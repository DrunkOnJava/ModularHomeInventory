//
//  DefaultTagRepository.swift
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
//  Testing: Default in-memory implementation with concurrent access
//
//  Description: Default in-memory implementation of TagRepository providing thread-safe
//  tag management with search capabilities, usage tracking, and preview data. Supports
//  concurrent operations and maintains tag popularity statistics.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Default in-memory implementation of TagRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultTagRepository: TagRepository {
    private var tags: [Tag] = Tag.previews
    private let queue = DispatchQueue(label: "com.homeinventory.tagrepository", attributes: .concurrent)
    
    public init() {}
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.tags)
            }
        }
    }
    
    public func fetch(id: UUID) async throws -> Tag? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let tag = self.tags.first { $0.id == id }
                continuation.resume(returning: tag)
            }
        }
    }
    
    public func save(_ entity: Tag) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == entity.id }) {
                    self.tags[index] = entity
                } else {
                    self.tags.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    public func saveAll(_ entities: [Tag]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: Tag) async throws {
        try await delete(id: entity.id)
    }
    
    public func delete(id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.tags.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - TagRepository Protocol
    
    public func fetchByItemId(_ itemId: UUID) async throws -> [Tag] {
        // In a real implementation, this would query the relationship
        // For now, return empty array
        return []
    }
    
    public func search(query: String) async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let filtered = self.tags.filter { tag in
                    tag.name.localizedCaseInsensitiveContains(query)
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    public func incrementItemCount(for tagId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == tagId }) {
                    self.tags[index].itemCount += 1
                    self.tags[index].updatedAt = Date()
                }
                continuation.resume()
            }
        }
    }
    
    public func decrementItemCount(for tagId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == tagId }) {
                    self.tags[index].itemCount = max(0, self.tags[index].itemCount - 1)
                    self.tags[index].updatedAt = Date()
                }
                continuation.resume()
            }
        }
    }
    
    public func fetchMostUsed(limit: Int) async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let sorted = self.tags.sorted { $0.itemCount > $1.itemCount }
                let limited = Array(sorted.prefix(limit))
                continuation.resume(returning: limited)
            }
        }
    }
    
    public func findByName(_ name: String) async throws -> Tag? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let tag = self.tags.first { $0.name.lowercased() == name.lowercased() }
                continuation.resume(returning: tag)
            }
        }
    }
}