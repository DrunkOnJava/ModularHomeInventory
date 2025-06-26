//
//  Photo.swift
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
//  Testing: Modules/Core/Tests/CoreTests/PhotoTests.swift
//
//  Description: Photo model for item images with storage and repository protocols
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Photo model for item images
public struct Photo: Identifiable, Codable, Equatable {
    public let id: UUID
    public let itemId: UUID
    public var caption: String?
    public var sortOrder: Int
    public let createdAt: Date
    public var updatedAt: Date
    
    /// Transient property for image data
    public var imageData: Data?
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        caption: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.caption = caption
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, itemId, caption, sortOrder, createdAt, updatedAt
    }
}

// MARK: - Photo Storage Protocol
public protocol PhotoStorageProtocol {
    func savePhoto(_ imageData: Data, for photoId: UUID) async throws -> URL
    func loadPhoto(for photoId: UUID) async throws -> Data
    func deletePhoto(for photoId: UUID) async throws
    func generateThumbnail(_ imageData: Data, size: CGSize) async throws -> Data
}

// MARK: - Photo Repository Protocol
public protocol PhotoRepository {
    func savePhoto(_ photo: Photo, imageData: Data) async throws
    func loadPhotos(for itemId: UUID) async throws -> [Photo]
    func loadPhoto(id: UUID) async throws -> Photo?
    func deletePhoto(id: UUID) async throws
    func updatePhotoOrder(itemId: UUID, photoIds: [UUID]) async throws
    func updatePhotoCaption(id: UUID, caption: String?) async throws
}