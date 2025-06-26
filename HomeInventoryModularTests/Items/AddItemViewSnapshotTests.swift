//
//  AddItemViewSnapshotTests.swift
//  HomeInventoryModular
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, Items, Core
//  Testing: N/A (This is a test file)
//
//  Description: Snapshot tests for AddItemView UI consistency and visual regression testing
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class AddItemViewSnapshotTests: SnapshotTestCase {
    
    func testAddItemView_Empty() {
        let view = NavigationStack {
            AddItemView(isPresented: .constant(true))
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testAddItemView_Filled() {
        // Since we can't easily pre-fill the form, we'll test individual sections
        let formSection = Form {
            Section("Basic Information") {
                TextField("Item Name", text: .constant("iPhone 15 Pro"))
                TextField("Description", text: .constant("256GB Space Black"), axis: .vertical)
                Picker("Category", selection: .constant(ItemCategory.electronics)) {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
            }
            
            Section("Purchase Details") {
                DatePicker("Purchase Date", selection: .constant(Date()))
                TextField("Purchase Price", text: .constant("$1,199.00"))
                TextField("Store", text: .constant("Apple Store"))
            }
        }
        .frame(height: 400)
        
        assertSnapshot(matching: formSection, as: .image(on: .iPhone16ProMax))
    }
    
    func testAddItemView_DarkMode() {
        let view = NavigationStack {
            AddItemView(isPresented: .constant(true))
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testAddItemView_iPad() {
        let view = NavigationStack {
            AddItemView(isPresented: .constant(true))
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
}