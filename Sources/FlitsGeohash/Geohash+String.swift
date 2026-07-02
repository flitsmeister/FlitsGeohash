//
//  Geohash+String.swift
//  FlitsGeohash
//

extension Geohash {

    /// The geohash base32 alphabet (no a, i, l, o).
    @usableFromInline
    internal static let base32Alphabet: [UInt8] = Array("0123456789bcdefghjkmnpqrstuvwxyz".utf8)

    /// Maps an ASCII byte to its base32 digit, or -1 when the byte is not
    /// part of the (lowercase) geohash alphabet.
    @usableFromInline
    internal static let base32Decode: [Int8] = {
        var table = [Int8](repeating: -1, count: 128)
        for (digit, byte) in base32Alphabet.enumerated() {
            table[Int(byte)] = Int8(digit)
        }
        return table
    }()

    /// Parses a strict lowercase base32 geohash of length 1...12.
    @inlinable
    public init?(string: String) {
        var interleaved: UInt64 = 0
        var count = 0
        for byte in string.utf8 {
            guard count < 12, byte < 128 else { return nil }
            let digit = Geohash.base32Decode[Int(byte)]
            guard digit >= 0 else { return nil }
            interleaved = (interleaved << 5) | UInt64(digit)
            count += 1
        }
        guard count >= 1 else { return nil }
        self.init(rawValue: (interleaved << (64 - 5 * count)) | UInt64(count))
    }

    /// The base32 string representation. Intended for the edges of a
    /// system (persistence, wire formats, logging) — keep `Geohash`
    /// values packed everywhere else.
    public var string: String {
        let length = self.length
        let totalBits = 5 * length
        let interleaved = rawValue >> (64 - totalBits)
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 12) { buffer in
            for index in 0..<length {
                let shift = totalBits - 5 * (index + 1)
                buffer[index] = Geohash.base32Alphabet[Int((interleaved >> shift) & 0x1F)]
            }
            return String(decoding: UnsafeBufferPointer(rebasing: buffer[0..<length]), as: UTF8.self)
        }
    }
}

extension Geohash: CustomStringConvertible {
    public var description: String { string }
}

extension Geohash: Codable {

    /// Encoded as the base32 string for wire compatibility.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let geohash = Geohash(string: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid geohash string: \(string)"
            )
        }
        self = geohash
    }
}
