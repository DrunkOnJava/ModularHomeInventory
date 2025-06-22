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