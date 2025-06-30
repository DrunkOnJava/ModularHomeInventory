// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TestUtilities",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TestUtilities",
            targets: ["TestUtilities"]
        )
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
    ],
    targets: [
        .target(
            name: "TestUtilities",
            dependencies: [
                "Core",
                "SharedUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TestUtilitiesTests",
            dependencies: ["TestUtilities"],
            path: "Tests"
        )
    ]
)