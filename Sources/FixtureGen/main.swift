//
//  main.swift
//  FixtureGen
//
//  Generates golden fixtures from the v1 C-backed implementation.
//  Run once before the C target is removed; the output files are committed
//  and the v2 pure-Swift implementation is validated against them.
//
//  Usage: swift run -c release FixtureGen [output-directory]
//

import Foundation
import FlitsGeohash

// Deterministic RNG so the fixture set is reproducible.
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    // Uniform in [0, 1)
    mutating func nextDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }
}

// %.17g round-trips a Double exactly through its decimal representation.
func fmt(_ value: Double) -> String {
    String(format: "%.17g", value)
}

// A coordinate axis value lies on a geohash cell boundary if its fixed-point
// scaling at the finest resolution (30 bits, length 12) is an exact integer.
// Coarser-length boundaries are a subset of the finest grid, so one check
// covers all lengths. v1 (`>`) and v2 (`>=`) only disagree on such rows,
// which is why they must not appear in the parity fixtures.
func isOnGridBoundary(_ value: Double, offset: Double, span: Double) -> Bool {
    let scaled = ((value + offset) / span) * Double(1 << 30)
    return scaled == scaled.rounded(.down)
}

func isOnGridBoundary(latitude: Double, longitude: Double) -> Bool {
    isOnGridBoundary(latitude, offset: 90, span: 180)
        || isOnGridBoundary(longitude, offset: 180, span: 360)
}

// Latitude row index at the given geohash length, floor semantics.
func latitudeRow(_ latitude: Double, length: Int) -> (row: UInt64, maxRow: UInt64) {
    let latBits = (5 * length) / 2
    let maxRow = (UInt64(1) << latBits) - 1
    let scaled = ((latitude + 90) / 180) * Double(UInt64(1) << latBits)
    if scaled <= 0 { return (0, maxRow) }
    if scaled >= Double(UInt64(1) << latBits) { return (maxRow, maxRow) }
    return (UInt64(scaled), maxRow)
}

let outputDirectory: String
if CommandLine.arguments.count > 1 {
    outputDirectory = CommandLine.arguments[1]
} else {
    outputDirectory = FileManager.default.currentDirectoryPath + "/Tests/FlitsGeohashTests/Fixtures"
}
try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

var rng = SplitMix64(seed: 0x5EED_F1A5_6E0A_5A5A)

// MARK: - Encode fixtures: lat \t lon \t length \t v1 hash

let rowsPerLength = 9_000
var encodeLines: [String] = []
var encodeCoordinates: [(latitude: Double, longitude: Double)] = []
encodeLines.reserveCapacity(rowsPerLength * 12)

for length in 1...12 {
    var produced = 0
    while produced < rowsPerLength {
        let lat = rng.nextDouble(in: -90...90)
        let lon = rng.nextDouble(in: -180...180)
        if isOnGridBoundary(latitude: lat, longitude: lon) { continue }
        let hash = Geohash.hash(
            .init(latitude: lat, longitude: lon),
            length: UInt32(length)
        )
        encodeLines.append("\(fmt(lat))\t\(fmt(lon))\t\(length)\t\(hash)")
        encodeCoordinates.append((lat, lon))
        produced += 1
    }
}

try (encodeLines.joined(separator: "\n") + "\n").write(
    toFile: outputDirectory + "/encode.tsv",
    atomically: true,
    encoding: .utf8
)
print("encode.tsv: \(encodeLines.count) rows")

// MARK: - Neighbor fixtures: hash \t n \t ne \t e \t se \t s \t sw \t w \t nw
//
// Pole-row cells are excluded: v1 wraps latitude across the poles, v2
// deliberately returns nil there (documented breaking change, tested
// separately against the new semantics).

var neighborLines: [String] = []

func neighborRow(latitude: Double, longitude: Double, length: Int) -> String? {
    let (row, maxRow) = latitudeRow(latitude, length: length)
    if row == 0 || row == maxRow { return nil }
    let hash = Geohash.hash(.init(latitude: latitude, longitude: longitude), length: UInt32(length))
    let n = Geohash.neighbors(hash: hash)
    return [hash, n.north, n.northEast, n.east, n.southEast, n.south, n.southWest, n.west, n.northWest]
        .joined(separator: "\t")
}

for length in 1...12 {
    var produced = 0
    while produced < 200 {
        let lat = rng.nextDouble(in: -90...90)
        let lon = rng.nextDouble(in: -180...180)
        if isOnGridBoundary(latitude: lat, longitude: lon) { continue }
        if let row = neighborRow(latitude: lat, longitude: lon, length: length) {
            neighborLines.append(row)
            produced += 1
        }
    }
}

// Antimeridian rows: east/west wraparound parity.
for _ in 0..<200 {
    let lat = rng.nextDouble(in: -85...85)
    let east = rng.next() & 1 == 0
    let lon = east ? rng.nextDouble(in: 179.9...179.999) : rng.nextDouble(in: (-179.999)...(-179.9))
    if isOnGridBoundary(latitude: lat, longitude: lon) { continue }
    let length = 2 + Int(rng.next() % 10) // 2...11
    if let row = neighborRow(latitude: lat, longitude: lon, length: length) {
        neighborLines.append(row)
    }
}

try (neighborLines.joined(separator: "\n") + "\n").write(
    toFile: outputDirectory + "/neighbors.tsv",
    atomically: true,
    encoding: .utf8
)
print("neighbors.tsv: \(neighborLines.count) rows")

// MARK: - Region fixtures: lat \t lon \t latDelta \t lonDelta \t length \t sorted,hashes

let regionDeltaRanges: [Int: ClosedRange<Double>] = [
    3: 1.0...5.0,
    4: 0.3...1.0,
    5: 0.05...0.3,
    6: 0.02...0.1
]

var regionLines: [String] = []
for length in [3, 4, 5, 6] {
    let deltaRange = regionDeltaRanges[length]!
    var produced = 0
    while produced < 50 {
        let lat = rng.nextDouble(in: -80...80)
        let lon = rng.nextDouble(in: -170...170)
        let latDelta = rng.nextDouble(in: deltaRange)
        let lonDelta = rng.nextDouble(in: deltaRange)
        // Region edges on a grid boundary would be affected by the > vs >= change.
        if isOnGridBoundary(latitude: lat - latDelta / 2, longitude: lon - lonDelta / 2) { continue }
        if isOnGridBoundary(latitude: lat + latDelta / 2, longitude: lon + lonDelta / 2) { continue }
        let hashes = Geohash.hashesForRegion(
            centerCoordinate: .init(latitude: lat, longitude: lon),
            latitudeDelta: latDelta,
            longitudeDelta: lonDelta,
            length: UInt32(length)
        )
        regionLines.append(
            "\(fmt(lat))\t\(fmt(lon))\t\(fmt(latDelta))\t\(fmt(lonDelta))\t\(length)\t"
                + hashes.sorted().joined(separator: ",")
        )
        produced += 1
    }
}

try (regionLines.joined(separator: "\n") + "\n").write(
    toFile: outputDirectory + "/regions.tsv",
    atomically: true,
    encoding: .utf8
)
print("regions.tsv: \(regionLines.count) rows")
print("Fixtures written to \(outputDirectory)")
