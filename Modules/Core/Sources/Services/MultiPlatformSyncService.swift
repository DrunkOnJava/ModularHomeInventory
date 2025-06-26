//
//  MultiPlatformSyncService.swift
//  Core Module
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import CloudKit
import Combine
import CryptoKit
import UIKit

/// Service for handling multi-platform sync across iOS, iPadOS, and macOS
public class MultiPlatformSyncService: NSObject, ObservableObject {
    
    // MARK: - Types
    
    /// Sync status for UI updates
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case uploading(progress: Double)
        case downloading(progress: Double)
        case error(String)
        
        public var isActive: Bool {
            switch self {
            case .syncing, .uploading, .downloading:
                return true
            default:
                return false
            }
        }
    }
    
    /// Device platform
    public enum Platform: String, CaseIterable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case mac = "Mac"
        
        public static var current: Platform {
            #if os(iOS)
            return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
            #elseif os(macOS)
            return .mac
            #endif
        }
    }
    
    /// Sync configuration
    public struct SyncConfiguration {
        public var automaticSync: Bool = true
        public var syncInterval: TimeInterval = 300 // 5 minutes
        public var wifiOnlySync: Bool = false
        public var syncOnAppLaunch: Bool = true
        public var syncOnAppBackground: Bool = true
        
        public init() {}
    }
    
    // MARK: - Published Properties
    
    @Published public private(set) var syncStatus: SyncStatus = .idle
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var pendingChanges: Int = 0
    @Published public private(set) var iCloudAvailable = false
    @Published public private(set) var connectedDevices: [DeviceInfo] = []
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var configuration = SyncConfiguration()
    private var syncTimer: Timer?
    private var subscriptions = Set<AnyCancellable>()
    
    // CloudKit zones
    private let syncZoneName = "HomeInventorySync"
    private lazy var syncZone = CKRecordZone(zoneName: syncZoneName)
    private lazy var syncZoneID = CKRecordZone.ID(zoneName: syncZoneName, ownerName: CKCurrentUserDefaultName)
    
    // Change tracking
    private var serverChangeToken: CKServerChangeToken?
    
    // MARK: - Initialization
    
    public override init() {
        self.container = CKContainer(identifier: "iCloud.com.homeinventory.app")
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        super.init()
        
        Task {
            await setupSync()
        }
    }
    
    // MARK: - Public Methods
    
    /// Configure sync settings
    public func configure(_ configuration: SyncConfiguration) {
        self.configuration = configuration
        
        if configuration.automaticSync {
            startAutomaticSync()
        } else {
            stopAutomaticSync()
        }
    }
    
    /// Manually trigger sync
    public func syncNow() async throws {
        guard iCloudAvailable else {
            throw SyncError.iCloudNotAvailable
        }
        
        await updateSyncStatus(.syncing)
        
        do {
            // Ensure sync zone exists
            try await ensureSyncZoneExists()
            
            // Fetch changes from server
            try await fetchRemoteChanges()
            
            // Push local changes
            try await pushLocalChanges()
            
            // Update device info
            try await updateDeviceInfo()
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            await updateSyncStatus(.idle)
            
        } catch {
            await updateSyncStatus(.error(error.localizedDescription))
            throw error
        }
    }
    
    /// Check if data needs sync
    public func needsSync() async -> Bool {
        // Check if there are pending local changes
        if pendingChanges > 0 {
            return true
        }
        
        // Check if remote has changes
        do {
            let hasRemoteChanges = try await checkForRemoteChanges()
            return hasRemoteChanges
        } catch {
            return false
        }
    }
    
    /// Get sync statistics
    public func getSyncStats() -> SyncStatistics {
        return SyncStatistics(
            lastSyncDate: lastSyncDate,
            pendingChanges: pendingChanges,
            totalSynced: UserDefaults.standard.integer(forKey: "totalSyncedItems"),
            conflictsResolved: UserDefaults.standard.integer(forKey: "conflictsResolved"),
            connectedDevices: connectedDevices.count
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSync() async {
        // Check iCloud availability
        await checkiCloudAvailability()
        
        // Setup push notifications for changes
        await setupPushNotifications()
        
        // Load saved state
        loadSyncState()
        
        // Setup subscriptions
        setupSubscriptions()
        
        // Initial sync if configured
        if configuration.syncOnAppLaunch && iCloudAvailable {
            try? await syncNow()
        }
    }
    
    private func checkiCloudAvailability() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.iCloudAvailable = (status == .available)
            }
        } catch {
            await MainActor.run {
                self.iCloudAvailable = false
            }
        }
    }
    
    private func ensureSyncZoneExists() async throws {
        do {
            _ = try await privateDatabase.save(syncZone)
        } catch {
            if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                // Zone doesn't exist, create it
                _ = try await privateDatabase.save(syncZone)
            } else {
                throw error
            }
        }
    }
    
    private func fetchRemoteChanges() async throws {
        let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
        options.previousServerChangeToken = serverChangeToken
        
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [syncZoneID],
            optionsByRecordZoneID: [syncZoneID: options]
        )
        
        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []
        
        operation.recordChangedBlock = { record in
            changedRecords.append(record)
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            deletedRecordIDs.append(recordID)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
            self.serverChangeToken = token
        }
        
        operation.recordZoneFetchCompletionBlock = { [weak self] _, token, _, _, error in
            if error == nil {
                self?.serverChangeToken = token
                self?.saveServerChangeToken()
            }
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            if let error = error {
                print("Fetch changes error: \(error)")
            } else {
                Task {
                    await self?.processRemoteChanges(
                        changed: changedRecords,
                        deleted: deletedRecordIDs
                    )
                }
            }
        }
        
        privateDatabase.add(operation)
        
        // Wait for operation to complete
        await withCheckedContinuation { continuation in
            operation.completionBlock = {
                continuation.resume()
            }
        }
    }
    
    private func processRemoteChanges(changed: [CKRecord], deleted: [CKRecord.ID]) async {
        // Update progress
        let total = changed.count + deleted.count
        guard total > 0 else { return }
        
        var processed = 0
        
        // Process changed records
        for record in changed {
            await updateSyncStatus(.downloading(progress: Double(processed) / Double(total)))
            await processChangedRecord(record)
            processed += 1
        }
        
        // Process deleted records
        for recordID in deleted {
            await updateSyncStatus(.downloading(progress: Double(processed) / Double(total)))
            await processDeletedRecord(recordID)
            processed += 1
        }
    }
    
    private func pushLocalChanges() async throws {
        // Get pending local changes
        let changes = await getPendingLocalChanges()
        guard !changes.isEmpty else { return }
        
        let total = changes.count
        var processed = 0
        
        for change in changes {
            await updateSyncStatus(.uploading(progress: Double(processed) / Double(total)))
            
            do {
                try await uploadChange(change)
                await markChangeAsSynced(change.id)
                processed += 1
            } catch {
                print("Failed to upload change: \(error)")
                // Continue with other changes
            }
        }
        
        // Update pending changes count
        await updatePendingChanges()
    }
    
    private func updateDeviceInfo() async throws {
        let deviceInfo = DeviceInfo(
            id: getDeviceID(),
            name: getDeviceName(),
            platform: Platform.current,
            lastSeen: Date(),
            systemVersion: getSystemVersion()
        )
        
        let record = deviceInfo.toCKRecord()
        _ = try await publicDatabase.save(record)
        
        // Fetch all devices
        await fetchConnectedDevices()
    }
    
    private func fetchConnectedDevices() async {
        do {
            let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
            let results = try await publicDatabase.perform(query, inZoneWith: nil)
            
            let devices = results.compactMap { DeviceInfo(record: $0) }
            
            await MainActor.run {
                self.connectedDevices = devices.sorted { $0.lastSeen > $1.lastSeen }
            }
        } catch {
            print("Failed to fetch devices: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: configuration.syncInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.syncNow()
            }
        }
    }
    
    private func stopAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func setupSubscriptions() {
        // Listen for app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.configuration.syncOnAppLaunch == true {
                    Task {
                        try? await self?.syncNow()
                    }
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                if self?.configuration.syncOnAppBackground == true {
                    Task {
                        try? await self?.syncNow()
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setupPushNotifications() async {
        // Create subscription for changes
        let subscription = CKDatabaseSubscription(subscriptionID: "home-inventory-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await privateDatabase.save(subscription)
        } catch {
            print("Failed to setup push notifications: \(error)")
        }
    }
    
    @MainActor
    private func updateSyncStatus(_ status: SyncStatus) {
        self.syncStatus = status
    }
    
    @MainActor
    private func updatePendingChanges() {
        // In real implementation, count actual pending changes
        self.pendingChanges = 0
    }
    
    // MARK: - Persistence
    
    private func loadSyncState() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate") as? TimeInterval {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
        }
        
        if let tokenData = UserDefaults.standard.data(forKey: "serverChangeToken") {
            serverChangeToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
        }
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "lastSyncDate")
        }
    }
    
    private func saveServerChangeToken() {
        if let token = serverChangeToken {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "serverChangeToken")
        }
    }
    
    // MARK: - Device Info
    
    private func getDeviceID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    private func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    private func getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    // MARK: - Placeholder Methods
    
    private func checkForRemoteChanges() async throws -> Bool {
        // Implementation would check for remote changes
        return false
    }
    
    private func getPendingLocalChanges() async -> [LocalChange] {
        // Implementation would fetch pending local changes
        return []
    }
    
    private func uploadChange(_ change: LocalChange) async throws {
        // Implementation would upload change to CloudKit
    }
    
    private func markChangeAsSynced(_ changeId: UUID) async {
        // Implementation would mark change as synced
    }
    
    private func processChangedRecord(_ record: CKRecord) async {
        // Implementation would process changed record
    }
    
    private func processDeletedRecord(_ recordID: CKRecord.ID) async {
        // Implementation would process deleted record
    }
}

