//
//  Benchmarks.swift
//
//  Performance gates for FlitsGeohash. The loops live in this module and are
//  built with -O (`swift run -c release Benchmarks`); the hot library entry
//  points are @inlinable so the optimizer sees through the module boundary.
//
//  Usage:
//    swift run -c release Benchmarks            # report timings
//    swift run -c release Benchmarks enforce    # exit 1 when a gate fails
//
//  GEOHASH_BENCH_GATE_SCALE (a Double, default 1) relaxes the gates for
//  slower machines without changing the canonical numbers.
//

import Dispatch
import Foundation
import FlitsGeohash

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(Darwin)
import Darwin

// Darwin's allocation hook: every heap allocation in the process reports
// through this global function pointer while it is installed.
private typealias MallocLoggerFunction = @convention(c) (
    UInt32, UInt, UInt, UInt, UInt, UInt32
) -> Void

nonisolated(unsafe) private var mallocEventCount: UInt64 = 0

private let mallocCounter: MallocLoggerFunction = { _, _, _, _, _, _ in
    mallocEventCount += 1
}

nonisolated(unsafe) private let mallocLoggerSlot: UnsafeMutablePointer<MallocLoggerFunction?>? =
    dlsym(dlopen(nil, RTLD_NOW), "malloc_logger")?
        .assumingMemoryBound(to: MallocLoggerFunction?.self)

func countAllocations(_ body: () -> Void) -> UInt64? {
    guard let slot = mallocLoggerSlot else { return nil }
    mallocEventCount = 0
    slot.pointee = mallocCounter
    body()
    slot.pointee = nil
    return mallocEventCount
}
#else
func countAllocations(_ body: () -> Void) -> UInt64? {
    body()
    return nil
}
#endif

struct Gate {
    let name: String
    let limitNanoseconds: Double
    let measuredNanoseconds: Double
    let allocations: UInt64?
}

@main
struct Benchmarks {

    static func main() {
        let enforce = CommandLine.arguments.contains("enforce")
        let gateScale = ProcessInfo.processInfo.environment["GEOHASH_BENCH_GATE_SCALE"]
            .flatMap(Double.init) ?? 1.0

        // MARK: Fixtures

        let coordinateCount = 100_000
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.reserveCapacity(coordinateCount)
        var seed: UInt64 = 0x0123_4567_89AB_CDEF
        func nextRandom() -> Double {
            seed &+= 0x9E37_79B9_7F4A_7C15
            var z = seed
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z ^= z >> 31
            return Double(z >> 11) * (1.0 / 9_007_199_254_740_992.0)
        }
        for _ in 0..<coordinateCount {
            coordinates.append(
                .init(latitude: nextRandom() * 180 - 90, longitude: nextRandom() * 360 - 180)
            )
        }
        let geohashes = coordinates.map { Geohash($0, length: 7)! }

        // Accumulator the optimizer cannot remove.
        var blackhole: UInt64 = 0

        func measure(passes: Int, operationsPerPass: Int, _ body: () -> Void) -> Double {
            body() // warm-up
            var best = Double.greatestFiniteMagnitude
            for _ in 0..<passes {
                let start = DispatchTime.now().uptimeNanoseconds
                body()
                let elapsed = DispatchTime.now().uptimeNanoseconds - start
                best = min(best, Double(elapsed) / Double(operationsPerPass))
            }
            return best
        }

        var gates: [Gate] = []

        // MARK: Encode -> Geohash (gate: 15 ns, zero allocations)

        var encodeAllocations: UInt64?
        let encodeNanoseconds = measure(passes: 20, operationsPerPass: coordinateCount) {
            encodeAllocations = countAllocations {
                for coordinate in coordinates {
                    blackhole &+= UInt64(Geohash(coordinate, length: 7)!.length)
                }
            }
        }
        gates.append(.init(
            name: "encode -> Geohash",
            limitNanoseconds: 15,
            measuredNanoseconds: encodeNanoseconds,
            allocations: encodeAllocations
        ))

        // MARK: Neighbor (gate: 5 ns, zero allocations)
        //
        // A dependency chain of east steps so the compiler cannot hoist or
        // vectorize the loop; longitude wrap keeps it running forever.

        let neighborSteps = 1_000_000
        var neighborAllocations: UInt64?
        let neighborNanoseconds = measure(passes: 20, operationsPerPass: neighborSteps) {
            neighborAllocations = countAllocations {
                var cell = geohashes[0]
                for _ in 0..<neighborSteps {
                    cell = cell.neighbor(.east)!
                }
                blackhole &+= UInt64(cell.length)
            }
        }
        gates.append(.init(
            name: "neighbor",
            limitNanoseconds: 5,
            measuredNanoseconds: neighborNanoseconds,
            allocations: neighborAllocations
        ))

        // MARK: neighbors() + center (informational, zero allocations)

        var ringAllocations: UInt64?
        let ringNanoseconds = measure(passes: 10, operationsPerPass: geohashes.count) {
            ringAllocations = countAllocations {
                for cell in geohashes {
                    let ring = cell.neighbors()
                    blackhole &+= UInt64(ring.east.length)
                    blackhole &+= UInt64(bitPattern: Int64(cell.center.latitude))
                }
            }
        }
        gates.append(.init(
            name: "neighbors() + center",
            limitNanoseconds: .infinity,
            measuredNanoseconds: ringNanoseconds,
            allocations: ringAllocations
        ))

        // MARK: Encode -> String (gate: 150 ns, allocations expected)

        let stringNanoseconds = measure(passes: 10, operationsPerPass: coordinateCount) {
            for coordinate in coordinates {
                blackhole &+= UInt64(Geohash(coordinate, length: 7)!.string.utf8.count)
            }
        }
        gates.append(.init(
            name: "encode -> String",
            limitNanoseconds: 150,
            measuredNanoseconds: stringNanoseconds,
            allocations: nil
        ))

        // MARK: Report

        func pad(_ text: String, _ width: Int) -> String {
            text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
        }

        print("blackhole: \(blackhole)")
        print(pad("operation", 24) + pad("measured", 14) + pad("gate", 10) + "allocations")
        var failed = false
        for gate in gates {
            let scaledLimit = gate.limitNanoseconds * gateScale
            let timeOK = gate.measuredNanoseconds <= scaledLimit
            let allocationsOK = (gate.allocations ?? 0) == 0
            if !timeOK || !allocationsOK { failed = true }
            let limitText = gate.limitNanoseconds.isFinite
                ? String(format: "%.0f ns", scaledLimit)
                : "-"
            let allocationText = gate.allocations.map(String.init) ?? "n/a"
            let status = (timeOK && allocationsOK) ? "ok" : "FAIL"
            print(
                pad(gate.name, 24)
                    + pad(String(format: "%.2f ns", gate.measuredNanoseconds), 14)
                    + pad(limitText, 10)
                    + pad(allocationText, 15)
                    + status
            )
        }

        if failed {
            if enforce {
                print("Performance gates FAILED")
                exit(1)
            }
            print("Performance gates failed (not enforced; pass 'enforce' to fail the build)")
        } else {
            print("All performance gates passed")
        }
    }
}
