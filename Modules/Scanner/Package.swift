// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Scanner",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Scanner",
            targets: ["Scanner"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(path: "../Settings")
    ],
    targets: [
        .target(
            name: "Scanner",
            dependencies: ["Core", "SharedUI", "Settings"],
            path: "Sources"
        ),
        .testTarget(
            name: "ScannerTests",
            dependencies: ["Scanner"],
            path: "Tests"
        ),
    ]
)