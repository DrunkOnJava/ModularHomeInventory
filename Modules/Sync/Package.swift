// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Sync",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Sync",
            targets: ["Sync"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "Sync",
            dependencies: ["Core", "SharedUI"],
            path: "Sources"
        ),
        .testTarget(
            name: "SyncTests",
            dependencies: ["Sync"],
            path: "Tests"
        ),
    ]
)