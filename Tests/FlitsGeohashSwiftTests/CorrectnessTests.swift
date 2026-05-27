import XCTest
#if canImport(CoreLocation)
import CoreLocation
#endif

import FlitsGeohash
import FlitsGeohashC

final class CorrectnessTests: XCTestCase {

    func testCoordinateValidity() {
        XCTAssertTrue(CLLocationCoordinate2DIsValid(.init(latitude: 52, longitude: 5)))
        XCTAssertFalse(CLLocationCoordinate2DIsValid(.init(latitude: 91, longitude: 5)))
        XCTAssertFalse(CLLocationCoordinate2DIsValid(.init(latitude: 52, longitude: 181)))
    }

    func testGeohashHashAndCoordinateExtension() {
        for length in 1...11 {
            let expectedHash = String(Fixture.hash11.prefix(length))
            XCTAssertEqual(Geohash.hash(Fixture.coordinate, length: UInt32(length)), expectedHash)
            XCTAssertEqual(Fixture.coordinate.geohash(length: UInt32(length)), expectedHash)
        }
    }

    func testGeohashAdjacent() {
        XCTAssertEqual(Geohash.adjacent(hash: Fixture.hash11, direction: .north), Fixture.north)
        XCTAssertEqual(Geohash.adjacent(hash: Fixture.hash11, direction: .east), Fixture.east)
        XCTAssertEqual(Geohash.adjacent(hash: Fixture.hash11, direction: .south), Fixture.south)
        XCTAssertEqual(Geohash.adjacent(hash: Fixture.hash11, direction: .west), Fixture.west)
    }

    func testGeohashAdjacentHandlesWorldBoundaryHashes() {
        let cases: [(hash: String, direction: Geohash.Direction, expected: String)] = [
            ("bpbpbp", .north, "000000"),
            ("zzzzzz", .east, "bpbpbp"),
            ("000000", .south, "bpbpbp"),
            ("000000", .west, "pbpbpb")
        ]

        for testCase in cases {
            let adjacent = Geohash.adjacent(hash: testCase.hash, direction: testCase.direction)

            XCTAssertEqual(adjacent, testCase.expected)
        }
    }

    func testGeohashNeighborsAndNeighborSets() {
        let neighbors = Geohash.neighbors(hash: Fixture.hash11)

        XCTAssertEqual(neighbors.north, Fixture.north)
        XCTAssertEqual(neighbors.south, Fixture.south)
        XCTAssertEqual(neighbors.west, Fixture.west)
        XCTAssertEqual(neighbors.east, Fixture.east)
        XCTAssertEqual(neighbors.northWest, Fixture.northWest)
        XCTAssertEqual(neighbors.northEast, Fixture.northEast)
        XCTAssertEqual(neighbors.southWest, Fixture.southWest)
        XCTAssertEqual(neighbors.southEast, Fixture.southEast)
        XCTAssertEqual(neighbors.allNeighbors, Fixture.stringNeighbors)
        XCTAssertEqual(
            neighbors.allNeighbors(and: Fixture.hash11),
            Fixture.stringNeighbors.union([Fixture.hash11])
        )
    }

    func testGeohashNeighborsHandlesOriginAdjacentGeneratedHashes() {
        let originAdjacentHashes = Geohash.hashesForRegion(
            centerCoordinate: .init(latitude: 0, longitude: 0),
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
            length: 6
        )

        XCTAssertEqual(Set(originAdjacentHashes), Set(["7zzzzz", "ebpbpb", "kpbpbp", "s00000"]))

        for hash in originAdjacentHashes {
            let neighbors = Geohash.neighbors(hash: hash)

            XCTAssertTrue(neighbors.allNeighbors.allSatisfy { $0.count == hash.count })
            XCTAssertTrue(neighbors.allNeighbors.allSatisfy { !$0.isEmpty })
        }
    }

    func testGeohashHashesForRegion() {
        let hashes = Geohash.hashesForRegion(
            centerCoordinate: Fixture.coordinate,
            latitudeDelta: 2,
            longitudeDelta: 2,
            length: 3
        )
        .sorted()

        XCTAssertEqual(hashes, Fixture.regionHashes)
    }

