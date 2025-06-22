// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        ),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests"
        ),
    ]
)