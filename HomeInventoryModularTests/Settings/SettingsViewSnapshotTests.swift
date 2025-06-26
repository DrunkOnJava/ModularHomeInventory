//
//  SettingsViewSnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, AppSettings, Core, SharedUI
//  Testing: Snapshot tests for Settings views
//
//  Description: Snapshot tests for Settings module views covering configuration screens and preferences
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import AppSettings
@testable import Core
@testable import SharedUI

final class SettingsViewSnapshotTests: SnapshotTestCase {
    
    func testSettingsView_Main() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testSettingsView_DarkMode() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testSettingsView_iPad() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
    
    func testSettingsSection_Scanner() {
        let section = List {
            Section("Scanner Settings") {
                Toggle("Sound Effects", isOn: .constant(true))
                Toggle("Haptic Feedback", isOn: .constant(true))
                Toggle("Auto-Save Scans", isOn: .constant(false))
                Toggle("Flash Light", isOn: .constant(false))
            }
        }
        .frame(height: 250)
        
        assertSnapshot(matching: section, as: .image(on: .iPhone16ProMax))
    }
    
    func testSettingsSection_Notifications() {
        let section = List {
            Section("Notifications") {
                Toggle("Warranty Expiration", isOn: .constant(true))
                Toggle("Service Reminders", isOn: .constant(true))
                Toggle("Price Alerts", isOn: .constant(false))
                HStack {
                    Text("Reminder Time")
                    Spacer()
                    Text("30 days before")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 250)
        
        assertSnapshot(matching: section, as: .image(on: .iPhone16ProMax))
    }
    
    func testAboutView() {
        let view = NavigationStack {
            AboutView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
}