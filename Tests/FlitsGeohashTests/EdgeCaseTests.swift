//
//  EdgeCaseTests.swift
//
//  World edges, exact boundaries under the documented `>=` rule, pole-row
//  neighbor semantics, invalid inputs, and the string/Codable edges.
//

import XCTest
import FlitsGeohash
#if canImport(CoreLocation)
import CoreLocation
#endif

final class EdgeCaseTests: XCTestCase {

    // MARK: Known vectors

    func testKnownVector() throws {
        let coordinate = CLLocationCoordinate2D(
            latitude: 57.64911063015461,
            longitude: 10.40743969380855
        )
        let cell = try XCTUnwrap(Geohash(coordinate, length: 11))
        XCTAssertEqual(cell.string, "u4pruydqqvj")
        XCTAssertEqual(cell.length, 11)

        let neighbors = cell.neighbors()
        XCTAssertEqual(neighbors.north?.string, "u4pruydqqvm")
        XCTAssertEqual(neighbors.south?.string, "u4pruydqquv")
        XCTAssertEqual(neighbors.west.string, "u4pruydqqvh")
        XCTAssertEqual(neighbors.east.string, "u4pruydqqvn")
        XCTAssertEqual(neighbors.northWest?.string, "u4pruydqqvk")
        XCTAssertEqual(neighbors.northEast?.string, "u4pruydqqvq")
        XCTAssertEqual(neighbors.southWest?.string, "u4pruydqquu")
        XCTAssertEqual(neighbors.southEast?.string, "u4pruydqquy")

        for length in 1...11 {
            XCTAssertEqual(cell.prefix(length).string, String("u4pruydqqvj".prefix(length)))
        }
    }

    // MARK: World edges

    func testWorldCorners() throws {
        XCTAssertEqual(
            Geohash(.init(latitude: 90, longitude: 180), length: 12)?.string,
            "zzzzzzzzzzzz"
        )
        XCTAssertEqual(
            Geohash(.init(latitude: -90, longitude: -180), length: 12)?.string,
            "000000000000"
        )
        XCTAssertEqual(
            Geohash(.init(latitude: 90, longitude: -180), length: 12)?.string,
            "bpbpbpbpbpbp"
        )
        XCTAssertEqual(
            Geohash(.init(latitude: -90, longitude: 180), length: 12)?.string,
            "pbpbpbpbpbpb"
        )
    }

    /// The canonical `>=` rule: a coordinate exactly on a boundary belongs
    /// to the higher cell. This deliberately differs from v1's `>`.
    func testExactBoundaryBelongsToHigherCell() throws {
        XCTAssertEqual(Geohash(.init(latitude: 0, longitude: 0), length: 12)?.string, "s00000000000")
        XCTAssertEqual(Geohash(.init(latitude: 0, longitude: 0), length: 1)?.string, "s")
        XCTAssertEqual(Geohash(.init(latitude: 45, longitude: -90), length: 2)?.string, "f0")
    }

    func testNegativeZeroEncodesLikePositiveZero() {
        XCTAssertEqual(
            Geohash(.init(latitude: -0.0, longitude: -0.0), length: 12),
            Geohash(.init(latitude: 0.0, longitude: 0.0), length: 12)
        )
    }

    func testCellCornersWithinOneUlp() throws {
        // NE corner of a length-5 cell: exactly on the corner belongs to the
        // north-east neighbor (>= rule); one ulp inside belongs to the cell.
        let cell = try XCTUnwrap(Geohash(string: "u4pru"))
        let center = cell.center
        let bounds = cell.bounds
        let cornerLatitude = center.latitude + bounds.latitudeDelta / 2
        let cornerLongitude = center.longitude + bounds.longitudeDelta / 2

        XCTAssertEqual(
            Geohash(.init(latitude: cornerLatitude, longitude: cornerLongitude), length: 5),
            cell.neighbor(.northEast)
        )
        XCTAssertEqual(
            Geohash(
                .init(latitude: cornerLatitude.nextDown, longitude: cornerLongitude.nextDown),
                length: 5
            ),
            cell
        )
        XCTAssertEqual(
            Geohash(
                .init(latitude: cornerLatitude.nextUp, longitude: cornerLongitude.nextUp),
                length: 5
            ),
            cell.neighbor(.northEast)
        )

        // SW corner: exactly on it belongs to the cell itself.
        let swLatitude = center.latitude - bounds.latitudeDelta / 2
        let swLongitude = center.longitude - bounds.longitudeDelta / 2
        XCTAssertEqual(
            Geohash(.init(latitude: swLatitude, longitude: swLongitude), length: 5),
            cell
        )
        XCTAssertEqual(
            Geohash(.init(latitude: swLatitude.nextDown, longitude: swLongitude.nextDown), length: 5),
            cell.neighbor(.southWest)
        )
    }

