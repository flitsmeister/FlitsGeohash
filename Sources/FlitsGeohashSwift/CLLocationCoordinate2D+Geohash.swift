//
//  CLLocationCoordinate2D+Geohash.swift
//
//
//  Created by Maarten Zonneveld on 08/05/2024.
//

#if canImport(CoreLocation)
import CoreLocation
#endif

public extension CLLocationCoordinate2D {
    
    func geohash(length: UInt32) -> String {
        Geohash.hash(self, length: length)
    }
}
