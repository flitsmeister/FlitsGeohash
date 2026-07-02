//
//  PerformanceTests.swift
//
//  Coarse regression tracking only. The CI-enforced nanosecond gates live
//  in the Benchmarks executable (`swift run -c release Benchmarks enforce`):
//  an XCTest loop in a debug-built test target understates the real
//  per-call cost by an order of magnitude.
//

import XCTest
import FlitsGeohash
#if canImport(CoreLocation)
import CoreLocation
#endif

final class PerformanceTests: XCTestCase {

    private static let coordinates: [CLLocationCoordinate2D] = {
        var rng = SplitMix64(seed: 42)
        return (0..<50_000).map { _ in rng.nextCoordinate() }
    }()

    private static let geohashes = coordinates.map { Geohash($0, length: 7)! }

    func testEncodePerformance() {
        measure {
            var blackhole: UInt64 = 0
            for coordinate in Self.coordinates {
                blackhole &+= UInt64(Geohash(coordinate, length: 7)!.length)
            }
            XCTAssertGreaterThan(blackhole, 0)
        }
    }

    func testNeighborsPerformance() {
        measure {
            var blackhole: UInt64 = 0
            for cell in Self.geohashes {
                blackhole &+= UInt64(cell.neighbors().east.length)
            }
            XCTAssertGreaterThan(blackhole, 0)
        }
    }

    func testStringPerformance() {
        measure {
            var blackhole = 0
            for cell in Self.geohashes {
                blackhole &+= cell.string.utf8.count
            }
            XCTAssertGreaterThan(blackhole, 0)
        }
    }

    func testRegionPerformance() {
        measure {
            var blackhole = 0
            for index in stride(from: 0, to: Self.coordinates.count, by: 1_000) {
                blackhole += Geohash.cells(
                    intersecting: Self.coordinates[index],
                    latitudeDelta: 0.1,
                    longitudeDelta: 0.1,
                    length: 6
                ).count
            }
            XCTAssertGreaterThan(blackhole, 0)
        }
    }
}