    // MARK: Pole rows and antimeridian

    func testLatitudeDoesNotWrapAtPoles() throws {
        let topRow = try XCTUnwrap(Geohash(string: "zzzzzz"))
        XCTAssertNil(topRow.neighbor(.north))
        XCTAssertNil(topRow.neighbor(.northEast))
        XCTAssertNil(topRow.neighbor(.northWest))
        XCTAssertNotNil(topRow.neighbor(.south))
        XCTAssertEqual(topRow.neighbor(.east)?.string, "bpbpbp")
        XCTAssertEqual(topRow.allNeighborsAndSelf().count, 6)

        let bottomRow = try XCTUnwrap(Geohash(string: "000000"))
        XCTAssertNil(bottomRow.neighbor(.south))
        XCTAssertNil(bottomRow.neighbor(.southEast))
        XCTAssertNil(bottomRow.neighbor(.southWest))
        XCTAssertEqual(bottomRow.neighbor(.west)?.string, "pbpbpb")
        XCTAssertEqual(bottomRow.allNeighborsAndSelf().count, 6)

        // Interior cells have the full ring.
        let interior = try XCTUnwrap(Geohash(string: "u4pru"))
        XCTAssertEqual(interior.allNeighborsAndSelf().count, 9)
    }

    func testLongitudeWrapsAtAntimeridian() throws {
        let east = try XCTUnwrap(Geohash(.init(latitude: 20, longitude: 179.999), length: 6))
        let wrapped = east.neighbor(.east)
        XCTAssertNotNil(wrapped)
        XCTAssertLessThan(try XCTUnwrap(wrapped).center.longitude, -179)
        XCTAssertEqual(wrapped?.neighbor(.west), east)
    }

    // MARK: Lengths

