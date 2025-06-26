//
//  CategoryRepository.swift
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
//  Testing: Modules/Core/Tests/CoreTests/CategoryRepositoryTests.swift
//
//  Description: Repository protocol for managing category data persistence and operations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Repository protocol for managing categories
/// Swift 5.9 - No Swift 6 features
public protocol CategoryRepository: Repository where Entity == ItemCategoryModel {
    func fetchBuiltIn() async throws -> [ItemCategoryModel]
    func fetchCustom() async throws -> [ItemCategoryModel]
    func fetchByParent(id: UUID?) async throws -> [ItemCategoryModel]
    func canDelete(_ category: ItemCategoryModel) async throws -> Bool
}

/// Default implementation of CategoryRepository
public final class DefaultCategoryRepository: CategoryRepository {
    private let storage: any Storage<ItemCategoryModel>
    private let itemRepository: any ItemRepository
    
    public init(storage: any Storage<ItemCategoryModel>, itemRepository: any ItemRepository) {
        self.storage = storage
        self.itemRepository = itemRepository
    }
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [ItemCategoryModel] {
        return try await storage.fetchAll()
    }
    
    public func fetch(id: UUID) async throws -> ItemCategoryModel? {
        return try await storage.fetch(id: id)
    }
    
    public func save(_ entity: ItemCategoryModel) async throws {
        try await storage.save(entity)
    }
    
    public func saveAll(_ entities: [ItemCategoryModel]) async throws {
        try await storage.saveAll(entities)
    }
    
    public func delete(_ entity: ItemCategoryModel) async throws {
        // Check if category can be deleted
        let canDelete = try await canDelete(entity)
        guard canDelete else {
            throw CategoryError.cannotDeleteCategoryInUse
        }
        
        try await storage.delete(entity)
    }
    
    public func delete(id: UUID) async throws {
        if let entity = try await fetch(id: id) {
            try await delete(entity)
        }
    }
    
    public func search(query: String) async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { category in
            category.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - CategoryRepository Protocol
    
    public func fetchBuiltIn() async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { $0.isBuiltIn }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public func fetchCustom() async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { !$0.isBuiltIn }.sorted { $0.name < $1.name }
    }
    
    public func fetchByParent(id: UUID?) async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { $0.parentId == id }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public func canDelete(_ category: ItemCategoryModel) async throws -> Bool {
        // Cannot delete built-in categories
        if category.isBuiltIn {
            return false
        }
        
        // Check if any items use this category
        let items = try await itemRepository.fetchAll()
        let hasItems = items.contains { $0.categoryId == category.id }
        
        // Check if any subcategories exist
        let subcategories = try await fetchByParent(id: category.id)
        let hasSubcategories = !subcategories.isEmpty
        
        return !hasItems && !hasSubcategories
    }
}

// MARK: - Errors
public enum CategoryError: LocalizedError {
    case cannotDeleteBuiltInCategory
    case cannotDeleteCategoryInUse
    case invalidParentCategory
    
    public var errorDescription: String? {
        switch self {
        case .cannotDeleteBuiltInCategory:
            return "Built-in categories cannot be deleted"
        case .cannotDeleteCategoryInUse:
            return "Cannot delete category that contains items or subcategories"
        case .invalidParentCategory:
            return "Invalid parent category"
        }
    }
}

// MARK: - Category Storage Initializer
public extension DefaultCategoryRepository {
    /// Initialize storage with built-in categories if needed
    static func initializeWithBuiltInCategories(storage: any Storage<ItemCategoryModel>) async throws {
        let existing = try await storage.fetchAll()
        
        // Only add built-in categories if storage is empty
        if existing.isEmpty {
            for category in ItemCategoryModel.builtInCategories {
                try await storage.save(category)
            }
        }
    }
}