    func testTypedGeohashLengthConstants() {
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
                GeohashLength11.length
            ],
            Array(1...11).map(UInt32.init)
        )
    }

    func testTypedGeohashInitializers() {
        XCTAssertEqual(Geohash11(Fixture.coordinate).string, Fixture.hash11)
        XCTAssertEqual(Geohash5(string: Fixture.hash5).string, Fixture.hash5)
    }

    func testTypedGeohashAdjacent() {
        let geohash = Geohash11(string: Fixture.hash11)

        XCTAssertEqual(geohash.adjacent(direction: .north), Geohash11(string: Fixture.north))
        XCTAssertEqual(geohash.adjacent(direction: .east), Geohash11(string: Fixture.east))
        XCTAssertEqual(geohash.adjacent(direction: .south), Geohash11(string: Fixture.south))
        XCTAssertEqual(geohash.adjacent(direction: .west), Geohash11(string: Fixture.west))
    }

    func testTypedGeohashNeighborsAndNeighborSets() {
        let geohash = Geohash11(string: Fixture.hash11)
        let neighbors = geohash.neighbors()
        let expected = Geohash11.Neighbors(
            north: .init(string: Fixture.north),
            south: .init(string: Fixture.south),
            west: .init(string: Fixture.west),
            east: .init(string: Fixture.east),
            northWest: .init(string: Fixture.northWest),
            northEast: .init(string: Fixture.northEast),
            southWest: .init(string: Fixture.southWest),
            southEast: .init(string: Fixture.southEast)
        )

        XCTAssertEqual(neighbors, expected)
        XCTAssertEqual(neighbors.allNeighbors, Fixture.typedNeighbors)
        XCTAssertEqual(neighbors.allNeighbors(and: geohash), Fixture.typedNeighbors.union([geohash]))
    }

    func testTypedGeohashToLowerLength() {
        let geohash11 = Geohash11(Fixture.coordinate)

        let geohash10: Geohash10? = geohash11.toLowerLength()
        let geohash2: Geohash2? = geohash11.toLowerLength()
        let geohash11FromLower: Geohash11? = geohash2?.toLowerLength()
        let geohashFromSame: Geohash11? = geohash11.toLowerLength()

        XCTAssertEqual(geohash10?.string, String(Fixture.hash11.prefix(10)))
        XCTAssertEqual(geohash2?.string, String(Fixture.hash11.prefix(2)))
        XCTAssertNil(geohash11FromLower)
        XCTAssertEqual(geohashFromSame, geohash11)
    }

    func testTypedGeohashHashesForRegion() {
        let hashes = Geohash3.hashesForRegion(
            centerCoordinate: Fixture.coordinate,
            latitudeDelta: 2,
            longitudeDelta: 2
        )
        .map(\.string)
        .sorted()

        XCTAssertEqual(hashes, Fixture.regionHashes)
    }

    func testSmallRegionReturnsNonEmptyArray() {
        let hashes = Geohash.hashesForRegion(
            centerCoordinate: .init(latitude: 52, longitude: 5),
            latitudeDelta: 0.001,
            longitudeDelta: 0.001,
            length: 6
        )
        XCTAssertGreaterThan(hashes.count, 0)
    }

    func testLargeRegionReturnsManyHashes() {
        let hashes = Geohash.hashesForRegion(
            centerCoordinate: .init(latitude: 52, longitude: 5),
            latitudeDelta: 0.5,
            longitudeDelta: 0.5,
            length: 6
        )
        XCTAssertGreaterThan(hashes.count, 1000)
    }

    func testFreeingHashArrayWorks() {
        var array = GEOHASH_hashes_for_region(52, 5, 0.02, 0.02, 6)
        GEOHASH_free_array(&array)

        XCTAssertEqual(array.count, 0, "After free, count should be zero")
        XCTAssertNil(array.hashes, "After free, hashes should be nil")
        XCTAssertEqual(array.capacity, 0, "After free, capacity should be zero")
    }

    func testEdgeAlignedRegion() {
        let hashes = Geohash.hashesForRegion(
            centerCoordinate: .init(latitude: 0, longitude: 0),
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
            length: 6
        )
        .sorted()
        .joined(separator: ",")

        XCTAssertEqual(hashes, "7zzzzz,ebpbpb,kpbpbp,s00000")
    }
}

private enum Fixture {
    static let coordinate = CLLocationCoordinate2D(
        latitude: 57.64911063015461,
        longitude: 10.40743969380855
    )
    static let hash11 = "u4pruydqqvj"
    static let hash5 = "u4pru"
    static let north = "u4pruydqqvm"
    static let south = "u4pruydqquv"
    static let west = "u4pruydqqvh"
    static let east = "u4pruydqqvn"
    static let northWest = "u4pruydqqvk"
    static let northEast = "u4pruydqqvq"
    static let southWest = "u4pruydqquu"
    static let southEast = "u4pruydqquy"
    static let regionHashes = ["u4n", "u4p", "u4q", "u4r", "u60", "u62"]
    static let stringNeighbors: Set<String> = [
        north,
        south,
        west,
        east,
        northWest,
        northEast,
        southWest,
        southEast
    ]
    static let typedNeighbors: Set<Geohash11> = [
        .init(string: north),
        .init(string: south),
        .init(string: west),
        .init(string: east),
        .init(string: northWest),
        .init(string: northEast),
        .init(string: southWest),
        .init(string: southEast)
    ]
}
