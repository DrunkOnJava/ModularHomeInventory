//
//  ReceiptsViewSnapshotTests.swift
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
//  Dependencies: XCTest, SnapshotTesting, SwiftUI, Receipts, Core, SharedUI
//  Testing: Snapshot tests for Receipts views
//
//  Description: Snapshot tests for Receipts module views covering receipt management and display
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Receipts
@testable import Core
@testable import SharedUI

final class ReceiptsViewSnapshotTests: SnapshotTestCase {
    
    func testReceiptsListView_Empty() {
        let view = NavigationStack {
            ReceiptsListView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testReceiptDetailView() {
        let receipt = Receipt.sample
        let view = NavigationStack {
            ReceiptDetailView(receipt: receipt)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testReceiptRow() {
        let receipt = Receipt.sample
        let row = ReceiptRowView(receipt: receipt)
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: row, as: .image)
    }
    
    func testReceiptsListView_DarkMode() {
        let view = NavigationStack {
            ReceiptsListView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testAddReceiptView() {
        let view = NavigationStack {
            AddReceiptView(isPresented: .constant(true))
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
}

// Helper extension
extension Receipt {
    static var sample: Receipt {
        Receipt(
            id: UUID(),
            itemId: UUID(),
            storeName: "Apple Store",
            purchaseDate: Date(),
            totalAmount: 1199.00,
            taxAmount: 95.92,
            currency: "USD",
            receiptNumber: "R123456789",
            paymentMethod: "Credit Card",
            notes: "Extended warranty purchased",
            imageData: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Mock receipt row view
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.storeName)
                    .font(.headline)
                Text(receipt.purchaseDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(receipt.totalAmount, specifier: "%.2f")")
                    .font(.headline)
                Text(receipt.paymentMethod ?? "Cash")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}