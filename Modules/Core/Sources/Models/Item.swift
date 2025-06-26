//
//  Item.swift
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
//  Testing: CoreTests/ItemTests.swift
//
//  Description: Core Item model representing an inventory item
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Core Item model representing an inventory item
public struct Item: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var brand: String?
    public var model: String?
    public var category: ItemCategory // Deprecated - use categoryId
    public var categoryId: UUID
    public var condition: ItemCondition
    public var quantity: Int
    public var value: Decimal?
    public var purchasePrice: Decimal?
    public var purchaseDate: Date?
    public var notes: String?
    public var barcode: String?
    public var serialNumber: String?
    public var tags: [String]
    public var imageIds: [UUID]
    public var locationId: UUID?
    public var storageUnitId: UUID?
    public var warrantyId: UUID?
    public var storeName: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        model: String? = nil,
        category: ItemCategory = .other,
        categoryId: UUID? = nil,
        condition: ItemCondition = .good,
        quantity: Int = 1,
        value: Decimal? = nil,
        purchasePrice: Decimal? = nil,
        purchaseDate: Date? = nil,
        notes: String? = nil,
        barcode: String? = nil,
        serialNumber: String? = nil,
        tags: [String] = [],
        imageIds: [UUID] = [],
        locationId: UUID? = nil,
        storageUnitId: UUID? = nil,
        warrantyId: UUID? = nil,
        storeName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.category = category
        self.categoryId = categoryId ?? ItemCategoryModel.fromItemCategory(category)
        self.condition = condition
        self.quantity = quantity
        self.value = value
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.barcode = barcode
        self.serialNumber = serialNumber
        self.tags = tags
        self.imageIds = imageIds
        self.locationId = locationId
        self.storageUnitId = storageUnitId
        self.warrantyId = warrantyId
        self.storeName = storeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Item {
    static let preview = Item(
        name: "iPhone 15 Pro",
        brand: "Apple",
        model: "A3102",
        category: .electronics,
        condition: .excellent,
        value: 999.00,
        purchasePrice: 999.00,
        purchaseDate: Date(),
        notes: "256GB Space Black",
        tags: ["phone", "work"],
        storeName: "Apple Store"
    )
    
    static let previews: [Item] = [
        // Electronics
        preview,
        Item(
            name: "MacBook Pro 16\"",
            brand: "Apple",
            model: "M3 Max",
            category: .electronics,
            condition: .excellent,
            value: 3499.00,
            purchasePrice: 3499.00,
            purchaseDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
            notes: "1TB SSD, 36GB RAM, Space Gray",
            barcode: "194253082194",
            serialNumber: "C02XG2JMQ05Q",
            tags: ["laptop", "work", "apple", "computer"],
            storeName: "Apple Store"
        ),
        Item(
            name: "Sony A7R V Camera",
            brand: "Sony",
            model: "ILCE-7RM5",
            category: .electronics,
            condition: .excellent,
            value: 3899.00,
            purchasePrice: 3899.00,
            purchaseDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
            notes: "61MP Full-frame mirrorless camera",
            barcode: "027242923942",
            serialNumber: "5012345",
            tags: ["camera", "photography", "professional"],
            storeName: "B&H Photo"
        ),
        Item(
            name: "iPad Pro 12.9\"",
            brand: "Apple",
            model: "A2764",
            category: .electronics,
            condition: .good,
            value: 1099.00,
            purchasePrice: 1299.00,
            purchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            notes: "512GB WiFi + Cellular, with Magic Keyboard",
            barcode: "194253378457",
            serialNumber: "DLXVG9FKQ1GC",
            tags: ["tablet", "apple", "mobile"],
            storeName: "Best Buy"
        ),
        Item(
            name: "LG OLED TV 65\"",
            brand: "LG",
            model: "OLED65C3PUA",
            category: .electronics,
            condition: .excellent,
            value: 1799.00,
            purchasePrice: 2199.00,
            purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
            notes: "4K OLED Smart TV",
            barcode: "719192642669",
            tags: ["tv", "entertainment", "smart-home"],
            storeName: "Costco"
        ),
        Item(
            name: "PlayStation 5",
            brand: "Sony",
            model: "CFI-1215A",
            category: .electronics,
            condition: .good,
            value: 499.00,
            purchasePrice: 499.00,
            purchaseDate: Date().addingTimeInterval(-300 * 24 * 60 * 60),
            notes: "Disc version with extra controller",
            barcode: "711719541486",
            tags: ["gaming", "console", "entertainment"],
            storeName: "GameStop"
        ),
        
        // Furniture
        Item(
            name: "Office Chair",
            brand: "Herman Miller",
            model: "Aeron",
            category: .furniture,
            condition: .good,
            value: 1200.00,
            purchasePrice: 1200.00,
            purchaseDate: Date().addingTimeInterval(-400 * 24 * 60 * 60),
            notes: "Ergonomic office chair, black",
            tags: ["office", "furniture", "ergonomic"],
            storeName: "Herman Miller Store"
        ),
        Item(
            name: "Standing Desk",
            brand: "Uplift Desk",
            model: "V2 Commercial",
            category: .furniture,
            condition: .good,
            value: 899.00,
            purchasePrice: 899.00,
            purchaseDate: Date().addingTimeInterval(-380 * 24 * 60 * 60),
            notes: "72x30 bamboo top, memory settings",
            tags: ["desk", "office", "adjustable"],
            storeName: "Uplift Desk"
        ),
        Item(
            name: "Leather Sofa",
            brand: "West Elm",
            model: "Hamilton",
            category: .furniture,
            condition: .good,
            value: 2499.00,
            purchasePrice: 2999.00,
            purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
            notes: "3-seat sofa, cognac leather",
            tags: ["sofa", "living-room", "leather"],
            storeName: "West Elm"
        ),
        
        // Appliances
        Item(
            name: "Espresso Machine",
            brand: "Breville",
            model: "Barista Express",
            category: .appliances,
            condition: .excellent,
            value: 699.00,
            purchasePrice: 699.00,
            purchaseDate: Date().addingTimeInterval(-120 * 24 * 60 * 60),
            notes: "Stainless steel, built-in grinder",
            barcode: "021614062130",
            serialNumber: "BE870XL/A",
            tags: ["coffee", "kitchen", "appliance"],
            storeName: "Williams Sonoma"
        ),
        Item(
            name: "Robot Vacuum",
            brand: "iRobot",
            model: "Roomba j7+",
            category: .appliances,
            condition: .good,
            value: 599.00,
            purchasePrice: 799.00,
            purchaseDate: Date().addingTimeInterval(-200 * 24 * 60 * 60),
            notes: "Self-emptying, obstacle avoidance",
            barcode: "885155025517",
            tags: ["cleaning", "smart-home", "robot"],
            storeName: "Amazon"
        ),
        Item(
            name: "KitchenAid Mixer",
            brand: "KitchenAid",
            model: "Professional 600",
            category: .appliances,
            condition: .excellent,
            value: 449.00,
            purchasePrice: 449.00,
            purchaseDate: Date().addingTimeInterval(-500 * 24 * 60 * 60),
            notes: "6-quart, Empire Red",
            barcode: "883049118949",
            tags: ["kitchen", "baking", "mixer"],
            storeName: "Sur La Table"
        ),
        
        // Tools
        Item(
            name: "Cordless Drill",
            brand: "DeWalt",
            model: "DCD791D2",
            category: .tools,
            condition: .good,
            value: 179.00,
            purchasePrice: 179.00,
            purchaseDate: Date().addingTimeInterval(-600 * 24 * 60 * 60),
            notes: "20V MAX, 2 batteries included",
            barcode: "885911475129",
            tags: ["power-tools", "drill", "construction"],
            storeName: "Home Depot"
        ),
        Item(
            name: "Socket Set",
            brand: "Craftsman",
            model: "CMMT99206",
            category: .tools,
            condition: .excellent,
            value: 99.00,
            purchasePrice: 99.00,
            purchaseDate: Date().addingTimeInterval(-450 * 24 * 60 * 60),
            notes: "230-piece mechanics tool set",
            barcode: "885911613309",
            tags: ["hand-tools", "mechanics", "repair"],
            storeName: "Lowe's"
        ),
        
        // Clothing
        Item(
            name: "Running Shoes",
            brand: "Nike",
            model: "Air Zoom Pegasus",
            category: .clothing,
            condition: .fair,
            quantity: 1,
            value: 120.00,
            purchasePrice: 130.00,
            purchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            notes: "Size 10.5, Black/White",
            tags: ["sports", "shoes", "running"],
            storeName: "Nike Store"
        ),
        Item(
            name: "Winter Jacket",
            brand: "Patagonia",
            model: "Down Sweater",
            category: .clothing,
            condition: .excellent,
            value: 279.00,
            purchasePrice: 279.00,
            purchaseDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
            notes: "Men's Large, Navy Blue",
            tags: ["jacket", "winter", "outdoor"],
            storeName: "Patagonia"
        ),
        
        // Books
        Item(
            name: "Clean Code",
            brand: "Pearson",
            model: "9780132350884",
            category: .books,
            condition: .good,
            value: 40.00,
            purchasePrice: 50.00,
            notes: "Programming best practices book",
            tags: ["programming", "technical", "education"],
            storeName: "Amazon"
        ),
        
        // Sports Equipment
        Item(
            name: "Mountain Bike",
            brand: "Trek",
            model: "Marlin 8",
            category: .sports,
            condition: .good,
            value: 949.00,
            purchasePrice: 1199.00,
            purchaseDate: Date().addingTimeInterval(-400 * 24 * 60 * 60),
            notes: "29er, Medium frame",
            tags: ["bike", "outdoor", "exercise"],
            storeName: "Trek Store"
        ),
        Item(
            name: "Yoga Mat",
            brand: "Manduka",
            model: "PRO",
            category: .sports,
            condition: .excellent,
            value: 120.00,
            purchasePrice: 120.00,
            notes: "6mm thick, Black",
            tags: ["yoga", "fitness", "exercise"],
            storeName: "REI"
        ),
        
        // Collectibles
        Item(
            name: "Vintage Watch",
            brand: "Omega",
            model: "Speedmaster",
            category: .collectibles,
            condition: .excellent,
            value: 4500.00,
            purchasePrice: 3500.00,
            purchaseDate: Date().addingTimeInterval(-1095 * 24 * 60 * 60),
            notes: "1969 Professional, with box and papers",
            serialNumber: "145.022",
            tags: ["watch", "vintage", "luxury", "investment"],
            storeName: "Chrono24"
        )
    ]
}