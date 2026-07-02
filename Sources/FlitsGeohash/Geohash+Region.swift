//
//  Geohash+Region.swift
//  FlitsGeohash
//

#if canImport(CoreLocation)
import CoreLocation
#endif

extension Geohash {

    /// All cells at the given length that intersect the box centered on
    /// `center` with the given angular size.
    ///
    /// Latitude is clamped to -90...90 and longitude to -180...180 — the
    /// box does not wrap across the antimeridian or the poles. Returns an
    /// empty array for an invalid center, non-finite or negative deltas,
    /// or a length outside 1...12.
    public static func cells(
        intersecting center: CLLocationCoordinate2D,
        latitudeDelta: CLLocationDegrees,
        longitudeDelta: CLLocationDegrees,
        length: Int
    ) -> [Geohash] {
        guard length >= 1, length <= 12,
              center.latitude >= -90, center.latitude <= 90,
              center.longitude >= -180, center.longitude <= 180,
              latitudeDelta.isFinite, latitudeDelta >= 0,
              longitudeDelta.isFinite, longitudeDelta >= 0
        else {
            return []
        }
        let minLatitude = max(-90, center.latitude - latitudeDelta / 2)
        let maxLatitude = min(90, center.latitude + latitudeDelta / 2)
        let minLongitude = max(-180, center.longitude - longitudeDelta / 2)
        let maxLongitude = min(180, center.longitude + longitudeDelta / 2)

        let totalBits = 5 * length
        let longitudeBits = (totalBits + 1) / 2
        let latitudeBits = totalBits / 2

        let minX = axisIndex(minLongitude, offset: 180, span: 360, bits: longitudeBits)
        let maxX = axisIndex(maxLongitude, offset: 180, span: 360, bits: longitudeBits)
        let minY = axisIndex(minLatitude, offset: 90, span: 180, bits: latitudeBits)
        let maxY = axisIndex(maxLatitude, offset: 90, span: 180, bits: latitudeBits)

        var result: [Geohash] = []
        result.reserveCapacity(Int(maxX - minX + 1) * Int(maxY - minY + 1))
        for y in minY...maxY {
            for x in minX...maxX {
                result.append(Geohash(x: x, y: y, length: length))
            }
        }
        return result
    }
}

public extension CLLocationCoordinate2D {

    /// Encodes the coordinate at the given length; `nil` for invalid input.
    func geohash(length: Int) -> Geohash? {
        Geohash(self, length: length)
    }
}
