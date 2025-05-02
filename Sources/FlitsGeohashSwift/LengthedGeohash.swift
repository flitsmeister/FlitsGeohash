//
//  LengthedGeohash.swift
//  
//
//  Created by Maarten Zonneveld on 21/05/2024.
//

import FlitsGeohashC
import CoreLocation

public protocol GeohashLengthed {
    static var length: UInt32 { get }
}

public enum GeohashLength11: GeohashLengthed {
    public static let length: UInt32 = 11
}
public enum GeohashLength10: GeohashLengthed {
    public static let length: UInt32 = 10
}
public enum GeohashLength9: GeohashLengthed {
    public static let length: UInt32 = 9
}
public enum GeohashLength8: GeohashLengthed {
    public static let length: UInt32 = 8
}
public enum GeohashLength7: GeohashLengthed {
    public static let length: UInt32 = 7
}
public enum GeohashLength6: GeohashLengthed {
    public static let length: UInt32 = 6
}
public enum GeohashLength5: GeohashLengthed {
    public static let length: UInt32 = 5
}
public enum GeohashLength4: GeohashLengthed {
    public static let length: UInt32 = 4
}
public enum GeohashLength3: GeohashLengthed {
    public static let length: UInt32 = 3
}
public enum GeohashLength2: GeohashLengthed {
    public static let length: UInt32 = 2
}
public enum GeohashLength1: GeohashLengthed {
    public static let length: UInt32 = 1
}

public typealias Geohash11 = LengthedGeohash<GeohashLength11>
public typealias Geohash10 = LengthedGeohash<GeohashLength10>
public typealias Geohash9 = LengthedGeohash<GeohashLength9>
public typealias Geohash8 = LengthedGeohash<GeohashLength8>
public typealias Geohash7 = LengthedGeohash<GeohashLength7>
public typealias Geohash6 = LengthedGeohash<GeohashLength6>
public typealias Geohash5 = LengthedGeohash<GeohashLength5>
public typealias Geohash4 = LengthedGeohash<GeohashLength4>
public typealias Geohash3 = LengthedGeohash<GeohashLength3>
public typealias Geohash2 = LengthedGeohash<GeohashLength2>
public typealias Geohash1 = LengthedGeohash<GeohashLength1>

public struct LengthedGeohash<Length: GeohashLengthed>: Hashable, Sendable {
    public let string: String

    public init(string: String) {
        if string.count != Length.length { assertionFailure() }
        self.string = string
    }

    public init(_ coordinate: CLLocationCoordinate2D) {
        self.string = Geohash.hash(coordinate, length: Length.length)
    }

    public func neighbors() -> Neighbors {
        let neighbors = Geohash.neighbors(hash: string)
        return .init(
            north: .init(string: neighbors.north),
            south: .init(string: neighbors.south),
            west: .init(string: neighbors.west),
            east: .init(string: neighbors.east),
            northWest: .init(string: neighbors.northWest),
            northEast: .init(string: neighbors.northEast),
            southWest: .init(string: neighbors.southWest),
            southEast: .init(string: neighbors.southEast)
        )
    }
    
    public static func hashes(for region: Geohash.Region) -> Set<Self> {
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
        
        let hashNorthWest = Self.init(northWest)
        let hashNorthEast = Self.init(northEast)
        let hashSouthEast = Self.init(southEast)
        
        var currentHash = hashNorthWest
        var mostEastHash = hashNorthEast
        var mostWestHash = hashNorthWest
        
        var hashes: Set<Self> = [currentHash]
        while currentHash != hashSouthEast {
            
            guard hashNorthEast != hashNorthWest else {
                // Our region fits inside a single geohash (width)
                // This will produce 1 or more rows of a single column
                // Only look in the southern direction, if you start looking east you will immediately go past the mostEastHash
                // Immediately move to the next row until we find the hashSouthEast
                mostEastHash = mostEastHash.adjacent(direction: .south)
                mostWestHash = mostWestHash.adjacent(direction: .south)
                currentHash = mostWestHash
                hashes.insert(currentHash)
                continue
            }
            
            // Look for the next column by moving east
            currentHash = currentHash.adjacent(direction: .east)
            hashes.insert(currentHash)
            
            if currentHash == mostEastHash && currentHash != hashSouthEast {
                // We are now at the most east row. Start again with a new row.
                mostEastHash = mostEastHash.adjacent(direction: .south)
                mostWestHash = mostWestHash.adjacent(direction: .south)
                currentHash = mostWestHash
                hashes.insert(currentHash)
            }
        }
        return hashes
    }

    public func adjacent(direction: Geohash.Direction) -> LengthedGeohash {
        .init(string: Geohash.adjacent(hash: string, direction: direction))
    }

    public func toLowerLength<L: GeohashLengthed>() -> LengthedGeohash<L>? {
        let otherLength = L.length
        if otherLength == Length.length {
            return .init(string: string)
        }
        if otherLength > Length.length {
            return nil
        }
        return .init(string: String(string.prefix(Int(otherLength))))
    }
}

extension LengthedGeohash {

    public struct Neighbors: Hashable, Sendable {
        public let north: LengthedGeohash
        public let south: LengthedGeohash
        public let west: LengthedGeohash
        public let east: LengthedGeohash
        public let northWest: LengthedGeohash
        public let northEast: LengthedGeohash
        public let southWest: LengthedGeohash
        public let southEast: LengthedGeohash

        public init(north: LengthedGeohash, south: LengthedGeohash, west: LengthedGeohash, east: LengthedGeohash, northWest: LengthedGeohash, northEast: LengthedGeohash, southWest: LengthedGeohash, southEast: LengthedGeohash) {
            self.north = north
            self.south = south
            self.west = west
            self.east = east
            self.northWest = northWest
            self.northEast = northEast
            self.southWest = southWest
            self.southEast = southEast
        }

        public var allNeighbors: Set<LengthedGeohash> {
            [north, south, west, east, northWest, northEast, southWest, southEast]
        }

        public func allNeighbors(and center: LengthedGeohash) -> Set<LengthedGeohash> {
            [north, south, west, east, northWest, northEast, southWest, southEast, center]
        }
    }
}
