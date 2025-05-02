
import XCTest
import CoreLocation
@testable import FlitsGeohash
@testable import FlitsGeohashC

final class GeohashTests: XCTestCase {

    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let chars = "u4pruydqqvj"

        XCTAssertEqual(Geohash10(coordinate).string, String(chars.prefix(10)))
        XCTAssertEqual(Geohash9(coordinate).string, String(chars.prefix(9)))
        XCTAssertEqual(Geohash8(coordinate).string, String(chars.prefix(8)))
        XCTAssertEqual(Geohash7(coordinate).string, String(chars.prefix(7)))
        XCTAssertEqual(Geohash6(coordinate).string, String(chars.prefix(6)))
        XCTAssertEqual(Geohash5(coordinate).string, String(chars.prefix(5)))
        XCTAssertEqual(Geohash4(coordinate).string, String(chars.prefix(4)))
        XCTAssertEqual(Geohash3(coordinate).string, String(chars.prefix(3)))
        XCTAssertEqual(Geohash2(coordinate).string, String(chars.prefix(2)))
        XCTAssertEqual(Geohash1(coordinate).string, String(chars.prefix(1)))
    }

    func testGetAdjacent() {
        let north = Geohash11(string: "u4pruydqqvj").adjacent(direction: .north)
        let east = Geohash11(string: "u4pruydqqvj").adjacent(direction: .east)
        let south = Geohash11(string: "u4pruydqqvj").adjacent(direction: .south)
        let west = Geohash11(string: "u4pruydqqvj").adjacent(direction: .west)

        XCTAssertEqual(north.string, "u4pruydqqvm")
        XCTAssertEqual(east.string, "u4pruydqqvn")
        XCTAssertEqual(south.string, "u4pruydqquv")
        XCTAssertEqual(west.string, "u4pruydqqvh")
    }

    func testGetNeighbors() {
        let neighbors = Geohash11(string: "u4pruydqqvj").neighbors()
        let expectedNeighbors = LengthedGeohash<GeohashLength11>.Neighbors(
            north: .init(string: "u4pruydqqvm"),
            south: .init(string: "u4pruydqquv"),
            west: .init(string: "u4pruydqqvh"),
            east: .init(string: "u4pruydqqvn"),
            northWest: .init(string: "u4pruydqqvk"),
            northEast: .init(string: "u4pruydqqvq"),
            southWest: .init(string: "u4pruydqquu"),
            southEast: .init(string: "u4pruydqquy")
        )
        XCTAssertEqual(neighbors, expectedNeighbors)
    }

    func testLowerLength() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let chars = "u4pruydqqvj"

        let geohash11 = Geohash11(coordinate)
        XCTAssertEqual(geohash11.string, String(chars.prefix(11)))

        let geohash10: Geohash10? = geohash11.toLowerLength()
        XCTAssertEqual(geohash10?.string, String(chars.prefix(10)))

        let geohash2: Geohash2? = geohash11.toLowerLength()
        XCTAssertEqual(geohash2?.string, String(chars.prefix(2)))

        let geohash11FromLower: Geohash11? = geohash2?.toLowerLength()
        XCTAssertNil(geohash11FromLower)

        let geohashFromSame: Geohash11? = geohash11.toLowerLength()
        XCTAssertEqual(geohashFromSame, geohash11)
    }
    
    func testRegion() {
        let expectedHashes: Set<String> = ["u14zr","u14yd","u16bj","u14yg","u16b4","u14zd","u16bc","u14yf","u16bd","u14zb","u14xn","u14zh","u14zp","u16b6","u16bz","u14xq","u14wy","u14xy","u14wx","u14zq","u16bh","u14zc","u16b3","u16bv","u14xp","u14zv","u14zf","u14wz","u14xz","u14ww","u16b2","u168w","u16bq","u16bb","u16bk","u14zs","u14yx","u16b1","u14ye","u14zm","u14zy","u14yv","u16bg","u16bn","u16bt","u14zu","u16b7","u14yc","u14xx","u16bx","u14z3","u14y9","u14z9","u14zn","u16br","u16be","u16bf","u14yu","u16b9","u14xr","u16b8","u16b5","u14z8","u14yy","u14zg","u168n","u14zx","u14z5","u14y8","u14zt","u168x","u14zz","u14z0","u16bm","u14zj","u14yt","u168q","u168z","u14xw","u16b0","u14z2","u14yz","u14ze","u16bs","u14z6","u14z7","u14ys","u14zw","u14z1","u14yb","u16bw","u16bp","u14zk","u14z4","u16by","u168r","u14yw","u168p","u168y","u16bu"]
        let center = CLLocationCoordinate2D(latitude: 52, longitude: 4)
        var hashesInRegion: Set<String> = []
        measure {
            let region = Geohash.Region(center: center, latitudeDelta: 0.4, longitudeDelta: 0.4)
            hashesInRegion = Geohash5.hashes(for: region).reduce(into: Set(), { $0.insert($1.string) })
        }
        XCTAssertEqual(hashesInRegion, expectedHashes)
    }
    
    func testRegionC() {
        let expectedHashes: [String] = ["u14zr","u14yd","u16bj","u14yg","u16b4","u14zd","u16bc","u14yf","u16bd","u14zb","u14xn","u14zh","u14zp","u16b6","u16bz","u14xq","u14wy","u14xy","u14wx","u14zq","u16bh","u14zc","u16b3","u16bv","u14xp","u14zv","u14zf","u14wz","u14xz","u14ww","u16b2","u168w","u16bq","u16bb","u16bk","u14zs","u14yx","u16b1","u14ye","u14zm","u14zy","u14yv","u16bg","u16bn","u16bt","u14zu","u16b7","u14yc","u14xx","u16bx","u14z3","u14y9","u14z9","u14zn","u16br","u16be","u16bf","u14yu","u16b9","u14xr","u16b8","u16b5","u14z8","u14yy","u14zg","u168n","u14zx","u14z5","u14y8","u14zt","u168x","u14zz","u14z0","u16bm","u14zj","u14yt","u168q","u168z","u14xw","u16b0","u14z2","u14yz","u14ze","u16bs","u14z6","u14z7","u14ys","u14zw","u14z1","u14yb","u16bw","u16bp","u14zk","u14z4","u16by","u168r","u14yw","u168p","u168y","u16bu"].sorted()
        let center = CLLocationCoordinate2D(latitude: 52, longitude: 4)
        var hashes: [String] = []
        measure {
            hashes = Geohash.hashesC(centerCoordinate: center, latitudeDelta: 0.4, longitudeDelta: 0.4, length: 5)
        }
        XCTAssertEqual(hashes.sorted(), expectedHashes)
    }
}
