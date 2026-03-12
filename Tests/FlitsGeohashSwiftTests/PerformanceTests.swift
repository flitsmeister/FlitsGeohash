//
//  PerformanceTests.swift
//
//
//  Created by Maarten Zonneveld on 08/05/2024.
//

import XCTest
#if canImport(CoreLocation)
import CoreLocation
#endif
import FlitsGeohash
import FlitsGeohashC

final class PerformanceTests: XCTestCase {
    
    private enum Benchmark {
        static let geohashLength: UInt32 = 5
        static let coordinateFixtureCount = 50_000
        static let regionRequestFixtureCount = 64
    }
    
    private struct RegionRequest {
        let centerCoordinate: CLLocationCoordinate2D
        let latitudeDelta: CLLocationDegrees
        let longitudeDelta: CLLocationDegrees
    }
    
    private static let coordinates = CLLocationCoordinate2D.testCollection(size: Benchmark.coordinateFixtureCount)
    private static let geohashes = coordinates.map {
        Geohash.hash($0, length: Benchmark.geohashLength)
    }
    private static let regionRequests = makeRegionRequestFixture()
    
    func testBenchmarkFixturesAreStable() {
        XCTAssertEqual(Self.coordinates.count, Benchmark.coordinateFixtureCount)
        XCTAssertEqual(Self.geohashes.count, Benchmark.coordinateFixtureCount)
        XCTAssertEqual(Self.geohashes.first, "u15d1")
        XCTAssertEqual(Self.geohashes.last, "u1hrb")
        XCTAssertEqual(Self.regionRequests.count, Benchmark.regionRequestFixtureCount)
    }
    
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    private let metrics: [XCTMetric] = [
        XCTClockMetric(),
        XCTCPUMetric(),
        XCTMemoryMetric()
    ]
    func testHashPerformance() {
        measure(metrics: metrics) {
            Self.runHashPerformance()
        }
    }
    func testAdjacentPerformance() {
        measure(metrics: metrics) {
            Self.runAdjacentPerformance()
        }
    }
    func testNeighborsPerformance() {
        measure(metrics: metrics) {
            Self.runNeighborsPerformance()
        }
    }
    func testRegionPerformance() {
        measure(metrics: metrics) {
            Self.runRegionPerformance()
        }
    }
    #else
    func testHashPerformance() {
        measure {
            Self.runHashPerformance()
        }
    }
    func testAdjacentPerformance() {
        measure {
            Self.runAdjacentPerformance()
        }
    }
    func testNeighborsPerformance() {
        measure {
            Self.runNeighborsPerformance()
        }
    }
    func testRegionPerformance() {
        measure {
            Self.runRegionPerformance()
        }
    }
    #endif
}

private extension PerformanceTests {
    
    private static func makeRegionRequestFixture() -> [RegionRequest] {
        let deltas: [(latitude: CLLocationDegrees, longitude: CLLocationDegrees)] = [
            (0.02, 0.02),
            (0.04, 0.03),
            (0.08, 0.06),
            (0.12, 0.09),
            (0.18, 0.14),
            (0.24, 0.18)
        ]
        let stride = max(1, coordinates.count / Benchmark.regionRequestFixtureCount)
        
        return (0..<Benchmark.regionRequestFixtureCount).map { index in
            let center = coordinates[min(index * stride, coordinates.count - 1)]
            let delta = deltas[index % deltas.count]
            return RegionRequest(
                centerCoordinate: center,
                latitudeDelta: delta.latitude,
                longitudeDelta: delta.longitude
            )
        }
    }
    
    // 100,000 encodes/sample = 20,000 coordinates x 5 passes at geohash length 5.
    static func runHashPerformance() {
        Self.run(passes: 5) {
            for coordinate in Self.coordinates {
                _ = Geohash.hash(coordinate, length: Benchmark.geohashLength)
            }
        }
    }
    
    // 100,000 north-adjacent lookups/sample = 20,000 hashes x 5 passes.
    static func runAdjacentPerformance() {
        Self.run(passes: 5) {
            for hash in Self.geohashes {
                _ = Geohash.adjacent(hash: hash, direction: .north)
            }
        }
    }
    
    // 20,000 neighbor lookups/sample = 20,000 hashes.
    static func runNeighborsPerformance() {
        for hash in Self.geohashes {
            _ = Geohash.neighbors(hash: hash)
        }
    }
    
    // 8,192 region-cover requests/sample = 64 requests x 128 passes at geohash length 5.
    static func runRegionPerformance() {
        Self.run(passes: 128) {
            for request in Self.regionRequests {
                _ = Geohash.hashesForRegion(
                    centerCoordinate: request.centerCoordinate,
                    latitudeDelta: request.latitudeDelta,
                    longitudeDelta: request.longitudeDelta,
                    length: Benchmark.geohashLength
                )
            }
        }
    }
    
    static func run(passes: Int, body: () -> ()) {
        for _ in 0..<passes {
            body()
        }
    }
}

private extension CLLocationCoordinate2D {

    static func testCollection(size: Int) -> [CLLocationCoordinate2D] {
        let minLat: CLLocationDegrees = 51
        let maxLat: CLLocationDegrees = 52
        let minLong: CLLocationDegrees = 5
        let maxLong: CLLocationDegrees = 6
        let latIncrements = (maxLat - minLat) / Double(size)
        let longIncrements = (maxLong - minLong) / Double(size)
        var array: [CLLocationCoordinate2D] = []
        array.reserveCapacity(size)
        for i in 0..<size {
            let doubleI = CLLocationDegrees(i)
            array.append(
                .init(
                    latitude: minLat + latIncrements * doubleI,
                    longitude: minLong + longIncrements * doubleI
                )
            )
        }
        return array
    }
}
