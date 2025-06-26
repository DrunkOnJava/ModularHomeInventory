//
//  InMemoryCategoryRepository.swift
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
//  Testing: In-memory mock repository for testing and development
//
//  Description: In-memory implementation of CategoryRepository providing thread-safe category
//  management with built-in categories and concurrent access support. Used for testing,
//  development, and as a default implementation when persistent storage is not available.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// In-memory implementation of CategoryRepository for testing and defaults
/// Swift 5.9 - No Swift 6 features
public final class InMemoryCategoryRepository: CategoryRepository {
    private var categories: [ItemCategoryModel] = []
    private let queue = DispatchQueue(label: "InMemoryCategoryRepository", attributes: .concurrent)
    
    public init() {
        // Initialize with built-in categories
        self.categories = Self.createBuiltInCategories()
    }
    
    private static func createBuiltInCategories() -> [ItemCategoryModel] {
        let now = Date()
        return [
            ItemCategoryModel(
                name: "Electronics",
                icon: "laptopcomputer",
                color: "#4ECDC4",
                isBuiltIn: true,
                parentId: nil,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now
            ),
            ItemCategoryModel(
                name: "Clothing",
                icon: "tshirt",
                color: "#FF6B6B",
                isBuiltIn: true,
                parentId: nil,
                sortOrder: 1,
                createdAt: now,
                updatedAt: now
            ),
            ItemCategoryModel(
                name: "Home & Garden",
                icon: "house",
                color: "#95E1D3",
                isBuiltIn: true,
                parentId: nil,
                sortOrder: 2,
                createdAt: now,
                updatedAt: now
            ),
            ItemCategoryModel(
                name: "Sports & Outdoors",
                icon: "sportscourt",
                color: "#FECA57",
                isBuiltIn: true,
                parentId: nil,
                sortOrder: 3,
                createdAt: now,
                updatedAt: now
            ),
            ItemCategoryModel(
                name: "Tools",
                icon: "wrench",
                color: "#A8E6CF",
                isBuiltIn: true,
                parentId: nil,
                sortOrder: 4,
                createdAt: now,
                updatedAt: now
            )
        ]
    }
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [ItemCategoryModel] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.categories)
            }
        }
    }
    
    public func fetch(id: UUID) async throws -> ItemCategoryModel? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let category = self.categories.first { $0.id == id }
                continuation.resume(returning: category)
            }
        }
    }
    
    public func save(_ entity: ItemCategoryModel) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.categories.firstIndex(where: { $0.id == entity.id }) {
                    self.categories[index] = entity
                } else {
                    self.categories.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    public func saveAll(_ entities: [ItemCategoryModel]) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                for entity in entities {
                    if let index = self.categories.firstIndex(where: { $0.id == entity.id }) {
                        self.categories[index] = entity
                    } else {
                        self.categories.append(entity)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    public func delete(_ entity: ItemCategoryModel) async throws {
        try await delete(id: entity.id)
    }
    
    public func delete(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.categories.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    public func search(query: String) async throws -> [ItemCategoryModel] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.categories.filter { category in
                    category.name.localizedCaseInsensitiveContains(query)
                }
                continuation.resume(returning: results)
            }
        }
    }
    
    // MARK: - CategoryRepository Protocol
    
    public func fetchBuiltIn() async throws -> [ItemCategoryModel] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let builtIn = self.categories.filter { $0.isBuiltIn }
                continuation.resume(returning: builtIn)
            }
        }
    }
    
    public func fetchCustom() async throws -> [ItemCategoryModel] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let custom = self.categories.filter { !$0.isBuiltIn }
                continuation.resume(returning: custom)
            }
        }
    }
    
    public func fetchByParent(id: UUID?) async throws -> [ItemCategoryModel] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.categories.filter { $0.parentId == id }
                continuation.resume(returning: results)
            }
        }
    }
    
    public func canDelete(_ category: ItemCategoryModel) async throws -> Bool {
        // Built-in categories cannot be deleted
        return !category.isBuiltIn
    }
}