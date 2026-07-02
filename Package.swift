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
            name: "FlitsGeohash"
        ),
        .executableTarget(
            name: "Benchmarks",
            dependencies: ["FlitsGeohash"]
        ),
        .testTarget(
            name: "FlitsGeohashTests",
            dependencies: ["FlitsGeohash"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
