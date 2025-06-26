//
//  SnapshotTestCase.swift
//  HomeInventoryModularTests
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: HomeInventoryModularTests
//  Dependencies: XCTest, SnapshotTesting
//  Testing: N/A (This is a test base class)
//
//  Description: Base class for snapshot tests providing common configuration and utilities
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting

/// Base class for snapshot tests that provides common configuration
class SnapshotTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Check if we should record snapshots
        #if RECORD_SNAPSHOTS
        isRecording = true
        #endif
        
        // You can also control recording via environment variable
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "true" {
            isRecording = true
        }
    }
    
    override func tearDown() {
        super.tearDown()
        isRecording = false
    }
}

// Common device configurations
extension ViewImageConfig {
    // Modern iPhone configs (using closest available)
    static let iPhone16 = ViewImageConfig.iPhone13
    static let iPhone16Pro = ViewImageConfig.iPhone13Pro  
    static let iPhone16ProMax = ViewImageConfig.iPhone13ProMax
    
    // iPad configs
    static let iPadPro13 = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
        size: CGSize(width: 1024, height: 1366),
        traits: .init(
            horizontalSizeClass: .regular,
            userInterfaceIdiom: .pad,
            verticalSizeClass: .regular
        )
    )
}

// Helper for common test scenarios
extension SnapshotTestCase {
    /// Test a view in both light and dark mode
    func assertSnapshotInBothModes<V: SwiftUI.View>(
        matching view: V,
        as snapshotting: Snapshotting<V, UIImage> = .image(on: .iPhone16ProMax),
        named name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        // Light mode
        assertSnapshot(
            matching: view,
            as: snapshotting,
            named: name.map { "\($0)_light" },
            file: file,
            testName: testName,
            line: line
        )
        
        // Dark mode
        var darkConfig = snapshotting
        if case .image(let config, let precision, let perceptualPrecision, let scale) = snapshotting {
            var traits = config.traits ?? .init()
            traits.userInterfaceStyle = .dark
            let darkViewConfig = ViewImageConfig(
                safeArea: config.safeArea,
                size: config.size,
                traits: traits
            )
            darkConfig = .image(
                on: darkViewConfig,
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                scale: scale
            )
        }
        
        assertSnapshot(
            matching: view,
            as: darkConfig,
            named: name.map { "\($0)_dark" },
            file: file,
            testName: testName,
            line: line
        )
    }
    
    /// Test a view on multiple devices
    func assertSnapshotOnAllDevices<V: SwiftUI.View>(
        matching view: V,
        named name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let devices: [(config: ViewImageConfig, suffix: String)] = [
            (.iPhone16ProMax, "iPhone16ProMax"),
            (.iPhone16, "iPhone16"),
            (.iPadPro11, "iPadPro11"),
            (.iPadPro13, "iPadPro13")
        ]
        
        for (config, suffix) in devices {
            assertSnapshot(
                matching: view,
                as: .image(on: config),
                named: name.map { "\($0)_\(suffix)" } ?? suffix,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}