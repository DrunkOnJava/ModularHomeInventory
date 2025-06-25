// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Items",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Items",
            targets: ["Items"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(path: "../BarcodeScanner"),
        .package(path: "../Receipts"),
        .package(path: "../Gmail")
    ],
    targets: [
        .target(
            name: "Items",
            dependencies: ["Core", "SharedUI", "BarcodeScanner", "Receipts", "Gmail"],
            path: "Sources"
        ),
        .testTarget(
            name: "ItemsTests",
            dependencies: ["Items"],
            path: "Tests"
        ),
    ]
)