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

public struct GeohashLength11: GeohashLengthed {
    public static let length: UInt32 = 11
}
public struct GeohashLength10: GeohashLengthed {
    public static let length: UInt32 = 10
}
public struct GeohashLength9: GeohashLengthed {
    public static let length: UInt32 = 9
}
public struct GeohashLength8: GeohashLengthed {
    public static let length: UInt32 = 8
}
public struct GeohashLength7: GeohashLengthed {
    public static let length: UInt32 = 7
}
public struct GeohashLength6: GeohashLengthed {
    public static let length: UInt32 = 6
}
public struct GeohashLength5: GeohashLengthed {
    public static let length: UInt32 = 5
}
public struct GeohashLength4: GeohashLengthed {
    public static let length: UInt32 = 4
}
public struct GeohashLength3: GeohashLengthed {
    public static let length: UInt32 = 3
}
public struct GeohashLength2: GeohashLengthed {
    public static let length: UInt32 = 2
}
public struct GeohashLength1: GeohashLengthed {
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
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public init(_ coordinate: CLLocationCoordinate2D) {
        self.value = Geohash.hash(coordinate, length: Length.length)
    }

    public func neighbors() -> Neighbors {
        let neighbors = Geohash.neighbors(hash: value)
        return .init(
            north: .init(value: neighbors.north),
            south: .init(value: neighbors.south),
            west: .init(value: neighbors.west),
            east: .init(value: neighbors.east),
            northWest: .init(value: neighbors.northWest),
            northEast: .init(value: neighbors.northEast),
            southWest: .init(value: neighbors.southWest),
            southEast: .init(value: neighbors.southEast)
        )
    }

    public func adjacent(direction: Geohash.Direction) -> LengthedGeohash {
        .init(value: Geohash.adjacent(hash: value, direction: direction))
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