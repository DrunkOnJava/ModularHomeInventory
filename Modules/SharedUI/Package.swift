// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "SharedUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "SharedUI",
            targets: ["SharedUI"]
        ),
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: ["Core"],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI"],
            path: "Tests"
        ),
    ]
)