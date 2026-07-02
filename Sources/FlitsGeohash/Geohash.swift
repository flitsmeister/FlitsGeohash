//
//  Geohash.swift
//  FlitsGeohash
//

#if canImport(CoreLocation)
import CoreLocation
#endif

/// A geohash of length 1...12, packed into a single `UInt64`.
///
/// Bit layout: the `5 × length` hash bits are left-aligned starting at
/// bit 63; the length is stored in the low 4 bits. Length 12 uses exactly
/// 60 + 4 bits. Because the unused middle bits are always zero, equality
/// and hashing are plain `UInt64` operations, geohashes of different
/// lengths never collide as dictionary keys, and `prefix(_:)` is a mask
/// plus a length update.
///
/// Boundary rule: a coordinate exactly on a cell boundary belongs to the
/// higher cell (canonical `>=` / floor semantics). Longitude wraps at the
/// antimeridian; latitude does not wrap at the poles.
public struct Geohash: Hashable, Sendable {

    /// Packed representation: hash bits from bit 63 down, length in bits 3...0.
    @usableFromInline
    internal let rawValue: UInt64

    @usableFromInline
    internal init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// Encodes a coordinate at the given length.
    ///
    /// Returns `nil` if the coordinate is outside latitude -90...90 /
    /// longitude -180...180 (or not finite), or if `length` is outside 1...12.
    @inlinable
    public init?(_ coordinate: CLLocationCoordinate2D, length: Int) {
        guard length >= 1, length <= 12,
              coordinate.latitude >= -90, coordinate.latitude <= 90,
              coordinate.longitude >= -180, coordinate.longitude <= 180
        else {
            return nil
        }
        let totalBits = 5 * length
        let longitudeBits = (totalBits + 1) / 2
        let latitudeBits = totalBits / 2
        let x = Geohash.axisIndex(coordinate.longitude, offset: 180, span: 360, bits: longitudeBits)
        let y = Geohash.axisIndex(coordinate.latitude, offset: 90, span: 180, bits: latitudeBits)
        self.init(x: x, y: y, length: length)
    }

    /// Builds a geohash from precomputed axis indices. `x` must fit in
    /// ⌈5L/2⌉ bits and `y` in ⌊5L/2⌋ bits.
    @usableFromInline
    internal init(x: UInt64, y: UInt64, length: Int) {
        let totalBits = 5 * length
        // The geohash bit stream is longitude-first from the MSB. When the
        // total bit count is odd the stream also ends on a longitude bit,
        // so longitude occupies the even positions of the interleaved word;
        // when it is even, longitude occupies the odd positions.
        let interleaved: UInt64
        if totalBits & 1 == 1 {
            interleaved = Geohash.spread(x) | (Geohash.spread(y) << 1)
        } else {
            interleaved = (Geohash.spread(x) << 1) | Geohash.spread(y)
        }
        self.rawValue = (interleaved << (64 - totalBits)) | UInt64(length)
    }

    /// The number of base32 characters, 1...12.
    @inlinable
    public var length: Int {
        Int(rawValue & 0xF)
    }

    /// Truncates to a shorter (or equal) length. Equivalent to encoding the
    /// same coordinate at the shorter length, without recomputing.
    ///
    /// - Precondition: `1 <= length <= self.length`
    @inlinable
    public func prefix(_ length: Int) -> Geohash {
        precondition(length >= 1 && length <= self.length, "prefix length must be in 1...length")
        let mask = ~UInt64(0) << (64 - 5 * length)
        return Geohash(rawValue: (rawValue & mask) | UInt64(length))
    }

    /// The center coordinate of the cell.
    @inlinable
    public var center: CLLocationCoordinate2D {
        let (x, y) = axisIndices
        let totalBits = 5 * length
        let longitudeBits = (totalBits + 1) / 2
        let latitudeBits = totalBits / 2
        // 360 / 2^n and 180 / 2^m are exactly representable, so the cell
        // arithmetic below is exact apart from the final add.
        let cellWidth = 360.0 / Double(UInt64(1) << longitudeBits)
        let cellHeight = 180.0 / Double(UInt64(1) << latitudeBits)
        return CLLocationCoordinate2D(
            latitude: (Double(y) + 0.5) * cellHeight - 90,
            longitude: (Double(x) + 0.5) * cellWidth - 180
        )
    }

    /// The angular size of the cell.
    @inlinable
    public var bounds: (latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        let totalBits = 5 * length
        let longitudeBits = (totalBits + 1) / 2
        let latitudeBits = totalBits / 2
        return (
            latitudeDelta: 180.0 / Double(UInt64(1) << latitudeBits),
            longitudeDelta: 360.0 / Double(UInt64(1) << longitudeBits)
        )
    }

    /// The (longitude, latitude) fixed-point indices of the cell.
    @usableFromInline
    internal var axisIndices: (x: UInt64, y: UInt64) {
        let totalBits = 5 * length
        let interleaved = rawValue >> (64 - totalBits)
        if totalBits & 1 == 1 {
            return (Geohash.compact(interleaved), Geohash.compact(interleaved >> 1))
        } else {
            return (Geohash.compact(interleaved >> 1), Geohash.compact(interleaved))
        }
    }

    /// Scales an axis value to a `bits`-wide fixed-point index with floor
    /// semantics; the top of the range (lat 90 / lon 180) clamps into the
    /// last cell.
    @usableFromInline
    internal static func axisIndex(_ value: Double, offset: Double, span: Double, bits: Int) -> UInt64 {
        let cellCount = Double(UInt64(1) << bits)
        let scaled = ((value + offset) / span) * cellCount
        if scaled <= 0 { return 0 }
        if scaled >= cellCount { return (UInt64(1) << bits) - 1 }
        var index = UInt64(scaled)
        // The scaling above can round across a cell edge for values within a
        // few ulps of the edge. Cell edges (index * cellSize - offset) are
        // exactly representable, so one exact comparison restores strict
        // floor semantics: edge(index) <= value < edge(index + 1).
        let cellSize = span / cellCount
        if Double(index) * cellSize - offset > value {
            index -= 1
        } else if Double(index + 1) * cellSize - offset <= value {
            index += 1
        }
        return index
    }

    /// Spreads the low 32 bits of `value` to the even bit positions.
    @usableFromInline
    internal static func spread(_ value: UInt64) -> UInt64 {
        var x = value
        x = (x | (x << 16)) & 0x0000_FFFF_0000_FFFF
        x = (x | (x << 8)) & 0x00FF_00FF_00FF_00FF
        x = (x | (x << 4)) & 0x0F0F_0F0F_0F0F_0F0F
        x = (x | (x << 2)) & 0x3333_3333_3333_3333
        x = (x | (x << 1)) & 0x5555_5555_5555_5555
        return x
    }

    /// Gathers the even bit positions of `value` into the low 32 bits.
    @usableFromInline
    internal static func compact(_ value: UInt64) -> UInt64 {
        var x = value & 0x5555_5555_5555_5555
        x = (x | (x >> 1)) & 0x3333_3333_3333_3333
        x = (x | (x >> 2)) & 0x0F0F_0F0F_0F0F_0F0F
        x = (x | (x >> 4)) & 0x00FF_00FF_00FF_00FF
        x = (x | (x >> 8)) & 0x0000_FFFF_0000_FFFF
        x = (x | (x >> 16)) & 0x0000_0000_FFFF_FFFF
        return x
    }
}
