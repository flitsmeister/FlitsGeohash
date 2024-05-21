// swift-tools-version: 5.9

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
            dependencies: ["FlitsGeohashC"]
        ),
        .target(name: "FlitsGeohashC"),
        .testTarget(
            name: "FlitsGeohashTests",
            dependencies: ["FlitsGeohash"]
        )
    ]
)
