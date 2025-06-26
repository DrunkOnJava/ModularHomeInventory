//
//  Tag.swift
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
//  Module: Core
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/TagTests.swift
//
//  Description: Tag model for flexible item labeling and organization system
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Represents a tag that can be applied to items
/// Swift 5.9 - No Swift 6 features
public struct Tag: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var color: String
    public var icon: String?
    public var itemCount: Int
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = "blue",
        icon: String? = nil,
        itemCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.itemCount = itemCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Tag {
    static let previews: [Tag] = [
        Tag(name: "Electronics", color: "blue", icon: "tv", itemCount: 15),
        Tag(name: "Vintage", color: "brown", icon: "clock", itemCount: 8),
        Tag(name: "Gift", color: "pink", icon: "gift", itemCount: 12),
        Tag(name: "Work", color: "purple", icon: "briefcase", itemCount: 24),
        Tag(name: "Travel", color: "orange", icon: "airplane", itemCount: 6),
        Tag(name: "Outdoor", color: "green", icon: "leaf", itemCount: 10),
        Tag(name: "Kitchen", color: "red", icon: "fork.knife", itemCount: 18),
        Tag(name: "Gaming", color: "indigo", icon: "gamecontroller", itemCount: 9)
    ]
}