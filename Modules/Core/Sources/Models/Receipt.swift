//
//  Receipt.swift
//  Core
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
//  Module: Core
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/ReceiptTests.swift
//
//  Description: Receipt domain model for purchase tracking and warranty management
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Receipt domain model
/// Swift 5.9 - No Swift 6 features
public struct Receipt: Identifiable, Codable, Equatable {
    public let id: UUID
    public var storeName: String
    public var date: Date
    public var totalAmount: Decimal
    public var itemIds: [UUID]
    public var imageData: Data?
    public var rawText: String?
    public var confidence: Double
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        storeName: String,
        date: Date,
        totalAmount: Decimal,
        itemIds: [UUID] = [],
        imageData: Data? = nil,
        rawText: String? = nil,
        confidence: Double = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.itemIds = itemIds
        self.imageData = imageData
        self.rawText = rawText
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sample Data
public extension Receipt {
    static let preview = Receipt(
        storeName: "Whole Foods Market",
        date: Date().addingTimeInterval(-86400), // Yesterday
        totalAmount: 157.42,
        itemIds: [UUID(), UUID(), UUID()],
        confidence: 0.95
    )
    
    static let previews: [Receipt] = [
        Receipt(
            storeName: "Whole Foods Market",
            date: Date().addingTimeInterval(-86400),
            totalAmount: 157.42,
            itemIds: [UUID(), UUID(), UUID()],
            confidence: 0.95
        ),
        Receipt(
            storeName: "Target",
            date: Date().addingTimeInterval(-172800),
            totalAmount: 89.99,
            itemIds: [UUID(), UUID()],
            confidence: 0.88
        ),
        Receipt(
            storeName: "Home Depot",
            date: Date().addingTimeInterval(-259200),
            totalAmount: 234.56,
            itemIds: [UUID(), UUID(), UUID(), UUID()],
            confidence: 0.92
        )
    ]
}