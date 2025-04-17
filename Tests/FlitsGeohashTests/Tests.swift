//
//  Tests.swift
//
//
//  Created by Maarten Zonneveld on 08/05/2024.
//

import XCTest
import CoreLocation
@testable import FlitsGeohash

final class Tests: XCTestCase {

    private static let size = 100_000
    private static let array = CLLocationCoordinate2D.testCollection(size: size)

    private static let geohashes = array.map {
        Geohash.hash($0, length: 5)
    }

    override class func setUp() {
        _ = array
        _ = geohashes
    }

    func testMakeGeohashes() {
        measure {
            let geohashes = Self.array.map {
                Geohash.hash($0, length: 5)
            }
            XCTAssertEqual(geohashes.count, Self.size)
            XCTAssertEqual(geohashes.first, "u15d1")
            XCTAssertEqual(geohashes.last, "u1hrb")
        }
    }

    func testNeigbors() {
        measure {
            let neighbors = Self.geohashes.map {
                Geohash.neighbors(hash: $0)
            }
            XCTAssertEqual(neighbors.count, Self.size)
            XCTAssertEqual(neighbors.first?.north, "u15d3")
            XCTAssertEqual(neighbors.last?.north, "u1k20")
        }
    }

    func testAdjacent() {
        measure {
            let adjacentHashes = Self.geohashes.map {
                Geohash.adjacent(hash: $0, direction: .north)
            }
            XCTAssertEqual(adjacentHashes.count, Self.size)
            XCTAssertEqual(adjacentHashes.first, "u15d3")
            XCTAssertEqual(adjacentHashes.last, "u1k20")
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
