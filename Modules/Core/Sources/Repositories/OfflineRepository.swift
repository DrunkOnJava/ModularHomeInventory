//
//  OfflineRepository.swift
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
//  Dependencies: Foundation, Combine
//  Testing: Repository wrapper with offline capabilities
//
//  Description: Generic repository wrapper providing offline support with local caching,
//  operation queueing, and automatic sync coordination. Supports online/offline modes,
//  change publishing, and background synchronization.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Combine

/// A repository wrapper that provides offline support
/// Swift 5.9 - No Swift 6 features
public final class OfflineRepository<T: Codable & Identifiable, R: Repository> where R.Entity == T, T.ID == UUID {
    
    private let onlineRepository: R
    private let offlineStorage = OfflineStorageManager.shared
    private let offlineQueue = OfflineQueueManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let cacheKey: String
    
    // Combine subjects
    private let changesSubject = PassthroughSubject<RepositoryChange<T>, Never>()
    
    public var changesPublisher: AnyPublisher<RepositoryChange<T>, Never> {
        changesSubject.eraseToAnyPublisher()
    }
    
    public init(wrapping repository: R, cacheKey: String) {
        self.onlineRepository = repository
        self.cacheKey = cacheKey
    }
    
    // MARK: - Repository Methods
    
    /// Fetch all items with offline support
    public func fetchAll() async throws -> [T] {
        let isConnected = await networkMonitor.isConnected
        if isConnected {
            // Online: fetch from server and cache
            do {
                let items = try await onlineRepository.fetchAll()
                try? offlineStorage.save(items, key: "\(cacheKey)_all")
                return items
            } catch {
                // If online fetch fails, try offline cache
                if let cachedItems = try? offlineStorage.load([T].self, key: "\(cacheKey)_all") {
                    return cachedItems
                }
                throw error
            }
        } else {
            // Offline: use cached data
            if let cachedItems = try? offlineStorage.load([T].self, key: "\(cacheKey)_all") {
                return cachedItems
            }
            throw OfflineError.noOfflineData
        }
    }
    
    /// Fetch item by ID with offline support
    public func fetch(by id: UUID) async throws -> T? {
        let isConnected = await networkMonitor.isConnected
        if isConnected {
            // Online: fetch from server and cache
            do {
                let item = try await onlineRepository.fetch(id: id)
                if let item = item {
                    try? offlineStorage.save(item, key: "\(cacheKey)_\(id)")
                }
                return item
            } catch {
                // If online fetch fails, try offline cache
                return try? offlineStorage.load(T.self, key: "\(cacheKey)_\(id)")
            }
        } else {
            // Offline: use cached data
            return try? offlineStorage.load(T.self, key: "\(cacheKey)_\(id)")
        }
    }
    
    /// Save item with offline queueing
    public func save(_ item: T) async throws {
        let isConnected = await networkMonitor.isConnected
        if isConnected {
            // Online: save directly
            try await onlineRepository.save(item)
            try? offlineStorage.save(item, key: "\(cacheKey)_\(item.id)")
            changesSubject.send(.created(item))
        } else {
            // Offline: queue for later and save to cache
            let operation = try QueuedOperation(
                type: .createItem,
                data: OfflineItemOperation(item: item, repositoryKey: cacheKey)
            )
            await offlineQueue.enqueue(operation)
            
            // Save to offline cache
            try offlineStorage.save(item, key: "\(cacheKey)_\(item.id)")
            
            // Update all items cache
            var allItems = (try? offlineStorage.load([T].self, key: "\(cacheKey)_all")) ?? []
            allItems.append(item)
            try? offlineStorage.save(allItems, key: "\(cacheKey)_all")
            
            changesSubject.send(.created(item))
        }
    }
    
    /// Delete item with offline queueing
    public func delete(_ item: T) async throws {
        let isConnected = await networkMonitor.isConnected
        if isConnected {
            // Online: delete directly
            try await onlineRepository.delete(item)
            try? offlineStorage.delete(key: "\(cacheKey)_\(item.id)")
            changesSubject.send(.deleted(item))
        } else {
            // Offline: queue for later and remove from cache
            let operation = try QueuedOperation(
                type: .deleteItem,
                data: OfflineItemOperation(item: item, repositoryKey: cacheKey)
            )
            await offlineQueue.enqueue(operation)
            
            // Remove from offline cache
            try? offlineStorage.delete(key: "\(cacheKey)_\(item.id)")
            
            // Update all items cache
            if var allItems = try? offlineStorage.load([T].self, key: "\(cacheKey)_all") {
                allItems.removeAll { $0.id == item.id }
                try? offlineStorage.save(allItems, key: "\(cacheKey)_all")
            }
            
            changesSubject.send(.deleted(item))
        }
    }
}

// MARK: - Repository Change

public enum RepositoryChange<T> {
    case created(T)
    case updated(T)
    case deleted(T)
}

// MARK: - Offline Error

public enum OfflineError: LocalizedError {
    case noOfflineData
    case syncInProgress
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .noOfflineData:
            return "No offline data available"
        case .syncInProgress:
            return "Sync is already in progress"
        case .networkUnavailable:
            return "Network connection is not available"
        }
    }
}

// MARK: - Offline Item Operation

struct OfflineItemOperation: Codable {
    let item: Data
    let repositoryKey: String
    let itemType: String
    
    init<T: Codable>(item: T, repositoryKey: String) throws {
        let encoder = JSONEncoder()
        self.item = try encoder.encode(item)
        self.repositoryKey = repositoryKey
        self.itemType = String(describing: T.self)
    }
}

// MARK: - Offline Sync Coordinator

/// Coordinates offline sync operations across repositories
@MainActor
public final class OfflineSyncCoordinator: ObservableObject {
    
    // Singleton instance
    public static let shared = OfflineSyncCoordinator()
    
    @Published public private(set) var isSyncing = false
    @Published public private(set) var syncProgress: Double = 0
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var pendingOperations: Int = 0
    
    private let offlineQueue = OfflineQueueManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
        loadLastSyncDate()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .filter { $0 } // Only when connected
            .sink { [weak self] _ in
                Task {
                    await self?.performSync()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Manually trigger sync
    public func syncNow() async throws {
        guard networkMonitor.isConnected else {
            throw OfflineError.networkUnavailable
        }
        
        guard !isSyncing else {
            throw OfflineError.syncInProgress
        }
        
        await performSync()
    }
    
    private func performSync() async {
        isSyncing = true
        syncProgress = 0
        
        // Process offline queue
        await offlineQueue.processQueue()
        
        // Update sync status
        isSyncing = false
        syncProgress = 1.0
        lastSyncDate = Date()
        saveLastSyncDate()
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
}