
import XCTest
import CoreLocation
@testable import FlitsGeohash

final class GeohashTests: XCTestCase {
    func testDecode() {
        XCTAssertNotNil(Geohash11(string: "u4pruydqqvj"))
    }

    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let chars = "u4pruydqqvj"

        XCTAssertEqual(Geohash10(coordinate).string, String(chars.prefix(10)))
        XCTAssertEqual(Geohash9(coordinate).string, String(chars.prefix(9)))
        XCTAssertEqual(Geohash8(coordinate).string, String(chars.prefix(8)))
        XCTAssertEqual(Geohash7(coordinate).string, String(chars.prefix(7)))
        XCTAssertEqual(Geohash6(coordinate).string, String(chars.prefix(6)))
        XCTAssertEqual(Geohash5(coordinate).string, String(chars.prefix(5)))
        XCTAssertEqual(Geohash4(coordinate).string, String(chars.prefix(4)))
        XCTAssertEqual(Geohash3(coordinate).string, String(chars.prefix(3)))
        XCTAssertEqual(Geohash2(coordinate).string, String(chars.prefix(2)))
        XCTAssertEqual(Geohash1(coordinate).string, String(chars.prefix(1)))
    }

    func testGetAdjacent() {
        let north = Geohash11(string: "u4pruydqqvj").adjacent(direction: .north)
        let east = Geohash11(string: "u4pruydqqvj").adjacent(direction: .east)
        let south = Geohash11(string: "u4pruydqqvj").adjacent(direction: .south)
        let west = Geohash11(string: "u4pruydqqvj").adjacent(direction: .west)

        XCTAssertEqual(north.string, "u4pruydqqvm")
        XCTAssertEqual(east.string, "u4pruydqqvn")
        XCTAssertEqual(south.string, "u4pruydqquv")
        XCTAssertEqual(west.string, "u4pruydqqvh")
    }

    func testGetNeighbors() {
        let neighbors = Geohash11(string: "u4pruydqqvj").neighbors()
        let expectedNeighbors = LengthedGeohash<GeohashLength11>.Neighbors(
            north: .init(string: "u4pruydqqvm"),
            south: .init(string: "u4pruydqquv"),
            west: .init(string: "u4pruydqqvh"),
            east: .init(string: "u4pruydqqvn"),
            northWest: .init(string: "u4pruydqqvk"),
            northEast: .init(string: "u4pruydqqvq"),
            southWest: .init(string: "u4pruydqquu"),
            southEast: .init(string: "u4pruydqquy")
        )
        XCTAssertEqual(neighbors, expectedNeighbors)
    }
}
