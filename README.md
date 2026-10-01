# FlitsGeohash


[![Swift](https://github.com/flitsmeister/FlitsGeohash/actions/workflows/swift.yml/badge.svg)](https://github.com/flitsmeister/FlitsGeohash/actions/workflows/swift.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

`FlitsGeohash` is a Swift package for working with geohashes on Apple platforms, Linux, and Android. It wraps a small C implementation with a Swift-friendly API for encoding coordinates, finding adjacent cells, collecting neighbors, and generating the geohashes that cover a region.

## Features

- Encode `CLLocationCoordinate2D` values into geohash strings
- Get adjacent geohashes in the four cardinal directions, including boundary wraparound
- Fetch all 8 neighboring geohashes, including boundary wraparound
- Generate the geohashes that cover a map region
- Use strongly typed fixed-length geohashes for common lengths
- Use the same coordinate API on Linux and Android without depending on `CoreLocation`

## Requirements

- Swift 6.0+
- Apple platforms where `CoreLocation` is available
- Linux
- Android with a matching Swift Android SDK and NDK (verified with Swift 6.4.0 and NDK r30)

When `CoreLocation` is unavailable, `FlitsGeohash` provides compatible `CLLocationCoordinate2D`, `CLLocationDegrees`, and `CLLocationCoordinate2DIsValid` definitions so the public API stays the same across platforms.

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
#if canImport(CoreLocation)
import CoreLocation
#endif
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

On Linux and Android, the snippet above works unchanged. `FlitsGeohash` exposes a compatible coordinate type when `CoreLocation` is not available.

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

Boundary adjacent cells wrap deterministically instead of failing:

```swift
Geohash.adjacent(hash: "zzzzzz", direction: .east)
// "bpbpbp"

Geohash.adjacent(hash: "000000", direction: .west)
// "pbpbpb"
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

The test suite includes correctness checks and performance-oriented coverage for encoding, adjacency, neighbors, and region generation, and CI runs on both macOS and Ubuntu.

## Android builds

Use the same Swift compiler version as your consuming app, together with its
matching Swift Android SDK. Detour pins that version in `.swift-version`; this
package keeps its Swift 6.0 minimum and does not introduce a separate version pin.

With Swift 6.4.0, its Android SDK installed, and NDK r30 available:

```bash
export ANDROID_NDK_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}/ndk/android-ndk-r30"
swift build -c release --swift-sdk swift-6.4.0-RELEASE_android --triple aarch64-unknown-linux-android29
swift build -c release --swift-sdk swift-6.4.0-RELEASE_android --triple x86_64-unknown-linux-android29
```

Here, `swift` must resolve to the matching open-source toolchain. These commands
cross-compile the Swift wrapper and C implementation without an emulator. Running
Android tests requires an Android device or emulator. Kotlin callers use the
consuming library's JNI bridge; this package remains a Swift package.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
