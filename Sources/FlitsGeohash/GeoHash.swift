//
//  Geohash.swift
//  ReportPerformanceTestTests
//
//  Created by Maarten Zonneveld on 07/05/2024.
//

import CoreLocation

public enum Geohash {

    public enum Direction: UInt32, Sendable {
        case north = 0
        case east = 1
        case west = 2
        case south = 3

        var cValue: GEOHASH_direction {
            .init(rawValue)
        }
    }

    public struct Neighbors: Hashable, Sendable {
        public let north: String
        public let south: String
        public let west: String
        public let east: String
        public let northWest: String
        public let northEast: String
        public let southWest: String
        public let southEast: String

        public var allNeighbors: Set<String> {
            [north, south, west, east, northWest, northEast, southWest, southEast]
        }

        public func allNeighbors(and center: String) -> Set<String> {
            [north, south, west, east, northWest, northEast, southWest, southEast, center]
        }
    }

    public static func hash(_ coordinate: CLLocationCoordinate2D, length: UInt32) -> String {
        if !CLLocationCoordinate2DIsValid(coordinate) {
            assertionFailure("coordinate is invalid")
        }
        if length < 1, length > 22 {
            assertionFailure("length must be greater than 0 and less than 23")
        }
        return string(from: GEOHASH_encode(coordinate.latitude, coordinate.longitude, length))
    }

    public static func adjacent(hash: String, direction: Direction) -> String {
        guard let pointer = GEOHASH_get_adjacent(
            hash.cString(using: .ascii),
            direction.cValue
        ) else {
            fatalError()
        }
        let adjacent = string(from: pointer)
        GEOHASH_free_adjacent(pointer)
        return adjacent
    }

    public static func neighbors(hash: String) -> Neighbors {
        let pointer = GEOHASH_get_neighbors(hash.cString(using: .ascii))
        guard let cNeighbors = pointer?.pointee else {
            fatalError()
        }
        let neighbors = Neighbors(
            north: string(from: cNeighbors.north),
            south: string(from: cNeighbors.south),
            west: string(from: cNeighbors.west),
            east: string(from: cNeighbors.east),
            northWest: string(from: cNeighbors.north_west),
            northEast: string(from: cNeighbors.north_east),
            southWest: string(from: cNeighbors.south_west),
            southEast: string(from: cNeighbors.south_east)
        )
        GEOHASH_free_neighbors(pointer)
        return neighbors
    }

    public struct Region: Sendable {
        let center: CLLocationCoordinate2D
        let latitudeDelta: CLLocationDegrees
        let longitudeDelta: CLLocationDegrees

        public init(center: CLLocationCoordinate2D, latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
            self.center = center
            self.latitudeDelta = latitudeDelta
            self.longitudeDelta = longitudeDelta
        }
    }

    public static func hashes(for region: Region, length: UInt32) -> Set<String> {
        let northWest = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.latitudeDelta / 2,
            longitude: region.center.longitude - region.longitudeDelta / 2
        )
        let northEast = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.latitudeDelta / 2,
            longitude: region.center.longitude + region.longitudeDelta / 2
        )
        let southEast = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.latitudeDelta / 2,
            longitude: region.center.longitude + region.longitudeDelta / 2
        )

        let hashNorthWest = hash(northWest, length: length)
        let hashNorthEast = hash(northEast, length: length)
        let hashSouthEast = hash(southEast, length: length)

        var currentHash = hashNorthWest
        var mostEastHash = hashNorthEast
        var mostWestHash = hashNorthWest

        var hashes: Set<String> = [currentHash]
        while currentHash != hashSouthEast {

            guard hashNorthEast != hashNorthWest else {
                // Our region fits inside a single geohash (width)
                // This will produce 1 or more rows of a single column
                // Only look in the southern direction, if you start looking east you will immediately go past the mostEastHash
                // Immediately move to the next row until we find the hashSouthEast
                mostEastHash = adjacent(hash: mostEastHash, direction: .south)
                mostWestHash = adjacent(hash: mostWestHash, direction: .south)
                currentHash = mostWestHash
                hashes.insert(currentHash)
                continue
            }

            // Look for the next column by moving east
            currentHash = adjacent(hash: currentHash, direction: .east)
            hashes.insert(currentHash)

            if currentHash == mostEastHash && currentHash != hashSouthEast {
                // We are now at the most east row. Start again with a new row.
                mostEastHash = adjacent(hash: mostEastHash, direction: .south)
                mostWestHash = adjacent(hash: mostWestHash, direction: .south)
                currentHash = mostWestHash
                hashes.insert(currentHash)
            }
        }
        return hashes
    }
}

extension Geohash {

    private static func string(from cString: UnsafePointer<CChar>) -> String {
        guard let value = String(
            cString: cString,
            encoding: .ascii
        ) else {
            // This should never happen
            fatalError("Could not create String from cString")
        }
        return value
    }
}
