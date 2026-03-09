//
//  CoordinateCompatibility.swift
//
//
//  Created by Maarten Zonneveld on 09/03/2026.
//

#if canImport(CoreLocation)
import CoreLocation
#else
import Foundation

public typealias CLLocationDegrees = Double

public struct CLLocationCoordinate2D: Sendable, Hashable {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

@inline(__always)
public func CLLocationCoordinate2DIsValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
    (-90...90).contains(coordinate.latitude) && (-180...180).contains(coordinate.longitude)
}
#endif
