//
//  SnapshotTestingConfiguration.swift
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
//  Dependencies: Foundation, SnapshotTesting, SwiftUI, XCTest
//  Testing: N/A (This is test configuration)
//
//  Description: Global configuration for snapshot testing across all test modules
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SnapshotTesting
import SwiftUI
import XCTest

/// Global configuration for snapshot testing
enum SnapshotTestingConfiguration {
    
    /// Configure snapshot testing environment
    static func setUp() {
        // Set default image precision (0.98 = 98% similarity required)
        // This helps with minor rendering differences between test runs
        SnapshotTesting.diffTool = "ksdiff"  // Use Kaleidoscope if available
        
        // Configure snapshot directory
        // By default, snapshots are stored next to test files in __Snapshots__ folders
    }
    
    /// Standard device configurations for consistent testing
    enum Devices {
        // iPhones
        static let allIPhones: [(config: ViewImageConfig, name: String)] = [
            (.iPhone13Mini, "iPhone_Mini"),
            (.iPhone13, "iPhone_Standard"),
            (.iPhone13ProMax, "iPhone_ProMax")
        ]
        
        // iPads  
        static let allIPads: [(config: ViewImageConfig, name: String)] = [
            (.iPadMini, "iPad_Mini"),
            (.iPadPro11, "iPad_Pro_11"),
            (.iPadPro12_9, "iPad_Pro_13")
        ]
        
        // All devices
        static let all = allIPhones + allIPads
        
        // Common test configurations
        static let iPhoneOnly = allIPhones
        static let iPadOnly = allIPads
        static let hero = [(ViewImageConfig.iPhone13ProMax, "iPhone_Hero"), (ViewImageConfig.iPadPro11, "iPad_Hero")]
    }
    
    /// Standard trait configurations
    enum Traits {
        static let light = UITraitCollection(userInterfaceStyle: .light)
        static let dark = UITraitCollection(userInterfaceStyle: .dark)
        
        static let accessibilitySmall = UITraitCollection(preferredContentSizeCategory: .accessibilityMedium)
        static let accessibilityLarge = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraLarge)
        
        static let rtl = UITraitCollection(layoutDirection: .rightToLeft)
        static let highContrast = UITraitCollection(accessibilityContrast: .high)
        
        // Combined traits
        static let darkAccessibility = UITraitCollection(traitsFrom: [
            dark,
            accessibilityLarge
        ])
    }
}

// MARK: - Helper Extensions

extension XCTestCase {
    
    /// Assert snapshots on all standard devices
    func assertSnapshotsOnAllDevices<V: SwiftUI.View>(
        matching view: V,
        named name: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let previousRecordingState = isRecording
        isRecording = record
        
        for (config, deviceName) in SnapshotTestingConfiguration.Devices.all {
            assertSnapshot(
                matching: view,
                as: .image(on: config),
                named: name.map { "\($0)_\(deviceName)" } ?? deviceName,
                file: file,
                testName: testName,
                line: line
            )
        }
        
        isRecording = previousRecordingState
    }
    
    /// Assert snapshots with all accessibility configurations
    func assertAccessibilitySnapshots<V: SwiftUI.View>(
        matching view: V,
        named name: String? = nil,
        device: ViewImageConfig = .iPhone13ProMax,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let previousRecordingState = isRecording
        isRecording = record
        
        let configurations: [(traits: UITraitCollection, suffix: String)] = [
            (.init(preferredContentSizeCategory: .extraSmall), "textSize_XS"),
            (.init(preferredContentSizeCategory: .large), "textSize_L"),
            (.init(preferredContentSizeCategory: .accessibilityLarge), "textSize_AXL"),
            (.init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge), "textSize_AXXXL"),
            (SnapshotTestingConfiguration.Traits.highContrast, "highContrast"),
            (SnapshotTestingConfiguration.Traits.darkAccessibility, "dark_accessibility")
        ]
        
        for (traits, suffix) in configurations {
            assertSnapshot(
                matching: view,
                as: .image(on: device, traits: traits),
                named: name.map { "\($0)_\(suffix)" } ?? suffix,
                file: file,
                testName: testName,
                line: line
            )
        }
        
        isRecording = previousRecordingState
    }
}

// MARK: - Custom Snapshot Strategies

extension Snapshotting where Value == SwiftUI.AnyView, Format == UIImage {
    
    /// Snapshot with a specific color scheme
    static func image(
        colorScheme: ColorScheme,
        on config: ViewImageConfig = .iPhone13
    ) -> Snapshotting {
        var traits = config.traits ?? UITraitCollection()
        traits = UITraitCollection(traitsFrom: [
            traits,
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        ])
        
        return .image(
            on: ViewImageConfig(
                safeArea: config.safeArea,
                size: config.size,
                traits: traits
            )
        )
    }
}

// MARK: - Test Data Helpers

extension SnapshotTestCase {
    
    /// Create a preview container for consistent snapshot styling
    func previewContainer<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                Divider()
            }
            
            content()
        }
        .background(Color(.systemBackground))
    }
}