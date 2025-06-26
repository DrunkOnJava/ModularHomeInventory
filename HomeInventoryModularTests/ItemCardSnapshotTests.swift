//
//  ItemCardSnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, SharedUI, Core
//  Testing: Snapshot tests for ItemCard component
//
//  Description: Snapshot tests for ItemCard component covering various states and configurations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core

final class ItemCardSnapshotTests: SnapshotTestCase {
    
    func testItemCard_Standard() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_DarkMode() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone15, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testItemCard_NoPhoto() {
        var item = Item.sample
        item.photos = []
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_LongName() {
        var item = Item.sample
        item.name = "This is a very long item name that should wrap to multiple lines and test the layout"
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_HighValue() {
        var item = Item.sample
        item.purchasePrice = 9999.99
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_iPad() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 450)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
}

// Helper extension for sample data
extension Item {
    static var sample: Item {
        Item(
            id: UUID(),
            name: "MacBook Pro 16\"",
            description: "2023 M3 Max MacBook Pro",
            category: .electronics,
            locationId: UUID(),
            purchaseDate: Date(),
            purchasePrice: 3499.99,
            currency: "USD",
            serialNumber: "C02XK2JKML87",
            modelNumber: "MRW33LL/A",
            manufacturer: "Apple",
            photos: [Photo(id: UUID(), data: Data(), thumbnailData: nil)],
            tags: ["laptop", "work", "apple"],
            quantity: 1,
            notes: "Primary work computer",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Define iPhone 15 device for consistency
extension ViewImageConfig {
    static let iPhone15 = ViewImageConfig.iPhone13
    static let iPhone15Pro = ViewImageConfig.iPhone13Pro
    static let iPhone15ProMax = ViewImageConfig.iPhone13ProMax
}