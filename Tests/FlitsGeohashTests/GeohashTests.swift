// The MIT License (MIT)
//
// Copyright (c) 2019 Naoki Hiroshima
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
@testable import FlitsGeohash

final class GeohashTests: XCTestCase {
    func testDecode() {
        XCTAssertNil(Geohash7("garbage").decoded)
        XCTAssertNil(Geohash11("u$pruydqqvj").decoded)
        XCTAssertNotNil(Geohash11("u4pruydqqvj").decoded)

        let geohash = Geohash11("u4pruydqqvj").decoded!
        XCTAssertEqual(geohash.latitude.min, 57.649109959602356)
        XCTAssertEqual(geohash.latitude.max, 57.649111300706863)
        XCTAssertEqual(geohash.longitude.min, 10.407439023256302)
        XCTAssertEqual(geohash.longitude.max, 10.407440364360809)
    }

    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let chars = "u4pruydqqvj"

        XCTAssertEqual(Geohash10(latitude: lat, longitude: lon).string, String(chars.prefix(10)))
        XCTAssertEqual(Geohash9(latitude: lat, longitude: lon).string, String(chars.prefix(9)))
        XCTAssertEqual(Geohash8(latitude: lat, longitude: lon).string, String(chars.prefix(8)))
        XCTAssertEqual(Geohash7(latitude: lat, longitude: lon).string, String(chars.prefix(7)))
        XCTAssertEqual(Geohash6(latitude: lat, longitude: lon).string, String(chars.prefix(6)))
        XCTAssertEqual(Geohash5(latitude: lat, longitude: lon).string, String(chars.prefix(5)))
        XCTAssertEqual(Geohash4(latitude: lat, longitude: lon).string, String(chars.prefix(4)))
        XCTAssertEqual(Geohash3(latitude: lat, longitude: lon).string, String(chars.prefix(3)))
        XCTAssertEqual(Geohash2(latitude: lat, longitude: lon).string, String(chars.prefix(2)))
        XCTAssertEqual(Geohash1(latitude: lat, longitude: lon).string, String(chars.prefix(1)))
    }

    func testGetAdjacent() {
        let north = Geohash11("u4pruydqqvj").adjacent(direction: .n)
        let east = Geohash11("u4pruydqqvj").adjacent(direction: .e)
        let south = Geohash11("u4pruydqqvj").adjacent(direction: .s)
        let west = Geohash11("u4pruydqqvj").adjacent(direction: .w)

        XCTAssertEqual(north, "u4pruydqqvm")
        XCTAssertEqual(east, "u4pruydqqvn")
        XCTAssertEqual(south, "u4pruydqquv")
        XCTAssertEqual(west, "u4pruydqqvh")
    }

    func testGetNeighbors() {
        let neighbors = Geohash11("u4pruydqqvj").neighbors()
        let expectedNeighbors: [Geohash11] = [
            "u4pruydqqvm", // n
            "u4pruydqqvn", // e
            "u4pruydqquv", // s
            "u4pruydqqvh", // w
            "u4pruydqqvq", // ne
            "u4pruydqquy", // se
            "u4pruydqqvk", // nw
            "u4pruydqquu"  // sw
        ]
        XCTAssertEqual(neighbors, expectedNeighbors)
    }

    static var allTests = [
        ("testDecode", testDecode),
        ("testEncode", testEncode),
        ("testGetAdjacent", testGetAdjacent),
        ("testGetNeighbors", testGetNeighbors),
    ]
}

#if canImport(CoreLocation)
import CoreLocation

final class GeohashCoreLocationTests: XCTestCase {
    func testCoreLocation() {
        let garbage: Geohash7 = "garbage"
        XCTAssertFalse(CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(geohash: garbage)))

        let correct: Geohash11 = "u4pruydqqvj"
        let c = CLLocationCoordinate2D(geohash: correct)
        XCTAssertTrue(CLLocationCoordinate2DIsValid(c))
        XCTAssertTrue(Geohash11(coordinate: c) == "u4pruydqqvj")
    }

    static var allTests = [
        ("testCoreLocation", testCoreLocation),
    ]
}

#endif
