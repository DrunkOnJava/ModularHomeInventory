// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "BarcodeScanner",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "BarcodeScanner",
            targets: ["BarcodeScanner"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(path: "../AppSettings")
    ],
    targets: [
        .target(
            name: "BarcodeScanner",
            dependencies: ["Core", "SharedUI", "AppSettings"],
            path: "Sources"
        ),
        .testTarget(
            name: "BarcodeScannerTests",
            dependencies: ["BarcodeScanner"],
            path: "Tests"
        ),
    ]
)