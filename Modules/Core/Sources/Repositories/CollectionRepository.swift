//
//  CollectionRepository.swift
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
//  Testing: Modules/Core/Tests/CoreTests/CollectionRepositoryTests.swift
//
//  Description: Repository protocol for managing item collections, supporting collection
//  creation, item management, archival operations, and relationship tracking between
//  items and collections within the inventory system.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Repository for managing collections
/// Swift 5.9 - No Swift 6 features
public protocol CollectionRepository: Repository where Entity == Collection {
    /// Fetch collections containing a specific item
    func fetchByItemId(_ itemId: UUID) async throws -> [Collection]
    
    /// Add an item to a collection
    func addItem(_ itemId: UUID, to collectionId: UUID) async throws
    
    /// Remove an item from a collection
    func removeItem(_ itemId: UUID, from collectionId: UUID) async throws
    
    /// Fetch active (non-archived) collections
    func fetchActive() async throws -> [Collection]
    
    /// Fetch archived collections
    func fetchArchived() async throws -> [Collection]
    
    /// Archive a collection
    func archive(_ collectionId: UUID) async throws
    
    /// Unarchive a collection
    func unarchive(_ collectionId: UUID) async throws
}