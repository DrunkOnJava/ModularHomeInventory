//
//  DefaultCollectionRepository.swift
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
//  Testing: Default in-memory implementation for development and testing
//
//  Description: Default in-memory implementation of CollectionRepository providing collection
//  management capabilities including item addition/removal, archival operations, and
//  collection status tracking. Handles repository error cases and maintains collection state.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Default in-memory implementation of CollectionRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultCollectionRepository: CollectionRepository {
    private var collections: [Collection] = []
    
    public init() {}
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [Collection] {
        collections
    }
    
    public func fetch(id: UUID) async throws -> Collection? {
        collections.first { $0.id == id }
    }
    
    public func save(_ entity: Collection) async throws {
        if let index = collections.firstIndex(where: { $0.id == entity.id }) {
            var updated = entity
            updated.updatedAt = Date()
            collections[index] = updated
        } else {
            collections.append(entity)
        }
    }
    
    public func saveAll(_ entities: [Collection]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: Collection) async throws {
        collections.removeAll { $0.id == entity.id }
    }
    
    public func delete(id: UUID) async throws {
        collections.removeAll { $0.id == id }
    }
    
    // MARK: - CollectionRepository Protocol
    
    public func fetchByItemId(_ itemId: UUID) async throws -> [Collection] {
        collections.filter { $0.itemIds.contains(itemId) }
    }
    
    public func addItem(_ itemId: UUID, to collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        var collection = collections[index]
        if !collection.itemIds.contains(itemId) {
            collection.itemIds.append(itemId)
            collection.updatedAt = Date()
            collections[index] = collection
        }
    }
    
    public func removeItem(_ itemId: UUID, from collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        var collection = collections[index]
        collection.itemIds.removeAll { $0 == itemId }
        collection.updatedAt = Date()
        collections[index] = collection
    }
    
    public func fetchActive() async throws -> [Collection] {
        collections.filter { !$0.isArchived }
    }
    
    public func fetchArchived() async throws -> [Collection] {
        collections.filter { $0.isArchived }
    }
    
    public func archive(_ collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        collections[index].isArchived = true
        collections[index].updatedAt = Date()
    }
    
    public func unarchive(_ collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        collections[index].isArchived = false
        collections[index].updatedAt = Date()
    }
}

enum RepositoryError: LocalizedError {
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found"
        }
    }
}