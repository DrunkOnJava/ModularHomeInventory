//
//  ItemRowSnapshotTests.swift
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
//  Module: SharedUI
//  Dependencies: XCTest, SnapshotTesting, SwiftUI
//  Testing: Snapshot tests for SharedUI ItemRow component
//
//  Description: Snapshot tests for ItemRow component using SnapshotTesting framework
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core

final class ItemRowSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Uncomment to record new snapshots
        // isRecording = true
    }
    
    // MARK: - Basic Tests
    
    func testItemRow_default() {
        let item = Item(
            name: "MacBook Pro",
            category: .electronics,
            purchasePrice: 2499.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_withWarranty() {
        var item = Item(
            name: "Coffee Maker",
            category: .appliances,
            purchasePrice: 149.99,
            brand: "Breville"
        )
        item.warrantyExpiration = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_multiplePhotos() {
        var item = Item(
            name: "Gaming Console",
            category: .electronics,
            purchasePrice: 499.99,
            brand: "Sony"
        )
        item.photos = [
            ItemPhoto(data: Data(), isMainPhoto: true),
            ItemPhoto(data: Data(), isMainPhoto: false),
            ItemPhoto(data: Data(), isMainPhoto: false)
        ]
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Dark Mode Tests
    
    func testItemRow_darkMode() {
        let item = Item(
            name: "iPhone 15 Pro",
            category: .electronics,
            purchasePrice: 999.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
            .environment(\.colorScheme, .dark)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Accessibility Tests
    
    func testItemRow_largeText() {
        let item = Item(
            name: "Desk Lamp with Adjustable Brightness",
            category: .furniture,
            purchasePrice: 89.99,
            brand: "IKEA"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
            .environment(\.sizeCategory, .accessibilityLarge)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Edge Cases
    
    func testItemRow_longName() {
        let item = Item(
            name: "Ultra-Wide 49-inch Curved Gaming Monitor with HDR1000 and 240Hz Refresh Rate",
            category: .electronics,
            purchasePrice: 1299.99,
            brand: "Samsung"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_noPrice() {
        let item = Item(
            name: "Gift Item",
            category: .other,
            purchasePrice: nil,
            brand: nil
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Device Specific Tests
    
    func testItemRow_iPhone() {
        let item = Item(
            name: "AirPods Pro",
            category: .electronics,
            purchasePrice: 249.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
        
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(config: .iPhone13))
        )
    }
    
    func testItemRow_iPad() {
        let item = Item(
            name: "Smart Home Hub",
            category: .electronics,
            purchasePrice: 199.99,
            brand: "Google"
        )
        
        let view = ItemRow(item: item) {}
        
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(config: .iPadPro11))
        )
    }
}