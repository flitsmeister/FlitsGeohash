//
//  GeohashParser.swift
//  
//
//  Created by Tomas Harkema on 12/09/2023.
//

import Foundation

struct GeohashParser {
    static func parse<Length: GeohashLengthed>(hash: String) -> GeohashDecoded<Length>? {
        // For example: hash = u4pruydqqvj

        guard hash.count == Length.length else {
            return nil
        }

        let bits = hash
            .map { Self.bitmap[$0] ?? "?" }
            .joined(separator: "")
        guard bits.count % 5 == 0 else { return nil }
        // bits = 1101000100101011011111010111100110010110101101101110001

        let (lat, lon) = bits.enumerated().reduce(into: ([Character](), [Character]())) {
            if $1.0 % 2 == 0 {
                $0.1.append($1.1)
            } else {
                $0.0.append($1.1)
            }
        }
        // lat = [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0]
        // lon = [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1]

        func combiner(array a: (min: Double, max: Double), value: Character) -> (Double, Double) {
            let mean = (a.min + a.max) / 2
            return value == "1" ? (mean, a.max) : (a.min, mean)
        }

        let latRange = lat.reduce((-90.0, 90.0), combiner)
        // latRange = (57.649109959602356, 57.649111300706863)

        let lonRange = lon.reduce((-180.0, 180.0), combiner)
        // lonRange = (10.407439023256302, 10.407440364360809)

        return GeohashDecoded<Length>(originalString: hash, latitude: latRange, longitude: lonRange)
    }

    static func encode<Length: GeohashLengthed>(latitude: Double, longitude: Double) -> GeohashEncoded<Length> {
        // For example: (latitude, longitude) = (57.6491106301546, 10.4074396938086)
        let length = Length.length

        func combiner(array a: (min: Double, max: Double, array: [String]), value: Double) -> (Double, Double, [String]) {
            let mean = (a.min + a.max) / 2
            if value < mean {
                return (a.min, mean, a.array + "0")
            } else {
                return (mean, a.max, a.array + "1")
            }
        }

        let lat = Array(repeating: latitude, count: Int(length * 5)).reduce((-90.0, 90.0, [String]()), combiner)
        // lat = (57.64911063015461, 57.649110630154766, [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,0,...])

        let lon = Array(repeating: longitude, count: Int(length * 5)).reduce((-180.0, 180.0, [String]()), combiner)
        // lon = (10.407439693808236, 10.407439693808556, [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1,0,1,..])

        let latlon = lon.2.enumerated().flatMap { [$1, lat.2[$0]] }
        // latlon - [1,1,0,1,0,0,0,1,0,0,1,0,1,0,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,...]

        let bits = latlon.enumerated().reduce([String]()) { $1.0 % 5 > 0 ? $0 << $1.1 : $0 + $1.1 }
        //  bits: [11010,00100,10101,10111,11010,11110,01100,10110,10110,11011,10001,10010,10101,...]

        let arr = bits.compactMap { charmap[$0] }
        // arr: [u,4,p,r,u,y,d,q,q,v,j,k,p,b,...]

        return GeohashEncoded(geohash: String(arr.prefix(Int(length))))
    }

    // MARK: Private

    private static let bitmap = "0123456789bcdefghjkmnpqrstuvwxyz"
        .enumerated()
        .map {
            ($1, String(integer: $0, radix: 2, padding: 5))
        }
        .reduce(into: [Character: String]()) {
            $0[$1.0] = $1.1
        }

    private static let charmap = bitmap
        .reduce(into: [String: Character]()) {
            $0[$1.1] = $1.0
        }
}

private func + (left: [String], right: String) -> [String] {
    var arr = left
    arr.append(right)
    return arr
}

private func << (left: [String], right: String) -> [String] {
    var arr = left
    var s = arr.popLast()!
    s += right
    arr.append(s)
    return arr
}

public extension Geohash {
    private static var base32: String {
        return "0123456789bcdefghjkmnpqrstuvwxyz"
    }

    enum Direction: String {
        case n, e, s, w

        var neighbor: [String] {
            switch self {
            case .n:
                return ["p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx"]
            case .e:
                return ["bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy"]
            case .s:
                return ["14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp"]
            case .w:
                return ["238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb"]
            }
        }

        var border: [String] {
            switch self {
            case .n:
                return ["prxz", "bcfguvyz"]
            case .e:
                return ["bcfguvyz", "prxz"]
            case .s:
                return ["028b", "0145hjnp"]
            case .w:
                return ["0145hjnp", "028b"]
            }
        }
    }

    func adjacent(direction: Direction) -> Geohash {
        let hash = self.string
        let lastChar = hash.last!
        var parent = Geohash(stringLiteral: String(hash.dropLast()))
        let type = hash.count % 2

        // Check for edge-cases which don't share common prefix
        if direction.border[type].contains(lastChar), !parent.string.isEmpty {
            parent = parent.adjacent(direction: direction)
        }

        // Append letter for direction to parent
        let charIndex = direction.neighbor[type].distance(of: lastChar)!
        return Geohash(stringLiteral: parent.string.appending(String(Self.base32[charIndex])))
    }

    func neighbors() -> [Geohash] {
        let n = adjacent(direction: .n)
        let e = adjacent(direction: .e)
        let s = adjacent(direction: .s)
        let w = adjacent(direction: .w)

        return [
            n, e, s, w,
            n.adjacent(direction: .e), // ne
            s.adjacent(direction: .e), // se
            n.adjacent(direction: .w), // nw
            s.adjacent(direction: .w) // sw
        ]
    }
}

private extension String {
    init(integer n: Int, radix: Int, padding: Int) {
        let s = String(n, radix: radix)
        let pad = (padding - s.count % padding) % padding
        self = Array(repeating: "0", count: pad).joined(separator: "") + s
    }
}

private extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }

    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

private extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

private extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}
