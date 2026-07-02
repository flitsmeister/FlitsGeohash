//
//  Geohash+Neighbors.swift
//  FlitsGeohash
//

extension Geohash {

    public enum Direction: CaseIterable, Sendable {
        case north
        case northEast
        case east
        case southEast
        case south
        case southWest
        case west
        case northWest

        @usableFromInline
        internal var step: (x: Int, y: Int) {
            switch self {
            case .north: (0, 1)
            case .northEast: (1, 1)
            case .east: (1, 0)
            case .southEast: (1, -1)
            case .south: (0, -1)
            case .southWest: (-1, -1)
            case .west: (-1, 0)
            case .northWest: (-1, 1)
            }
        }
    }

    /// All eight adjacent cells. East and west always exist (longitude wraps
    /// at the antimeridian); the north/south rows and their diagonals are
    /// `nil` for cells in the top or bottom latitude row — there is nothing
    /// beyond the poles.
    public struct Neighbors: Hashable, Sendable {
        public let north: Geohash?
        public let northEast: Geohash?
        public let east: Geohash
        public let southEast: Geohash?
        public let south: Geohash?
        public let southWest: Geohash?
        public let west: Geohash
        public let northWest: Geohash?

        @usableFromInline
        internal init(
            north: Geohash?,
            northEast: Geohash?,
            east: Geohash,
            southEast: Geohash?,
            south: Geohash?,
            southWest: Geohash?,
            west: Geohash,
            northWest: Geohash?
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
    }

    /// The adjacent cell in the given direction, or `nil` when the step
    /// would cross a pole (top/bottom latitude row). Longitude wraps at
    /// the antimeridian.
    @inlinable
    public func neighbor(_ direction: Direction) -> Geohash? {
        let step = direction.step
        return shifted(x: step.x, y: step.y)
    }

    /// All eight neighbors as a fixed struct — no array allocation.
    @inlinable
    public func neighbors() -> Neighbors {
        Neighbors(
            north: shifted(x: 0, y: 1),
            northEast: shifted(x: 1, y: 1),
            east: shifted(x: 1, y: 0)!,
            southEast: shifted(x: 1, y: -1),
            south: shifted(x: 0, y: -1),
            southWest: shifted(x: -1, y: -1),
            west: shifted(x: -1, y: 0)!,
            northWest: shifted(x: -1, y: 1)
        )
    }

    /// This cell plus every existing neighbor: 9 elements for interior
    /// cells, 6 for cells in a pole row.
    public func allNeighborsAndSelf() -> [Geohash] {
        let n = neighbors()
        var result: [Geohash] = []
        result.reserveCapacity(9)
        result.append(self)
        result.append(n.east)
        result.append(n.west)
        if let cell = n.north { result.append(cell) }
        if let cell = n.northEast { result.append(cell) }
        if let cell = n.southEast { result.append(cell) }
        if let cell = n.south { result.append(cell) }
        if let cell = n.southWest { result.append(cell) }
        if let cell = n.northWest { result.append(cell) }
        return result
    }

    /// Steps the cell by (-1, 0, 1) on each axis using masked Morton
    /// increments — no de-interleave. Returns `nil` only when a latitude
    /// step would leave the grid.
    @usableFromInline
    internal func shifted(x: Int, y: Int) -> Geohash? {
        let totalBits = 5 * length
        let widthMask = (UInt64(1) << totalBits) &- 1
        let evenMask = 0x5555_5555_5555_5555 & widthMask
        let oddMask = 0xAAAA_AAAA_AAAA_AAAA & widthMask
        // Odd total bit count: longitude occupies the even positions.
        let lonMask = totalBits & 1 == 1 ? evenMask : oddMask
        let latMask = totalBits & 1 == 1 ? oddMask : evenMask
        let lonUnit = lonMask & (~lonMask &+ 1) // lowest set bit
        let latUnit = latMask & (~latMask &+ 1)

        var interleaved = rawValue >> (64 - totalBits)

        if y > 0 {
            if interleaved & latMask == latMask { return nil } // top row: nothing north
            interleaved = (((interleaved | lonMask) &+ latUnit) & latMask) | (interleaved & lonMask)
        } else if y < 0 {
            if interleaved & latMask == 0 { return nil } // bottom row: nothing south
            interleaved = (((interleaved & latMask) &- latUnit) & latMask) | (interleaved & lonMask)
        }

        if x > 0 {
            // Overflow past the last column wraps to column 0 (antimeridian).
            interleaved = (((interleaved | latMask) &+ lonUnit) & lonMask) | (interleaved & latMask)
        } else if x < 0 {
            interleaved = (((interleaved & lonMask) &- lonUnit) & lonMask) | (interleaved & latMask)
        }

        return Geohash(rawValue: (interleaved << (64 - totalBits)) | UInt64(length))
    }
}
