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
        guard let pointer = GEOHASH_encode(coordinate.latitude, coordinate.longitude, length) else {
            fatalError()
        }
        let hash = string(from: pointer)
        free(pointer)
        return hash
    }

    public static func adjacent(hash: String, direction: Direction) -> String {
        guard let pointer = GEOHASH_get_adjacent(
            hash.cString(using: .ascii),
            direction.cValue
        ) else {
            fatalError()
        }
        let adjacent = string(from: pointer)
        free(pointer)
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