// MARK: - Supporting Types

/// Device information
public struct DeviceInfo: Identifiable {
    public let id: String
    public let name: String
    public let platform: MultiPlatformSyncService.Platform
    public let lastSeen: Date
    public let systemVersion: String
    
    init(id: String, name: String, platform: MultiPlatformSyncService.Platform, lastSeen: Date, systemVersion: String) {
        self.id = id
        self.name = name
        self.platform = platform
        self.lastSeen = lastSeen
        self.systemVersion = systemVersion
    }
    
    init?(record: CKRecord) {
        guard let id = record["deviceID"] as? String,
              let name = record["name"] as? String,
              let platformString = record["platform"] as? String,
              let platform = MultiPlatformSyncService.Platform(rawValue: platformString),
              let lastSeen = record["lastSeen"] as? Date,
              let systemVersion = record["systemVersion"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.platform = platform
        self.lastSeen = lastSeen
        self.systemVersion = systemVersion
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Device")
        record["deviceID"] = id as CKRecordValue
        record["name"] = name as CKRecordValue
        record["platform"] = platform.rawValue as CKRecordValue
        record["lastSeen"] = lastSeen as CKRecordValue
        record["systemVersion"] = systemVersion as CKRecordValue
        return record
    }
}

/// Sync statistics
public struct SyncStatistics {
    public let lastSyncDate: Date?
    public let pendingChanges: Int
    public let totalSynced: Int
    public let conflictsResolved: Int
    public let connectedDevices: Int
}

/// Local change representation
public struct LocalChange: Identifiable {
    public let id = UUID()
    public let recordType: String
    public let recordID: String
    public let changeType: ChangeType
    public let data: Data
    
    public enum ChangeType {
        case create
        case update
        case delete
    }
}

/// Sync errors
public enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case networkUnavailable
    case syncInProgress
    
    public var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .networkUnavailable:
            return "Network connection is not available."
        case .syncInProgress:
            return "Sync is already in progress."
        }
    }
}