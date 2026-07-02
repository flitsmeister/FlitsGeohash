//
//  PropertyTests.swift
//
//  Invariants that must hold for arbitrary inputs, checked over a
//  deterministic pseudo-random sample.
//

import XCTest
import FlitsGeohash
#if canImport(CoreLocation)
import CoreLocation
#endif

struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
    mutating func nextCoordinate() -> CLLocationCoordinate2D {
        .init(latitude: nextDouble(in: -90...90), longitude: nextDouble(in: -180...180))
    }
    mutating func nextLength() -> Int {
        1 + Int(next() % 12)
    }
}

final class PropertyTests: XCTestCase {

    private let sampleCount = 10_000

    func testEncodeCenterEncodeIsFixedPoint() throws {
        var rng = SplitMix64(seed: 1)
        for _ in 0..<sampleCount {
            let length = rng.nextLength()
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: length))
            XCTAssertEqual(Geohash(cell.center, length: length), cell)
        }
    }

    func testStringRoundTrips() throws {
        var rng = SplitMix64(seed: 2)
        for _ in 0..<sampleCount {
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: rng.nextLength()))
            XCTAssertEqual(Geohash(string: cell.string), cell)
        }
    }

    func testPrefixEqualsEncodingAtShorterLength() throws {
        var rng = SplitMix64(seed: 3)
        for _ in 0..<sampleCount {
            let coordinate = rng.nextCoordinate()
            let length = rng.nextLength()
            let cell = try XCTUnwrap(Geohash(coordinate, length: length))
            for shorter in 1...length {
                XCTAssertEqual(cell.prefix(shorter), Geohash(coordinate, length: shorter))
            }
        }
    }

    func testEastThenWestIsIdentity() throws {
        var rng = SplitMix64(seed: 4)
        for index in 0..<sampleCount {
            // Every eighth sample sits against the antimeridian so the
            // wraparound path is exercised in both directions.
            var coordinate = rng.nextCoordinate()
            if index % 8 == 0 {
                coordinate.longitude = rng.nextDouble(in: 179.99...179.9999)
            } else if index % 8 == 4 {
                coordinate.longitude = rng.nextDouble(in: (-179.9999)...(-179.99))
            }
            let cell = try XCTUnwrap(Geohash(coordinate, length: rng.nextLength()))
            XCTAssertEqual(cell.neighbor(.east)?.neighbor(.west), cell)
            XCTAssertEqual(cell.neighbor(.west)?.neighbor(.east), cell)
        }
    }

    func testNorthThenSouthIsIdentityAwayFromPoles() throws {
        var rng = SplitMix64(seed: 5)
        for _ in 0..<sampleCount {
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: rng.nextLength()))
            if let north = cell.neighbor(.north) {
                XCTAssertEqual(north.neighbor(.south), cell)
            }
            if let south = cell.neighbor(.south) {
                XCTAssertEqual(south.neighbor(.north), cell)
            }
        }
    }

    func testEveryCellAppearsInItsOwnIntersectingCells() throws {
        var rng = SplitMix64(seed: 6)
        for _ in 0..<1_000 {
            let length = 1 + Int(rng.next() % 8) // lengths 1...8 keep regions small
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: length))
            let bounds = cell.bounds
            let cells = Geohash.cells(
                intersecting: cell.center,
                latitudeDelta: bounds.latitudeDelta,
                longitudeDelta: bounds.longitudeDelta,
                length: length
            )
            XCTAssertTrue(cells.contains(cell), "\(cell.string) missing from its own region cover")
        }
    }

    func testZeroSizedRegionIsExactlyTheContainingCell() throws {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<1_000 {
            let coordinate = rng.nextCoordinate()
            let length = rng.nextLength()
            let cell = try XCTUnwrap(Geohash(coordinate, length: length))
            XCTAssertEqual(
                Geohash.cells(intersecting: coordinate, latitudeDelta: 0, longitudeDelta: 0, length: length),
                [cell]
            )
        }
    }

    func testNeighborsAgreeWithSingleSteps() throws {
        var rng = SplitMix64(seed: 8)
        for _ in 0..<sampleCount {
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: rng.nextLength()))
            let neighbors = cell.neighbors()
            XCTAssertEqual(neighbors.north, cell.neighbor(.north))
            XCTAssertEqual(neighbors.northEast, cell.neighbor(.northEast))
            XCTAssertEqual(neighbors.east, cell.neighbor(.east))
            XCTAssertEqual(neighbors.southEast, cell.neighbor(.southEast))
            XCTAssertEqual(neighbors.south, cell.neighbor(.south))
            XCTAssertEqual(neighbors.southWest, cell.neighbor(.southWest))
            XCTAssertEqual(neighbors.west, cell.neighbor(.west))
            XCTAssertEqual(neighbors.northWest, cell.neighbor(.northWest))

            let ring = cell.allNeighborsAndSelf()
            XCTAssertTrue(ring.contains(cell))
            XCTAssertEqual(Set(ring).count, ring.count, "ring must not contain duplicates")
            let expectedCount = 3 + (cell.neighbor(.north) != nil ? 3 : 0) + (cell.neighbor(.south) != nil ? 3 : 0)
            XCTAssertEqual(ring.count, expectedCount)
        }
    }

    func testDiagonalEqualsTwoCardinalSteps() throws {
        var rng = SplitMix64(seed: 9)
        for _ in 0..<sampleCount {
            let cell = try XCTUnwrap(Geohash(rng.nextCoordinate(), length: rng.nextLength()))
            XCTAssertEqual(cell.neighbor(.northEast), cell.neighbor(.north)?.neighbor(.east))
            XCTAssertEqual(cell.neighbor(.southWest), cell.neighbor(.south)?.neighbor(.west))
        }
    }
}
