//
//  Storage.swift
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
//  Testing: Modules/Core/Tests/CoreTests/StorageTests.swift
//
//  Description: Generic storage protocol for data persistence with default implementations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Storage protocol for data persistence
/// Swift 5.9 - No Swift 6 features
public protocol Storage<Entity> {
    associatedtype Entity: Identifiable & Codable
    
    /// Fetch all entities
    func fetchAll() async throws -> [Entity]
    
    /// Fetch entity by ID
    func fetch(id: Entity.ID) async throws -> Entity?
    
    /// Save an entity
    func save(_ entity: Entity) async throws
    
    /// Save multiple entities
    func saveAll(_ entities: [Entity]) async throws
    
    /// Delete an entity
    func delete(_ entity: Entity) async throws
    
    /// Delete entity by ID
    func delete(id: Entity.ID) async throws
    
    /// Delete all entities
    func deleteAll() async throws
}

// MARK: - Default implementations
public extension Storage {
    func saveAll(_ entities: [Entity]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: Entity) async throws {
        try await delete(id: entity.id)
    }
}