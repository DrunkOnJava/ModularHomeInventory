// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "AppSettings",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AppSettings",
            targets: ["AppSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(path: "../Sync")
    ],
    targets: [
        .target(
            name: "AppSettings",
            dependencies: ["Core", "SharedUI", "Sync"],
            path: "Sources"
        ),
        .testTarget(
            name: "AppSettingsTests",
            dependencies: ["AppSettings"],
            path: "Tests"
        ),
    ]
)