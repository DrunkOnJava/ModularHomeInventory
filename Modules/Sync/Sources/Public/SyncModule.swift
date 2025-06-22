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