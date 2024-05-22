//
//  LengthedGeohash.swift
//  
//
//  Created by Maarten Zonneveld on 21/05/2024.
//

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

public struct LengthedGeohash<Length: GeohashLengthed>: Hashable {
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

    public func adjacent(direction: Geohash.Direction) -> LengthedGeohash {
        .init(string: Geohash.adjacent(hash: string, direction: direction))
    }

    public func toLowerLength<L: GeohashLengthed>() -> LengthedGeohash<L>? {
        let otherLength = L.length
        if otherLength > Length.length {
            return nil
        }
        return .init(string: String(string.prefix(Int(otherLength))))
    }
}

extension LengthedGeohash {

    public struct Neighbors: Hashable {
        public let north: LengthedGeohash
        public let south: LengthedGeohash
        public let west: LengthedGeohash
        public let east: LengthedGeohash
        public let northWest: LengthedGeohash
        public let northEast: LengthedGeohash
        public let southWest: LengthedGeohash
        public let southEast: LengthedGeohash

        public var allNeighbors: Set<LengthedGeohash> {
            [north, south, west, east, northWest, northEast, southWest, southEast]
        }

        public func allNeighbors(and center: LengthedGeohash) -> Set<LengthedGeohash> {
            [north, south, west, east, northWest, northEast, southWest, southEast, center]
        }
    }
}
