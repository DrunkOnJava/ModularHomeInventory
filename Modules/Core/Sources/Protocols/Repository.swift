//
//  Repository.swift
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
//  Testing: Modules/Core/Tests/CoreTests/RepositoryTests.swift
//
//  Description: Base repository protocol for data access with specialized protocols for Items and Locations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Base repository protocol for data access
public protocol Repository {
    associatedtype Entity: Identifiable
    
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
}

/// Item-specific repository protocol
public protocol ItemRepository: Repository where Entity == Item {
    /// Search items by query
    func search(query: String) async throws -> [Item]
    
    /// Search items with fuzzy matching
    func fuzzySearch(query: String, threshold: Double) async throws -> [Item]
    
    /// Search items with advanced criteria
    func searchWithCriteria(_ criteria: ItemSearchCriteria) async throws -> [Item]
    
    /// Fetch items by category
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item]
    
    /// Fetch items by category ID
    func fetchByCategoryId(_ categoryId: UUID) async throws -> [Item]
    
    /// Fetch items by location
    func fetchByLocation(_ locationId: UUID) async throws -> [Item]
    
    /// Fetch items by barcode
    func fetchByBarcode(_ barcode: String) async throws -> Item?
    
    /// Fetch items under warranty
    func fetchItemsUnderWarranty() async throws -> [Item]
    
    /// Fetch favorite items
    func fetchFavoriteItems() async throws -> [Item]
    
    /// Fetch recently added items
    func fetchRecentlyAdded(days: Int) async throws -> [Item]
}

/// Location-specific repository protocol  
public protocol LocationRepository: Repository where Entity == Location {
    /// Fetch root locations (no parent)
    func fetchRootLocations() async throws -> [Location]
    
    /// Fetch child locations
    func fetchChildren(of parentId: UUID) async throws -> [Location]
    
    /// Fetch all locations
    func getAllLocations() async throws -> [Location]
}

// MARK: - Default Implementations
public extension LocationRepository {
    func getAllLocations() async throws -> [Location] {
        try await fetchAll()
    }
}

public extension ItemRepository {
    /// Create a new item (alias for save)
    func createItem(_ item: Item) async throws {
        try await save(item)
    }
}