//
//  LoadingOverlaySnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, SharedUI
//  Testing: Snapshot tests for LoadingOverlay component
//
//  Description: Snapshot tests for LoadingOverlay component covering various loading states and message configurations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class LoadingOverlaySnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testLoadingOverlay_Default() {
        withSnapshotTesting(record: .all) {
            let view = Color.gray.opacity(0.1)
                .frame(width: 300, height: 200)
                .overlay(
                    LoadingOverlay()
                )
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testLoadingOverlay_WithMessage() {
        withSnapshotTesting(record: .all) {
            let view = Color.gray.opacity(0.1)
                .frame(width: 300, height: 200)
                .overlay(
                    LoadingOverlay(message: "Scanning barcode...")
                )
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testLoadingOverlay_LongMessage() {
        withSnapshotTesting(record: .all) {
            let view = Color.gray.opacity(0.1)
                .frame(width: 300, height: 200)
                .overlay(
                    LoadingOverlay(message: "This is a very long loading message that might wrap to multiple lines")
                )
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testLoadingOverlay_BothModes() {
        withSnapshotTesting(record: .all) {
            let view = Color.gray.opacity(0.1)
                .frame(width: 300, height: 200)
                .overlay(
                    LoadingOverlay(message: "Loading...")
                )
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
}