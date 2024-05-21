
import XCTest
import CoreLocation
@testable import FlitsGeohash

final class GeohashTests: XCTestCase {
    func testDecode() {
        XCTAssertNotNil(Geohash11(value: "u4pruydqqvj"))
    }

    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let chars = "u4pruydqqvj"

        XCTAssertEqual(Geohash10(coordinate).value, String(chars.prefix(10)))
        XCTAssertEqual(Geohash9(coordinate).value, String(chars.prefix(9)))
        XCTAssertEqual(Geohash8(coordinate).value, String(chars.prefix(8)))
        XCTAssertEqual(Geohash7(coordinate).value, String(chars.prefix(7)))
        XCTAssertEqual(Geohash6(coordinate).value, String(chars.prefix(6)))
        XCTAssertEqual(Geohash5(coordinate).value, String(chars.prefix(5)))
        XCTAssertEqual(Geohash4(coordinate).value, String(chars.prefix(4)))
        XCTAssertEqual(Geohash3(coordinate).value, String(chars.prefix(3)))
        XCTAssertEqual(Geohash2(coordinate).value, String(chars.prefix(2)))
        XCTAssertEqual(Geohash1(coordinate).value, String(chars.prefix(1)))
    }

    func testGetAdjacent() {
        let north = Geohash11(value: "u4pruydqqvj").adjacent(direction: .north)
        let east = Geohash11(value: "u4pruydqqvj").adjacent(direction: .east)
        let south = Geohash11(value: "u4pruydqqvj").adjacent(direction: .south)
        let west = Geohash11(value: "u4pruydqqvj").adjacent(direction: .west)

        XCTAssertEqual(north.value, "u4pruydqqvm")
        XCTAssertEqual(east.value, "u4pruydqqvn")
        XCTAssertEqual(south.value, "u4pruydqquv")
        XCTAssertEqual(west.value, "u4pruydqqvh")
    }

    func testGetNeighbors() {
        let neighbors = Geohash11(value: "u4pruydqqvj").neighbors()
        let expectedNeighbors = LengthedGeohash<GeohashLength11>.Neighbors(
            north: .init(value: "u4pruydqqvm"),
            south: .init(value: "u4pruydqquv"),
            west: .init(value: "u4pruydqqvh"),
            east: .init(value: "u4pruydqqvn"),
            northWest: .init(value: "u4pruydqqvk"),
            northEast: .init(value: "u4pruydqqvq"),
            southWest: .init(value: "u4pruydqquu"),
            southEast: .init(value: "u4pruydqquy")
        )
        XCTAssertEqual(neighbors, expectedNeighbors)
    }
}
