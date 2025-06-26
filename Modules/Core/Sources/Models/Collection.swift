//
//  Collection.swift
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
//  Testing: Modules/Core/Tests/CoreTests/CollectionTests.swift
//
//  Description: Collection model for grouping related items together with metadata
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// A collection groups related items together
/// Swift 5.9 - No Swift 6 features
public struct Collection: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var icon: String
    public var color: String
    public var itemIds: [UUID]
    public var isArchived: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        icon: String = "folder",
        color: String = "blue",
        itemIds: [UUID] = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.itemIds = itemIds
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Collection {
    static let preview = Collection(
        name: "Summer Vacation Gear",
        description: "Everything needed for beach trips",
        icon: "sun.max",
        color: "orange",
        itemIds: []
    )
    
    static let previews: [Collection] = [
        preview,
        Collection(
            name: "Home Office Setup",
            description: "Work from home equipment",
            icon: "desktopcomputer",
            color: "purple",
            itemIds: []
        ),
        Collection(
            name: "Emergency Kit",
            description: "Essential items for emergencies",
            icon: "cross.case",
            color: "red",
            itemIds: []
        ),
        Collection(
            name: "Travel Essentials",
            description: "Must-have items for trips",
            icon: "airplane",
            color: "blue",
            itemIds: []
        )
    ]
}