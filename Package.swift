// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FlitsGeohash",
    products: [
        .library(
            name: "FlitsGeohash",
            targets: ["FlitsGeohashSwift"]
        )
    ],
    targets: [
        .target(
            name: "FlitsGeohashSwift",
            dependencies: ["FlitsGeohashC"]
        ),
        .target(name: "FlitsGeohashC"),
        .testTarget(
            name: "FlitsGeohashSwiftTests",
            dependencies: ["FlitsGeohashSwift"]
        )
    ]
)
