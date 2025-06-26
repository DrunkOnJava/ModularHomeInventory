//
//  SyncModuleAPI.swift
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
//  Module: Sync
//  Dependencies: Foundation, Core, Combine
//  Testing: Modules/Sync/Tests/SyncTests/SyncModuleAPITests.swift
//
//  Description: Public API protocol definitions for the Sync module including sync status and cloud service protocols
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import Combine

/// Public API for the Sync module
/// Swift 5.9 - No Swift 6 features
public protocol SyncModuleAPI {
    /// Start syncing data
    func startSync() async throws
    
    /// Stop syncing data
    func stopSync()
    
    /// Force sync immediately
    func syncNow() async throws
    
    /// Get current sync status
    var syncStatus: SyncStatus { get }
    
    /// Listen to sync status changes
    var syncStatusPublisher: Published<SyncStatus>.Publisher { get }
}

/// Sync status information
public enum SyncStatus: Equatable {
    case idle
    case syncing(progress: Double)
    case completed(date: Date)
    case failed(error: String)
    
    public var isSyncing: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}

/// Dependencies required by the Sync module
public struct SyncModuleDependencies {
    public let itemRepository: ItemRepository
    public let receiptRepository: ReceiptRepository
    public let locationRepository: LocationRepository
    public let cloudService: CloudServiceProtocol
    
    public init(
        itemRepository: ItemRepository,
        receiptRepository: ReceiptRepository,
        locationRepository: LocationRepository,
        cloudService: CloudServiceProtocol
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
        self.cloudService = cloudService
    }
}

/// Protocol for cloud sync service
public protocol CloudServiceProtocol {
    /// Upload data to cloud
    func upload<T: Codable>(_ data: T, to path: String) async throws
    
    /// Download data from cloud
    func download<T: Codable>(_ type: T.Type, from path: String) async throws -> T?
    
    /// Delete data from cloud
    func delete(at path: String) async throws
    
    /// Check if user is authenticated
    var isAuthenticated: Bool { get }
    
    /// Authenticate user
    func authenticate() async throws
}