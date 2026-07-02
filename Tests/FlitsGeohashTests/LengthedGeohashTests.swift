//
//  LengthedGeohashTests.swift
//
//  The typed-length wrapper over the packed Geohash, mirroring the v1
//  LengthedGeohash test coverage plus the v2 semantics (optional
//  pole-row neighbors). The coordinate and string initializers are
//  non-failable and trap on invalid input, exactly as in v1.
//

import XCTest
import FlitsGeohash
#if canImport(CoreLocation)
import CoreLocation
#endif

final class LengthedGeohashTests: XCTestCase {

    private let coordinate = CLLocationCoordinate2D(
        latitude: 57.64911063015461,
        longitude: 10.40743969380855
    )

    func testLengthConstants() {
        XCTAssertEqual(
            [
                GeohashLength1.length,
                GeohashLength2.length,
                GeohashLength3.length,
                GeohashLength4.length,
                GeohashLength5.length,
                GeohashLength6.length,
                GeohashLength7.length,
                GeohashLength8.length,
                GeohashLength9.length,
                GeohashLength10.length,
                GeohashLength11.length,
                GeohashLength12.length
            ],
            Array(1...12)
        )
    }

    func testInitializers() throws {
        // As in v1, the coordinate and string initializers are non-failable
        // and trap on invalid input, so only valid inputs can be tested here.
        XCTAssertEqual(Geohash11(coordinate).string, "u4pruydqqvj")
        XCTAssertEqual(Geohash5(string: "u4pru").string, "u4pru")

        // The packed-geohash initializer is the non-trapping path.
        let packed = try XCTUnwrap(Geohash(string: "u4pru"))
        XCTAssertEqual(Geohash5(packed)?.geohash, packed)
        XCTAssertNil(Geohash6(packed), "length mismatch must fail")
    }

    func testAdjacent() throws {
        let geohash = Geohash11(string: "u4pruydqqvj")

        XCTAssertEqual(geohash.adjacent(direction: .north), Geohash11(string: "u4pruydqqvm"))
        XCTAssertEqual(geohash.adjacent(direction: .east), Geohash11(string: "u4pruydqqvn"))
        XCTAssertEqual(geohash.adjacent(direction: .south), Geohash11(string: "u4pruydqquv"))
        XCTAssertEqual(geohash.adjacent(direction: .west), Geohash11(string: "u4pruydqqvh"))
        XCTAssertEqual(geohash.adjacent(direction: .northEast), Geohash11(string: "u4pruydqqvq"))
    }

    func testNeighborsAndNeighborSets() throws {
        let geohash = Geohash11(string: "u4pruydqqvj")
        let neighbors = geohash.neighbors()

        XCTAssertEqual(neighbors.north?.string, "u4pruydqqvm")
        XCTAssertEqual(neighbors.south?.string, "u4pruydqquv")
        XCTAssertEqual(neighbors.west.string, "u4pruydqqvh")
        XCTAssertEqual(neighbors.east.string, "u4pruydqqvn")
        XCTAssertEqual(neighbors.northWest?.string, "u4pruydqqvk")
        XCTAssertEqual(neighbors.northEast?.string, "u4pruydqqvq")
        XCTAssertEqual(neighbors.southWest?.string, "u4pruydqquu")
        XCTAssertEqual(neighbors.southEast?.string, "u4pruydqquy")

        let expected = Set(
            ["u4pruydqqvm", "u4pruydqquv", "u4pruydqqvh", "u4pruydqqvn",
             "u4pruydqqvk", "u4pruydqqvq", "u4pruydqquu", "u4pruydqquy"]
                .map(Geohash11.init(string:))
        )
        XCTAssertEqual(neighbors.allNeighbors, expected)
        XCTAssertEqual(neighbors.allNeighbors(and: geohash), expected.union([geohash]))
    }

    func testPoleRowNeighborsAreNil() throws {
        let topRow = Geohash6(string: "zzzzzz")
        let neighbors = topRow.neighbors()

        XCTAssertNil(neighbors.north)
        XCTAssertNil(neighbors.northEast)
        XCTAssertNil(neighbors.northWest)
        XCTAssertEqual(neighbors.east.string, "bpbpbp")
        XCTAssertEqual(neighbors.allNeighbors.count, 5)
        XCTAssertNil(topRow.adjacent(direction: .north))
    }

    func testToLowerLength() throws {
        let geohash11 = Geohash11(coordinate)

        let geohash10: Geohash10? = geohash11.toLowerLength()
        let geohash2: Geohash2? = geohash11.toLowerLength()
        let geohash11FromLower: Geohash11? = geohash2?.toLowerLength()
        let geohashFromSame: Geohash11? = geohash11.toLowerLength()

        XCTAssertEqual(geohash10?.string, "u4pruydqqv")
        XCTAssertEqual(geohash2?.string, "u4")
        XCTAssertNil(geohash11FromLower, "widening must fail")
        XCTAssertEqual(geohashFromSame, geohash11)
    }

    func testHashesForRegion() {
        let hashes = Geohash3.hashesForRegion(
            centerCoordinate: coordinate,
            latitudeDelta: 2,
            longitudeDelta: 2
        )
        XCTAssertEqual(
            hashes.map(\.string).sorted(),
            ["u4n", "u4p", "u4q", "u4r", "u60", "u62"]
        )

        XCTAssertEqual(
            Geohash5.hashesForRegion(
                centerCoordinate: .init(latitude: 0, longitude: 0),
                latitudeDelta: 180,
                longitudeDelta: 360
            ),
            [],
            "the maxCells cap applies to the typed API too"
        )
    }

    func testCodableRoundTripsAsBase32String() throws {
        let geohash = Geohash5(string: "u4pru")
        let data = try JSONEncoder().encode([geohash])
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["u4pru"]"#)
        XCTAssertEqual(try JSONDecoder().decode([Geohash5].self, from: data), [geohash])
        XCTAssertThrowsError(try JSONDecoder().decode([Geohash6].self, from: data), "length mismatch must throw")
    }

    func testPackedInterop() throws {
        let typed = Geohash7(coordinate)
        let packed = try XCTUnwrap(Geohash(coordinate, length: 7))
        XCTAssertEqual(typed.geohash, packed)
        XCTAssertEqual(typed.string, packed.string)
        XCTAssertEqual("\(typed)", packed.string)
    }
}
