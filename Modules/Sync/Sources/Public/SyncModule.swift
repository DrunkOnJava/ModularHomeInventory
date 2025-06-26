//
//  SyncModule.swift
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
//  Testing: Modules/Sync/Tests/SyncTests/SyncModuleTests.swift
//
//  Description: Main implementation of the Sync module for data synchronization across devices
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import Combine

/// Main implementation of the Sync module
/// Swift 5.9 - No Swift 6 features
public final class SyncModule: SyncModuleAPI {
    @Published public private(set) var syncStatus: SyncStatus = .idle
    public var syncStatusPublisher: Published<SyncStatus>.Publisher { $syncStatus }
    
    private let dependencies: SyncModuleDependencies
    private var syncTimer: Timer?
    private var syncTask: Task<Void, Error>?
    
    public init(dependencies: SyncModuleDependencies) {
        self.dependencies = dependencies
    }
    
    deinit {
        stopSync()
    }
    
    public func startSync() async throws {
        guard dependencies.cloudService.isAuthenticated else {
            try await dependencies.cloudService.authenticate()
            return
        }
        
        // Start periodic sync every 5 minutes
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try? await self?.syncNow()
            }
        }
        
        // Do initial sync
        try await syncNow()
    }
    
    public func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        syncTask?.cancel()
        syncTask = nil
        syncStatus = .idle
    }
    
    public func syncNow() async throws {
        guard !syncStatus.isSyncing else { return }
        
        syncTask?.cancel()
        syncTask = Task {
            do {
                syncStatus = .syncing(progress: 0.0)
                
                // Sync items
                syncStatus = .syncing(progress: 0.25)
                try await syncItems()
                
                // Sync receipts
                syncStatus = .syncing(progress: 0.5)
                try await syncReceipts()
                
                // Sync locations
                syncStatus = .syncing(progress: 0.75)
                try await syncLocations()
                
                syncStatus = .completed(date: Date())
            } catch {
                syncStatus = .failed(error: error.localizedDescription)
                throw error
            }
        }
        
        try await syncTask?.value
    }
    
    private func syncItems() async throws {
        let items = try await dependencies.itemRepository.fetchAll()
        try await dependencies.cloudService.upload(items, to: "items.json")
    }
    
    private func syncReceipts() async throws {
        let receipts = try await dependencies.receiptRepository.fetchAll()
        try await dependencies.cloudService.upload(receipts, to: "receipts.json")
    }
    
    private func syncLocations() async throws {
        let locations = try await dependencies.locationRepository.fetchAll()
        try await dependencies.cloudService.upload(locations, to: "locations.json")
    }
}