    func testLengthExtremes() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.1, longitude: 5.1)
        let short = try XCTUnwrap(Geohash(coordinate, length: 1))
        XCTAssertEqual(short.length, 1)
        XCTAssertEqual(short.string.count, 1)
        XCTAssertEqual(Geohash(string: short.string), short)

        let long = try XCTUnwrap(Geohash(coordinate, length: 12))
        XCTAssertEqual(long.length, 12)
        XCTAssertEqual(long.string.count, 12)
        XCTAssertEqual(Geohash(string: long.string), long)
        XCTAssertEqual(long.prefix(1), short)

        // Length-12 cells are ~3.7 cm; the center must re-encode exactly.
        XCTAssertEqual(Geohash(long.center, length: 12), long)
    }

    func testPrefixesOfDifferentLengthsAreDistinctKeys() throws {
        let cell = try XCTUnwrap(Geohash(string: "u4pruydqqvj"))
        let prefixes = Set((1...11).map { cell.prefix($0) })
        XCTAssertEqual(prefixes.count, 11)
    }

    // MARK: Invalid inputs return nil (no traps)

    func testInvalidCoordinatesReturnNil() {
        XCTAssertNil(Geohash(.init(latitude: 90.000001, longitude: 0), length: 6))
        XCTAssertNil(Geohash(.init(latitude: -90.000001, longitude: 0), length: 6))
        XCTAssertNil(Geohash(.init(latitude: 0, longitude: 180.000001), length: 6))
        XCTAssertNil(Geohash(.init(latitude: 0, longitude: -180.000001), length: 6))
        XCTAssertNil(Geohash(.init(latitude: .nan, longitude: 0), length: 6))
        XCTAssertNil(Geohash(.init(latitude: 0, longitude: .nan), length: 6))
        XCTAssertNil(Geohash(.init(latitude: .infinity, longitude: 0), length: 6))
        XCTAssertNil(Geohash(.init(latitude: 0, longitude: -.infinity), length: 6))
    }

    func testInvalidLengthsReturnNil() {
        let coordinate = CLLocationCoordinate2D(latitude: 52, longitude: 5)
        XCTAssertNil(Geohash(coordinate, length: 0))
        XCTAssertNil(Geohash(coordinate, length: -1))
        XCTAssertNil(Geohash(coordinate, length: 13))
        XCTAssertNil(Geohash(coordinate, length: .max))
    }

    func testInvalidStringsReturnNil() {
        XCTAssertNil(Geohash(string: ""))
        XCTAssertNil(Geohash(string: "u4pruydqqvj0j")) // 13 characters
        XCTAssertNil(Geohash(string: "a"))             // not in the alphabet
        XCTAssertNil(Geohash(string: "U4PRU"))         // uppercase is rejected
        XCTAssertNil(Geohash(string: "u4p u"))
        XCTAssertNil(Geohash(string: "u4prü"))
        XCTAssertNil(Geohash(string: "u4pr-"))
    }

    func testInvalidRegionInputsReturnEmpty() {
        XCTAssertEqual(
            Geohash.cells(intersecting: .init(latitude: 91, longitude: 0), latitudeDelta: 1, longitudeDelta: 1, length: 5),
            []
        )
        XCTAssertEqual(
            Geohash.cells(intersecting: .init(latitude: 0, longitude: 0), latitudeDelta: -1, longitudeDelta: 1, length: 5),
            []
        )
        XCTAssertEqual(
            Geohash.cells(intersecting: .init(latitude: 0, longitude: 0), latitudeDelta: .nan, longitudeDelta: 1, length: 5),
            []
        )
        XCTAssertEqual(
            Geohash.cells(intersecting: .init(latitude: 0, longitude: 0), latitudeDelta: 1, longitudeDelta: 1, length: 0),
            []
        )
    }

    // MARK: Regions

    func testOriginRegion() {
        let cells = Geohash.cells(
            intersecting: .init(latitude: 0, longitude: 0),
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
            length: 6
        )
        XCTAssertEqual(
            cells.map(\.string).sorted(),
            ["7zzzzz", "ebpbpb", "kpbpbp", "s00000"]
        )
    }

    func testRegionClampsAtWorldEdges() {
        let cells = Geohash.cells(
            intersecting: .init(latitude: 89.9, longitude: 179.9),
            latitudeDelta: 1,
            longitudeDelta: 1,
            length: 3
        )
        XCTAssertFalse(cells.isEmpty)
        for cell in cells {
            XCTAssertLessThanOrEqual(cell.center.latitude, 90)
            XCTAssertLessThanOrEqual(cell.center.longitude, 180)
        }
    }

    // MARK: Geometry

    func testBounds() throws {
        let length1 = try XCTUnwrap(Geohash(string: "u"))
        XCTAssertEqual(length1.bounds.latitudeDelta, 45)
        XCTAssertEqual(length1.bounds.longitudeDelta, 45)

        let length2 = try XCTUnwrap(Geohash(string: "u4"))
        XCTAssertEqual(length2.bounds.latitudeDelta, 5.625)
        XCTAssertEqual(length2.bounds.longitudeDelta, 11.25)
    }

    func testCenterOfKnownCell() throws {
        // "u" spans lat 45...90, lon 0...45.
        let cell = try XCTUnwrap(Geohash(string: "u"))
        XCTAssertEqual(cell.center.latitude, 67.5)
        XCTAssertEqual(cell.center.longitude, 22.5)
    }

    // MARK: Codable & description

    func testCodableRoundTripsAsBase32String() throws {
        let cell = try XCTUnwrap(Geohash(string: "u4pruydqqvj"))
        let data = try JSONEncoder().encode([cell])
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["u4pruydqqvj"]"#)
        XCTAssertEqual(try JSONDecoder().decode([Geohash].self, from: data), [cell])
    }

    func testDecodingInvalidStringThrows() {
        let data = Data(#"["not a geohash!"]"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode([Geohash].self, from: data))
    }

    func testDescriptionIsTheBase32String() throws {
        let cell = try XCTUnwrap(Geohash(string: "u4pru"))
        XCTAssertEqual("\(cell)", "u4pru")
    }
}
