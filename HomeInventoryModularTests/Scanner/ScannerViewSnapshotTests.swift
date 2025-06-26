//
//  ScannerViewSnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, BarcodeScanner, Core, SharedUI
//  Testing: Snapshot tests for Scanner views
//
//  Description: Snapshot tests for BarcodeScanner module views covering scanning interface and history
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import BarcodeScanner
@testable import Core
@testable import SharedUI

final class ScannerViewSnapshotTests: SnapshotTestCase {
    
    func testScannerTabView() {
        let view = NavigationStack {
            ScannerTabView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScanHistoryView_Empty() {
        let view = NavigationStack {
            ScanHistoryView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScanHistoryView_WithItems() {
        // Mock scan history items
        let historyList = List {
            Section("Today") {
                ScanHistoryRow(
                    barcode: "0123456789012",
                    timestamp: Date(),
                    itemName: "iPhone 15 Pro"
                )
                ScanHistoryRow(
                    barcode: "9876543210987",
                    timestamp: Date().addingTimeInterval(-3600),
                    itemName: "MacBook Air"
                )
            }
            
            Section("Yesterday") {
                ScanHistoryRow(
                    barcode: "1234567890123",
                    timestamp: Date().addingTimeInterval(-86400),
                    itemName: "AirPods Pro"
                )
            }
        }
        .frame(height: 400)
        
        assertSnapshot(matching: historyList, as: .image(on: .iPhone16ProMax))
    }
    
    func testOfflineScanQueueView() {
        let view = NavigationStack {
            OfflineScanQueueView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScannerView_DarkMode() {
        let view = NavigationStack {
            ScannerTabView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
}

// Helper view for scan history row
struct ScanHistoryRow: View {
    let barcode: String
    let timestamp: Date
    let itemName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(itemName ?? "Unknown Item")
                    .font(.headline)
                Spacer()
                Text(timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(barcode)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}