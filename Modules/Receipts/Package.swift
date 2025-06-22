// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Receipts",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Receipts",
            targets: ["Receipts"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "Receipts",
            dependencies: ["Core", "SharedUI"],
            path: "Sources"
        ),
        .testTarget(
            name: "ReceiptsTests",
            dependencies: ["Receipts"],
            path: "Tests"
        ),
    ]
)