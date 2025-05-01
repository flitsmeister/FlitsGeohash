// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FlitsGeohash",
    products: [
        .library(
            name: "FlitsGeohash",
            targets: ["FlitsGeohash"]
        )
    ],
    targets: [
        .target(
            name: "FlitsGeohash",
            dependencies: ["FlitsGeohashC"],
            path: "Sources/FlitsGeohashSwift"
        ),
        .target(name: "FlitsGeohashC"),
        .testTarget(
            name: "FlitsGeohashSwiftTests",
            dependencies: ["FlitsGeohash"]
        )
    ]
)
