//
//  Tests.swift
//
//
//  Created by Maarten Zonneveld on 08/05/2024.
//

import XCTest
import CoreLocation
@testable import FlitsGeohashSwift

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

    func testRegion() {
        let expectedHashes: Set = ["u14zr","u14yd","u16bj","u14yg","u16b4","u14zd","u16bc","u14yf","u16bd","u14zb","u14xn","u14zh","u14zp","u16b6","u16bz","u14xq","u14wy","u14xy","u14wx","u14zq","u16bh","u14zc","u16b3","u16bv","u14xp","u14zv","u14zf","u14wz","u14xz","u14ww","u16b2","u168w","u16bq","u16bb","u16bk","u14zs","u14yx","u16b1","u14ye","u14zm","u14zy","u14yv","u16bg","u16bn","u16bt","u14zu","u16b7","u14yc","u14xx","u16bx","u14z3","u14y9","u14z9","u14zn","u16br","u16be","u16bf","u14yu","u16b9","u14xr","u16b8","u16b5","u14z8","u14yy","u14zg","u168n","u14zx","u14z5","u14y8","u14zt","u168x","u14zz","u14z0","u16bm","u14zj","u14yt","u168q","u168z","u14xw","u16b0","u14z2","u14yz","u14ze","u16bs","u14z6","u14z7","u14ys","u14zw","u14z1","u14yb","u16bw","u16bp","u14zk","u14z4","u16by","u168r","u14yw","u168p","u168y","u16bu"]
        measure {
            let region = Geohash.GeohashRegion(center: .init(latitude: 52, longitude: 4), latitudeDelta: 0.4, longitudeDelta: 0.4)
            let hashesInRegion = Geohash.hashes(for: region, length: 5)
            XCTAssertEqual(hashesInRegion, expectedHashes)
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
