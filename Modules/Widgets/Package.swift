// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Widgets",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Widgets",
            targets: ["Widgets"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "Widgets",
            dependencies: ["Core", "SharedUI"],
            path: "Sources"
        ),
        .testTarget(
            name: "WidgetsTests",
            dependencies: ["Widgets"],
            path: "Tests"
        ),
    ]
)