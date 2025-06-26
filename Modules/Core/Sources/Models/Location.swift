//
//  Location.swift
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
//  Testing: Modules/Core/Tests/CoreTests/LocationTests.swift
//
//  Description: Location model for organizing and tracking where items are stored within homes
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Location model for organizing where items are stored
public struct Location: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var parentId: UUID?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "location",
        parentId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.parentId = parentId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Full path including parent locations
    public func fullPath(with allLocations: [Location]) -> String {
        var path = [name]
        var currentParentId = parentId
        
        while let parentId = currentParentId {
            if let parent = allLocations.first(where: { $0.id == parentId }) {
                path.insert(parent.name, at: 0)
                currentParentId = parent.parentId
            } else {
                break
            }
        }
        
        return path.joined(separator: " > ")
    }
}

// MARK: - Preview Data
public extension Location {
    static let preview = Location(name: "Home", icon: "house")
    
    static let previews: [Location] = [
        Location(id: UUID(), name: "Home", icon: "house"),
        Location(id: UUID(), name: "Living Room", icon: "sofa", parentId: UUID()),
        Location(id: UUID(), name: "Bedroom", icon: "bed.double", parentId: UUID()),
        Location(id: UUID(), name: "Kitchen", icon: "refrigerator", parentId: UUID()),
        Location(id: UUID(), name: "Garage", icon: "car.fill", parentId: UUID()),
        Location(id: UUID(), name: "Office", icon: "desktopcomputer", parentId: UUID())
    ]
}