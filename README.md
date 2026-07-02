# FlitsGeohash

[![Swift](https://github.com/flitsmeister/FlitsGeohash/actions/workflows/swift.yml/badge.svg)](https://github.com/flitsmeister/FlitsGeohash/actions/workflows/swift.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

`FlitsGeohash` is a pure-Swift geohash library for Apple platforms and Linux.
A `Geohash` is a value type packed into a single `UInt64`: encoding a
coordinate takes ~12 ns, a neighbor lookup ~5 ns, and no operation on the
packed form allocates. Use `Geohash` values as dictionary keys and set
members directly — reach for `.string` only at the edges of your system.

Migrating from 1.x? See [MIGRATION.md](MIGRATION.md).

## Features

- Encode `CLLocationCoordinate2D` into a `Geohash` of length 1...12
- Cell geometry: `center`, `bounds`, and `prefix(_:)` for coarser cells
- All 8 neighbors, with longitude wrapping at the antimeridian and honest
  `nil` past the pole rows
- `cells(intersecting:)` to cover a map region
- `Hashable`, `Sendable`, and `Codable` (encodes as the base32 string)
- Runs unchanged on Linux — a compatible `CLLocationCoordinate2D` is
  provided where `CoreLocation` is unavailable

## Requirements

- Swift 6.0+
- Apple platforms or Linux

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/flitsmeister/FlitsGeohash.git", from: "2.0.0")
]
```

Then add the product to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "FlitsGeohash", package: "FlitsGeohash")
        ]
    )
]
```

## Usage

### Encode a coordinate

```swift
#if canImport(CoreLocation)
import CoreLocation
#endif
import FlitsGeohash

let coordinate = CLLocationCoordinate2D(
    latitude: 57.64911063015461,
    longitude: 10.40743969380855
)

let geohash = Geohash(coordinate, length: 11)   // nil for invalid input
geohash?.string                                  // "u4pruydqqvj"
geohash?.prefix(5).string                        // "u4pru"

Geohash(string: "u4pru")                         // parse back from base32
```

A coordinate exactly on a cell boundary belongs to the higher cell (the
canonical rule shared by mainstream implementations).

### Cell geometry

```swift
let cell = Geohash(string: "u4pru")!
cell.center            // CLLocationCoordinate2D in the middle of the cell
cell.bounds            // (latitudeDelta: 0.0439..., longitudeDelta: 0.0439...)
cell.length            // 5
```

### Neighbors

```swift
let neighbors = cell.neighbors()   // fixed struct, no allocation
neighbors.east                     // always exists: longitude wraps
neighbors.north                    // optional: nil in the top latitude row

cell.neighbor(.southWest)          // single step, ~5 ns
cell.allNeighborsAndSelf()         // [Geohash], 9 cells (6 in a pole row)
```

There is nothing north of the pole row, so `neighbor(.north)` on a top-row
cell like `"zzzz"` returns `nil` rather than wrapping. East and west wrap at
the antimeridian and always exist.

### Cover a region

```swift
let cells = Geohash.cells(
    intersecting: coordinate,
    latitudeDelta: 2,
    longitudeDelta: 2,
    length: 3
)
cells.map(\.string).sorted()
// ["u4n", "u4p", "u4q", "u4r", "u60", "u62"]
```

The result size is capped (`maxCells:` parameter, default 10,000): a box
covering more cells than that — say a zoomed-out viewport at a fine length —
returns `[]` instead of allocating millions of cells. Use a shorter length
or split the box.

### Keys, sets, and Codable

`Geohash` equality and hashing are single `UInt64` operations, and hashes of
different lengths never collide as keys:

```swift
var index: [Geohash: [Place]] = [:]
index[Geohash(place.coordinate, length: 7)!, default: []].append(place)
```

`Codable` uses the base32 string, so encoded payloads are interchangeable
with plain geohash strings:

```swift
try JSONEncoder().encode([cell])   // ["u4pru"]
```

## Testing & benchmarks

```bash
swift test                                # correctness, 108k golden fixtures, property tests
swift run -c release Benchmarks           # performance report
swift run -c release Benchmarks enforce   # fail on gate violations (used in CI)
```

The golden fixtures were generated with the 1.x C implementation before it
was removed, so 2.0 is verified bit-for-bit compatible outside the
documented behavioral changes. CI runs on macOS and Ubuntu.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
