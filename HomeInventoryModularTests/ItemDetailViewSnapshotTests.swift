//
//  ItemDetailViewSnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, Items, Core, SharedUI
//  Testing: Snapshot tests for ItemDetailView component
//
//  Description: Snapshot tests for ItemDetailView covering various item states and detail configurations
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

final class ItemDetailViewSnapshotTests: SnapshotTestCase {
    
    func testItemDetailView_Complete() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15ProMax))
    }
    
    func testItemDetailView_Minimal() {
        let item = Item.sampleMinimal
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15ProMax))
    }
    
    func testItemDetailView_DarkMode() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone15ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testItemDetailView_iPad() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
    
    func testItemDetailView_AccessibilityLarge() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(
            matching: view,
            as: .image(
                on: .iPhone15ProMax,
                traits: .init(preferredContentSizeCategory: .accessibilityLarge)
            )
        )
    }
}

// Extended sample data
extension Item {
    static var sampleComplete: Item {
        Item(
            id: UUID(),
            name: "Sony A7R V Camera",
            description: "Professional full-frame mirrorless camera with 61MP sensor",
            category: .electronics,
            locationId: UUID(),
            purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
            purchasePrice: 3899.99,
            currency: "USD",
            serialNumber: "SN1234567890",
            modelNumber: "ILCE-7RM5",
            manufacturer: "Sony",
            photos: [
                Photo(id: UUID(), data: Data(), thumbnailData: nil),
                Photo(id: UUID(), data: Data(), thumbnailData: nil),
                Photo(id: UUID(), data: Data(), thumbnailData: nil)
            ],
            tags: ["camera", "photography", "professional", "sony"],
            quantity: 1,
            notes: "Purchased with 2-year warranty. Includes original box and all accessories.",
            warranty: Warranty(
                id: UUID(),
                itemId: UUID(),
                provider: "Sony",
                startDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(550 * 24 * 60 * 60), // ~1.5 years from now
                type: .manufacturer,
                notes: "Extended warranty purchased"
            ),
            receipt: Receipt(
                id: UUID(),
                itemId: UUID(),
                storeName: "B&H Photo",
                purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                totalAmount: 3899.99,
                taxAmount: 312.00,
                currency: "USD"
            ),
            createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60),
            updatedAt: Date()
        )
    }
    
    static var sampleMinimal: Item {
        Item(
            id: UUID(),
            name: "Coffee Maker",
            description: nil,
            category: .appliances,
            locationId: UUID(),
            purchaseDate: nil,
            purchasePrice: nil,
            currency: "USD",
            serialNumber: nil,
            modelNumber: nil,
            manufacturer: nil,
            photos: [],
            tags: [],
            quantity: 1,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}