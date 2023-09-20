//
//  GeohashString.swift
//
//
//  Created by Tomas Harkema on 11/09/2023.
//

import Foundation
import CoreLocation

public struct GeohashEncoded<Length: GeohashLengthed>: Hashable, Sendable {
    public let geohash: String

    public init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    public init(latitude: Double, longitude: Double) {
        self = GeohashParser.encode(latitude: latitude, longitude: longitude)
    }

    init(geohash: String) {
        self.geohash = geohash
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(geohash)
    }
}

extension GeohashEncoded: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(geohash: value)
    }
}
