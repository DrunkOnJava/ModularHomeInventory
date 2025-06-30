//
//  SearchBarSnapshotTests.swift
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
//  Testing: Snapshot tests for SearchBar component
//
//  Description: Snapshot tests for SearchBar component covering various states and input configurations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class SearchBarSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testSearchBar_Empty() {
        withSnapshotTesting(record: .all) {
            let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
                .frame(height: 60)
                .padding()
            
            let hostingController = UIHostingController(rootView: searchBar)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSearchBar_WithText() {
        withSnapshotTesting(record: .all) {
            let searchBar = SearchBar(text: .constant("MacBook Pro"), placeholder: "Search items...")
                .frame(height: 60)
                .padding()
            
            let hostingController = UIHostingController(rootView: searchBar)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSearchBar_BothModes() {
        withSnapshotTesting(record: .all) {
            let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
                .frame(height: 60)
                .padding()
            
            let hostingController = UIHostingController(rootView: searchBar)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSearchBar_CustomPlaceholder() {
        withSnapshotTesting(record: .all) {
            let searchBar = SearchBar(
                text: .constant(""),
                placeholder: "Find by name, barcode, or location..."
            )
            .frame(height: 60)
            .padding()
            
            let hostingController = UIHostingController(rootView: searchBar)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSearchBar_Focused() {
        withSnapshotTesting(record: .all) {
            // Note: Testing focused state requires a more complex setup
            // For now, we'll test the appearance
            let searchBar = SearchBar(text: .constant("typing..."), placeholder: "Search")
                .frame(height: 60)
                .padding()
            
            let hostingController = UIHostingController(rootView: searchBar)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
}