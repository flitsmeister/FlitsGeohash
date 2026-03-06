# FlitsGeohash

`FlitsGeohash` is a Swift package for working with geohashes on Apple platforms. It wraps a small C implementation with a Swift-friendly API for encoding coordinates, finding adjacent cells, collecting neighbors, and generating the geohashes that cover a region.

## Features

- Encode `CLLocationCoordinate2D` values into geohash strings
- Get adjacent geohashes in the four cardinal directions
- Fetch all 8 neighboring geohashes
- Generate the geohashes that cover a map region
- Use strongly typed fixed-length geohashes for common lengths

## Requirements

- Swift 6.0+
- `CoreLocation`
- Apple platforms where `CoreLocation` is available

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/flitsmeister/FlitsGeohash.git", from: "1.3.0")
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
import CoreLocation
import FlitsGeohash

let coordinate = CLLocationCoordinate2D(
    latitude: 57.64911063015461,
    longitude: 10.40743969380855
)

let hash = Geohash.hash(coordinate, length: 11)
// "u4pruydqqvj"

let shortHash = coordinate.geohash(length: 5)
// "u4pru"
```

The string-based API accepts geohash lengths from `1...22`.

### Adjacent cells and neighbors

```swift
let hash = "u4pruydqqvj"

let north = Geohash.adjacent(hash: hash, direction: .north)
// "u4pruydqqvm"

let neighbors = Geohash.neighbors(hash: hash)
print(neighbors.east)       // "u4pruydqqvn"
print(neighbors.southWest)  // "u4pruydqquu"
print(neighbors.allNeighbors)
```

### Cover a region with geohashes

```swift
let hashes = Geohash.hashesForRegion(
    centerCoordinate: .init(latitude: 57.64911063015461, longitude: 10.40743969380855),
    latitudeDelta: 2,
    longitudeDelta: 2,
    length: 3
)

print(hashes.sorted())
// ["u4n", "u4p", "u4q", "u4r", "u60", "u62"]
```

### Use fixed-length geohash types

For stricter code, the package also exposes typed geohashes for lengths `1...11`:

```swift
let geohash = Geohash11(coordinate)
print(geohash.string) // "u4pruydqqvj"

let neighbors = geohash.neighbors()
print(neighbors.north.string) // "u4pruydqqvm"

let lowerPrecision: Geohash5? = geohash.toLowerLength()
print(lowerPrecision?.string as Any) // Optional("u4pru")
```

Typed region coverage is also available:

```swift
let regionHashes = Geohash3.hashesForRegion(
    centerCoordinate: .init(latitude: 57.64911063015461, longitude: 10.40743969380855),
    latitudeDelta: 2,
    longitudeDelta: 2
)
```

## Running Tests

```bash
swift test
```

The test suite includes correctness checks and performance-oriented coverage for encoding, adjacency, neighbors, and region generation.
