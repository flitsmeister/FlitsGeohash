//
//  GeohashHolder.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation

public typealias Geohash11 = Geohash<GeohashLength11>
public typealias Geohash10 = Geohash<GeohashLength10>
public typealias Geohash9 = Geohash<GeohashLength9>
public typealias Geohash8 = Geohash<GeohashLength8>
public typealias Geohash7 = Geohash<GeohashLength7>
public typealias Geohash6 = Geohash<GeohashLength6>
public typealias Geohash5 = Geohash<GeohashLength5>
public typealias Geohash4 = Geohash<GeohashLength4>
public typealias Geohash3 = Geohash<GeohashLength3>
public typealias Geohash2 = Geohash<GeohashLength2>
public typealias Geohash1 = Geohash<GeohashLength1>

public enum Geohash<Length: GeohashLengthed> {

    case encoded(GeohashEncoded<Length>)
    case decoded(GeohashDecoded<Length>)

    public var string: String {
        switch self {
        case .encoded(let encoded):
            return encoded.geohash
        case .decoded(let decoded):
            return decoded.originalString
        }
    }

    public var decoded: GeohashDecoded<Length>? {
        switch self {
        case .encoded(let encoded):
            return GeohashParser.parse(hash: encoded.geohash)
        case .decoded(let decoded):
            return decoded
        }
    }    

    public var encoded: GeohashEncoded<Length> {
        switch self {
        case .encoded(let encoded):
            return encoded
        case .decoded(let decoded):
            return .init(stringLiteral: decoded.originalString)
        }
    }
}

extension Geohash: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .encoded(let encoded):
            encoded.hash(into: &hasher)
        case .decoded(let decoded):
            decoded.hash(into: &hasher)
        }
    }
}

extension Geohash: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .encoded(.init(stringLiteral: value))
    }
}

extension Geohash: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = Geohash.encoded(.init(stringLiteral: string))
    }
}

// MARK: - CoreLocation

import CoreLocation

extension Geohash {
    // TODO: this round trip is a bit weird...
    public init(coordinate: CLLocationCoordinate2D) {
        self = .encoded(GeohashEncoded(
            coordinate: coordinate
        ))
    }

    public init(latitude: Double, longitude: Double) {
        self = .encoded(GeohashEncoded(
            latitude: latitude,
            longitude: longitude
        ))
    }
}

extension CLLocationCoordinate2D {
    public init<Length: GeohashLengthed>(geohash: Geohash<Length>) {
        if let decoded = geohash.decoded {
            self = CLLocationCoordinate2DMake((decoded.latitude.min + decoded.latitude.max) / 2, (decoded.longitude.min + decoded.longitude.max) / 2)
        } else {
            self = kCLLocationCoordinate2DInvalid
        }
    }
}

// MARK: - logging

extension Geohash: CustomStringConvertible {
    public var description: String {
        "📍<\(string):\(Length.length)>"
    }
}
