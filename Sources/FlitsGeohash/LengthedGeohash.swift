//
//  LengthedGeohash.swift
//  FlitsGeohash
//

#if canImport(CoreLocation)
import CoreLocation
#endif

/// A phantom type carrying a fixed geohash length.
public protocol GeohashLengthed {
    static var length: Int { get }
}

public enum GeohashLength12: GeohashLengthed {
    public static let length = 12
}
public enum GeohashLength11: GeohashLengthed {
    public static let length = 11
}
public enum GeohashLength10: GeohashLengthed {
    public static let length = 10
}
public enum GeohashLength9: GeohashLengthed {
    public static let length = 9
}
public enum GeohashLength8: GeohashLengthed {
    public static let length = 8
}
public enum GeohashLength7: GeohashLengthed {
    public static let length = 7
}
public enum GeohashLength6: GeohashLengthed {
    public static let length = 6
}
public enum GeohashLength5: GeohashLengthed {
    public static let length = 5
}
public enum GeohashLength4: GeohashLengthed {
    public static let length = 4
}
public enum GeohashLength3: GeohashLengthed {
    public static let length = 3
}
public enum GeohashLength2: GeohashLengthed {
    public static let length = 2
}
public enum GeohashLength1: GeohashLengthed {
    public static let length = 1
}

public typealias Geohash12 = LengthedGeohash<GeohashLength12>
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

/// A `Geohash` whose length is part of the type, so lengths cannot be mixed
/// up at compile time. It wraps the packed `Geohash` — same 8-byte storage,
/// same allocation-free operations.
public struct LengthedGeohash<Length: GeohashLengthed>: Hashable, Sendable {

    /// The underlying packed geohash; its `length` always equals `Length.length`.
    public let geohash: Geohash

    /// Wraps a packed geohash. Returns `nil` when its length does not
    /// match `Length.length`.
    @inlinable
    public init?(_ geohash: Geohash) {
        guard geohash.length == Length.length else { return nil }
        self.geohash = geohash
    }

    /// Encodes a coordinate at `Length.length`. Returns `nil` for an
    /// invalid coordinate (v1 trapped instead).
    @inlinable
    public init?(_ coordinate: CLLocationCoordinate2D) {
        guard let geohash = Geohash(coordinate, length: Length.length) else { return nil }
        self.geohash = geohash
    }

    /// Parses a base32 string of exactly `Length.length` characters.
    /// Returns `nil` for a malformed string or a length mismatch (v1
    /// asserted instead).
    @inlinable
    public init?(string: String) {
        guard let geohash = Geohash(string: string), geohash.length == Length.length else {
            return nil
        }
        self.geohash = geohash
    }

    @usableFromInline
    internal init(unchecked geohash: Geohash) {
        self.geohash = geohash
    }

    @inlinable
    public var string: String {
        geohash.string
    }

    /// The adjacent cell in the given direction; `nil` past the pole rows,
    /// like `Geohash.neighbor(_:)`.
    @inlinable
    public func adjacent(direction: Geohash.Direction) -> LengthedGeohash? {
        geohash.neighbor(direction).map(LengthedGeohash.init(unchecked:))
    }

    @inlinable
    public func neighbors() -> Neighbors {
        let neighbors = geohash.neighbors()
        return Neighbors(
            north: neighbors.north.map(LengthedGeohash.init(unchecked:)),
            northEast: neighbors.northEast.map(LengthedGeohash.init(unchecked:)),
            east: LengthedGeohash(unchecked: neighbors.east),
            southEast: neighbors.southEast.map(LengthedGeohash.init(unchecked:)),
            south: neighbors.south.map(LengthedGeohash.init(unchecked:)),
            southWest: neighbors.southWest.map(LengthedGeohash.init(unchecked:)),
            west: LengthedGeohash(unchecked: neighbors.west),
            northWest: neighbors.northWest.map(LengthedGeohash.init(unchecked:))
        )
    }

    /// Truncates to a shorter typed length; `nil` when `L` is longer than
    /// `Length` (same shape as v1).
    @inlinable
    public func toLowerLength<L: GeohashLengthed>() -> LengthedGeohash<L>? {
        guard L.length <= Length.length else { return nil }
        return LengthedGeohash<L>(unchecked: geohash.prefix(L.length))
    }

    /// All cells of this length intersecting the given box. See
    /// `Geohash.cells(intersecting:latitudeDelta:longitudeDelta:length:maxCells:)`
    /// for clamping and the result-size cap.
    public static func hashesForRegion(
        centerCoordinate: CLLocationCoordinate2D,
        latitudeDelta: CLLocationDegrees,
        longitudeDelta: CLLocationDegrees,
        maxCells: Int = 10_000
    ) -> [LengthedGeohash] {
        Geohash.cells(
            intersecting: centerCoordinate,
            latitudeDelta: latitudeDelta,
            longitudeDelta: longitudeDelta,
            length: Length.length,
            maxCells: maxCells
        )
        .map(LengthedGeohash.init(unchecked:))
    }
}

extension LengthedGeohash {

    /// All eight adjacent cells, with the same optionality as
    /// `Geohash.Neighbors`: east and west always exist, the rows toward a
    /// pole are `nil` in the top/bottom latitude row.
    public struct Neighbors: Hashable, Sendable {
        public let north: LengthedGeohash?
        public let northEast: LengthedGeohash?
        public let east: LengthedGeohash
        public let southEast: LengthedGeohash?
        public let south: LengthedGeohash?
        public let southWest: LengthedGeohash?
        public let west: LengthedGeohash
        public let northWest: LengthedGeohash?

        public init(
            north: LengthedGeohash?,
            northEast: LengthedGeohash?,
            east: LengthedGeohash,
            southEast: LengthedGeohash?,
            south: LengthedGeohash?,
            southWest: LengthedGeohash?,
            west: LengthedGeohash,
            northWest: LengthedGeohash?
        ) {
            self.north = north
            self.northEast = northEast
            self.east = east
            self.southEast = southEast
            self.south = south
            self.southWest = southWest
            self.west = west
            self.northWest = northWest
        }

        /// The neighbors that exist: 8 for interior cells, 5 in a pole row.
        public var allNeighbors: Set<LengthedGeohash> {
            var set: Set<LengthedGeohash> = [east, west]
            if let north { set.insert(north) }
            if let northEast { set.insert(northEast) }
            if let southEast { set.insert(southEast) }
            if let south { set.insert(south) }
            if let southWest { set.insert(southWest) }
            if let northWest { set.insert(northWest) }
            return set
        }

        public func allNeighbors(and center: LengthedGeohash) -> Set<LengthedGeohash> {
            var set = allNeighbors
            set.insert(center)
            return set
        }
    }
}

extension LengthedGeohash: CustomStringConvertible {
    public var description: String { string }
}

extension LengthedGeohash: Codable {

    /// Encoded as the base32 string, like `Geohash`.
    public func encode(to encoder: Encoder) throws {
        try geohash.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let geohash = try Geohash(from: decoder)
        guard geohash.length == Length.length else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Expected a geohash of length \(Length.length), got \(geohash.length)"
            ))
        }
        self.geohash = geohash
    }
}
