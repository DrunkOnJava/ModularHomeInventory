// swift-tools-version: 5.9
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: ["Core", "SharedUI"],
            path: "Sources"
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"],
            path: "Tests"
        ),
    ]
)