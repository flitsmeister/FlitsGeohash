//
//  GoldenFixtureTests.swift
//
//  Parity with the v1 C-backed implementation, verified against fixtures
//  generated before the C target was removed (see the fixture-generation
//  commit). The fixtures deliberately contain no coordinates on cell
//  boundaries — the only place where v1 (`>`) and v2 (`>=`) disagree —
//  and no pole-row neighbor cases, where v1 wrapped latitude and v2
//  returns nil. Those documented changes are tested in EdgeCaseTests.
//

import XCTest
import Foundation
import FlitsGeohash
#if canImport(CoreLocation)
import CoreLocation
#endif

final class GoldenFixtureTests: XCTestCase {

    private func fixtureLines(_ name: String) throws -> [Substring] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "tsv", subdirectory: "Fixtures"),
            "missing fixture \(name).tsv"
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        return content.split(separator: "\n")
    }

    func testEncodeMatchesV1() throws {
        let lines = try fixtureLines("encode")
        XCTAssertGreaterThanOrEqual(lines.count, 100_000, "fixture must hold at least 100k rows")

        var mismatches = 0
        for line in lines {
            let fields = line.split(separator: "\t")
            let latitude = try XCTUnwrap(Double(fields[0]))
            let longitude = try XCTUnwrap(Double(fields[1]))
            let length = try XCTUnwrap(Int(fields[2]))
            let expected = String(fields[3])

            let geohash = try XCTUnwrap(
                Geohash(.init(latitude: latitude, longitude: longitude), length: length)
            )
            if geohash.string != expected {
                mismatches += 1
                if mismatches <= 10 {
                    XCTFail("(\(latitude), \(longitude)) @\(length): got \(geohash.string), v1 said \(expected)")
                }
            }
        }
        XCTAssertEqual(mismatches, 0, "\(mismatches) rows differ from v1")
    }

    /// The fixture generator excluded boundary-aligned coordinates; verify it
    /// actually did, because such rows would be invalid under the v2 rule.
    func testEncodeFixtureContainsNoBoundaryRows() throws {
        for line in try fixtureLines("encode") {
            let fields = line.split(separator: "\t")
            let latitude = try XCTUnwrap(Double(fields[0]))
            let longitude = try XCTUnwrap(Double(fields[1]))
            let latScaled = ((latitude + 90) / 180) * Double(1 << 30)
            let lonScaled = ((longitude + 180) / 360) * Double(1 << 30)
            XCTAssertNotEqual(latScaled, latScaled.rounded(.down), "boundary latitude in fixture: \(latitude)")
            XCTAssertNotEqual(lonScaled, lonScaled.rounded(.down), "boundary longitude in fixture: \(longitude)")
        }
    }

    func testNeighborsMatchV1() throws {
        let lines = try fixtureLines("neighbors")
        XCTAssertGreaterThan(lines.count, 2_000)

        for line in lines {
            let fields = line.split(separator: "\t").map(String.init)
            let cell = try XCTUnwrap(Geohash(string: fields[0]))
            let neighbors = cell.neighbors()
            // Fixture order: hash n ne e se s sw w nw. None of the rows are
            // in a pole row, so all eight neighbors exist.
            XCTAssertEqual(try XCTUnwrap(neighbors.north).string, fields[1], "north of \(fields[0])")
            XCTAssertEqual(try XCTUnwrap(neighbors.northEast).string, fields[2], "northEast of \(fields[0])")
            XCTAssertEqual(neighbors.east.string, fields[3], "east of \(fields[0])")
            XCTAssertEqual(try XCTUnwrap(neighbors.southEast).string, fields[4], "southEast of \(fields[0])")
            XCTAssertEqual(try XCTUnwrap(neighbors.south).string, fields[5], "south of \(fields[0])")
            XCTAssertEqual(try XCTUnwrap(neighbors.southWest).string, fields[6], "southWest of \(fields[0])")
            XCTAssertEqual(neighbors.west.string, fields[7], "west of \(fields[0])")
            XCTAssertEqual(try XCTUnwrap(neighbors.northWest).string, fields[8], "northWest of \(fields[0])")
        }
    }

    func testRegionsMatchV1() throws {
        let lines = try fixtureLines("regions")
        XCTAssertGreaterThanOrEqual(lines.count, 200)

        for line in lines {
            let fields = line.split(separator: "\t")
            let latitude = try XCTUnwrap(Double(fields[0]))
            let longitude = try XCTUnwrap(Double(fields[1]))
            let latitudeDelta = try XCTUnwrap(Double(fields[2]))
            let longitudeDelta = try XCTUnwrap(Double(fields[3]))
            let length = try XCTUnwrap(Int(fields[4]))
            let expected = String(fields[5])

            let cells = Geohash.cells(
                intersecting: .init(latitude: latitude, longitude: longitude),
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta,
                length: length
            )
            XCTAssertEqual(
                cells.map(\.string).sorted().joined(separator: ","),
                expected,
                "region (\(latitude), \(longitude)) ±(\(latitudeDelta), \(longitudeDelta)) @\(length)"
            )
        }
    }
}
