// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Premium",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Premium",
            targets: ["Premium"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "Premium",
            dependencies: ["Core", "SharedUI"],
            path: "Sources"
        ),
        .testTarget(
            name: "PremiumTests",
            dependencies: ["Premium"],
            path: "Tests"
        ),
    ]
)