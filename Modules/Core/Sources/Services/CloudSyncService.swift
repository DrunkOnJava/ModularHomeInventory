//
//  CloudSyncService.swift
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
//  Dependencies: Foundation, Combine
//  Testing: CoreTests/CloudSyncServiceTests.swift
//
//  Description: Cloud sync service that coordinates syncing between local DocumentRepository and CloudDocumentStorage
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Combine

/// Cloud sync service that coordinates syncing between local DocumentRepository and CloudDocumentStorage
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class CloudSyncService: ObservableObject {
    
    // MARK: - Properties
    
    /// Singleton instance
    public static let shared = CloudSyncService()
    
    /// Published sync state properties
    @Published public private(set) var isSyncing = false
    @Published public private(set) var syncProgress: Double = 0.0
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncErrors: [CloudSyncError] = []
    @Published public private(set) var syncQueue: [SyncQueueItem] = []
    @Published public private(set) var conflictedDocuments: [SyncConflict] = []
    
    /// Sync settings
    @Published public var isAutoSyncEnabled = true {
        didSet {
            UserDefaults.standard.set(isAutoSyncEnabled, forKey: "cloudSyncAutoEnabled")
            if isAutoSyncEnabled {
                startAutoSync()
            } else {
                stopAutoSync()
            }
        }
    }
    
    @Published public var syncOnCellular = false {
        didSet {
            UserDefaults.standard.set(syncOnCellular, forKey: "cloudSyncOnCellular")
        }
    }
    
    /// Dependencies
    private let documentRepository: any DocumentRepository
    private let cloudStorage: CloudDocumentStorageProtocol
    private let networkMonitor = NetworkMonitor.shared
    
    /// Sync management
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let syncInterval: TimeInterval = 300 // 5 minutes
    private let processingQueue = DispatchQueue(label: "com.homeinventory.cloudsync", qos: .background)
    
    /// Persistence keys
    private let lastSyncKey = "cloudSyncLastDate"
    private let syncQueueKey = "cloudSyncQueue"
    private let encryptionPrefsKey = "documentEncryptionPrefs"
    
    // MARK: - Initialization
    
    private init(
        documentRepository: any DocumentRepository = DefaultDocumentRepository(),
        cloudStorage: CloudDocumentStorageProtocol? = nil
    ) {
        self.documentRepository = documentRepository
        self.cloudStorage = cloudStorage ?? (try? ICloudDocumentStorage()) ?? MockCloudStorage()
        
        loadSyncState()
        setupNetworkMonitoring()
        
        if isAutoSyncEnabled {
            startAutoSync()
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually trigger a sync
    public func syncNow() async {
        guard !isSyncing else { return }
        await performSync()
    }
    
    /// Sync a specific document
    public func syncDocument(_ document: Document, encrypted: Bool? = nil) async throws {
        let shouldEncrypt = encrypted ?? getEncryptionPreference(for: document.id)
        
        // Add to sync queue
        let queueItem = SyncQueueItem(
            documentId: document.id,
            operation: .upload,
            encrypted: shouldEncrypt,
            timestamp: Date()
        )
        
        syncQueue.append(queueItem)
        saveSyncQueue()
        
        // Sync immediately if connected
        if canSync() {
            try await syncSingleDocument(document, encrypted: shouldEncrypt)
            removeSyncQueueItem(document.id)
        }
    }
    
    /// Delete document from cloud
    public func deleteDocumentFromCloud(_ documentId: UUID) async throws {
        // Add to sync queue
        let queueItem = SyncQueueItem(
            documentId: documentId,
            operation: .delete,
            encrypted: false,
            timestamp: Date()
        )
        
        syncQueue.append(queueItem)
        saveSyncQueue()
        
        // Delete immediately if connected
        if canSync() {
            try await cloudStorage.deleteDocument(documentId: documentId)
            removeSyncQueueItem(documentId)
        }
    }
    
    /// Set encryption preference for a document
    public func setEncryptionPreference(for documentId: UUID, encrypted: Bool) {
        var prefs = UserDefaults.standard.dictionary(forKey: encryptionPrefsKey) ?? [:]
        prefs[documentId.uuidString] = encrypted
        UserDefaults.standard.set(prefs, forKey: encryptionPrefsKey)
    }
    
    /// Get encryption preference for a document
    public func getEncryptionPreference(for documentId: UUID) -> Bool {
        let prefs = UserDefaults.standard.dictionary(forKey: encryptionPrefsKey) ?? [:]
        return prefs[documentId.uuidString] as? Bool ?? true // Default to encrypted
    }
    
    /// Resolve a sync conflict
    public func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws {
        switch resolution {
        case .keepLocal:
            // Upload local version to cloud
            if let document = try await documentRepository.fetch(id: conflict.documentId) {
                try await syncSingleDocument(document, encrypted: conflict.localEncrypted)
            }
            
        case .keepCloud:
            // Download cloud version
            _ = try await cloudStorage.downloadDocument(documentId: conflict.documentId)
            // Update local document with cloud data
            if var document = try await documentRepository.fetch(id: conflict.documentId) {
                document.updatedAt = conflict.cloudMetadata.lastModified
                try await documentRepository.save(document)
            }
            
        case .keepBoth:
            // Create a copy of the local document with a new ID
            if var document = try await documentRepository.fetch(id: conflict.documentId) {
                let newDocument = Document(
                    id: UUID(),
                    name: "\(document.name) (Local Copy)",
                    type: document.type,
                    category: document.category,
                    subcategory: document.subcategory,
                    fileSize: document.fileSize,
                    mimeType: document.mimeType,
                    itemId: document.itemId,
                    receiptId: document.receiptId,
                    warrantyId: document.warrantyId,
                    tags: document.tags,
                    notes: document.notes,
                    pageCount: document.pageCount,
                    thumbnailData: document.thumbnailData,
                    searchableText: document.searchableText,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await documentRepository.save(newDocument)
                
                // Download cloud version to original document
                _ = try await cloudStorage.downloadDocument(documentId: conflict.documentId)
                document.updatedAt = conflict.cloudMetadata.lastModified
                try await documentRepository.save(document)
            }
        }
        
        // Remove from conflicts
        conflictedDocuments.removeAll { $0.id == conflict.id }
    }
    
    /// Clear sync errors
    public func clearSyncErrors() {
        syncErrors.removeAll()
    }
    
    /// Get sync status for a document
    public func getSyncStatus(for documentId: UUID) async -> Core.SyncStatus {
        // Check if in sync queue
        if syncQueue.contains(where: { $0.documentId == documentId }) {
            return .pending
        }
        
        // Check if exists in cloud
        do {
            if let cloudMetadata = try await cloudStorage.getDocumentMetadata(documentId: documentId),
               let localDocument = try await documentRepository.fetch(id: documentId) {
                // Compare timestamps
                if abs(cloudMetadata.lastModified.timeIntervalSince(localDocument.updatedAt)) < 1 {
                    return .synced
                } else {
                    return .conflict
                }
            } else {
                return .notSynced
            }
        } catch {
            return .error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        networkMonitor.$isConnected
            .combineLatest(networkMonitor.$isExpensive)
            .sink { [weak self] isConnected, isExpensive in
                guard let self = self else { return }
                
                if isConnected && (self.syncOnCellular || !isExpensive) {
                    Task {
                        await self.processSyncQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startAutoSync() {
        stopAutoSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performSync()
            }
        }
    }
    
    private func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func canSync() -> Bool {
        networkMonitor.isConnected && (syncOnCellular || !networkMonitor.isExpensive)
    }
    
    private func performSync() async {
        guard canSync() else { return }
        
        isSyncing = true
        syncProgress = 0.0
        
        do {
            // Process sync queue first
            await processSyncQueue()
            
            // Full sync
            let localDocuments = try await documentRepository.fetchAll()
            let cloudDocuments = try await cloudStorage.listDocuments()
            
            let total = Double(localDocuments.count + cloudDocuments.count)
            var processed = 0.0
            
            // Create lookup dictionaries
            let localDict = Dictionary(uniqueKeysWithValues: localDocuments.map { ($0.id, $0) })
            let cloudDict = Dictionary(uniqueKeysWithValues: cloudDocuments.map { ($0.documentId, $0) })
            
            // Upload new local documents
            for document in localDocuments {
                if cloudDict[document.id] == nil {
                    try await syncSingleDocument(document, encrypted: getEncryptionPreference(for: document.id))
                }
                processed += 1
                syncProgress = processed / total
            }
            
            // Download new cloud documents
            for cloudMetadata in cloudDocuments {
                if localDict[cloudMetadata.documentId] == nil {
                    try await downloadCloudDocument(cloudMetadata)
                } else if let localDocument = localDict[cloudMetadata.documentId] {
                    // Check for conflicts
                    await checkForConflict(localDocument: localDocument, cloudMetadata: cloudMetadata)
                }
                processed += 1
                syncProgress = processed / total
            }
            
            lastSyncDate = Date()
            saveLastSyncDate()
            
        } catch {
            let syncError = CloudSyncError(
                id: UUID(),
                error: error,
                timestamp: Date(),
                documentId: nil
            )
            syncErrors.append(syncError)
        }
        
        isSyncing = false
        syncProgress = 1.0
    }
    
    private func processSyncQueue() async {
        let items = syncQueue
        
        for item in items {
            guard canSync() else { break }
            
            do {
                switch item.operation {
                case .upload:
                    if let document = try await documentRepository.fetch(id: item.documentId) {
                        try await syncSingleDocument(document, encrypted: item.encrypted)
                    }
                    
                case .delete:
                    try await cloudStorage.deleteDocument(documentId: item.documentId)
                    
                case .download:
                    if let metadata = try await cloudStorage.getDocumentMetadata(documentId: item.documentId) {
                        try await downloadCloudDocument(metadata)
                    }
                }
                
                removeSyncQueueItem(item.documentId)
                
            } catch {
                let syncError = CloudSyncError(
                    id: UUID(),
                    error: error,
                    timestamp: Date(),
                    documentId: item.documentId
                )
                syncErrors.append(syncError)
            }
        }
    }
    
    private func syncSingleDocument(_ document: Document, encrypted: Bool) async throws {
        // Load document data
        let storage = try FileDocumentStorage()
        let data = try await storage.loadDocument(documentId: document.id)
        
        // Upload to cloud
        _ = try await cloudStorage.uploadDocument(data, documentId: document.id, encrypted: encrypted)
    }
    
    private func downloadCloudDocument(_ metadata: CloudDocumentMetadata) async throws {
        // Download from cloud
        let data = try await cloudStorage.downloadDocument(documentId: metadata.documentId)
        
        // Save locally
        let storage = try FileDocumentStorage()
        _ = try await storage.saveDocument(data, documentId: metadata.documentId)
        
        // Create document record if needed
        if try await documentRepository.fetch(id: metadata.documentId) == nil {
            let document = Document(
                id: metadata.documentId,
                name: "Downloaded Document",
                type: .other,
                fileSize: metadata.fileSize,
                mimeType: "application/octet-stream",
                createdAt: metadata.uploadedAt,
                updatedAt: metadata.lastModified
            )
            try await documentRepository.save(document)
        }
    }
    
    private func checkForConflict(localDocument: Document, cloudMetadata: CloudDocumentMetadata) async {
        // Compare modification dates (with 1 second tolerance)
        let timeDifference = abs(localDocument.updatedAt.timeIntervalSince(cloudMetadata.lastModified))
        
        if timeDifference > 1 {
            // Conflict detected
            let conflict = SyncConflict(
                id: UUID(),
                documentId: localDocument.id,
                localDocument: localDocument,
                cloudMetadata: cloudMetadata,
                localModified: localDocument.updatedAt,
                cloudModified: cloudMetadata.lastModified,
                localEncrypted: getEncryptionPreference(for: localDocument.id),
                cloudEncrypted: cloudMetadata.encrypted
            )
            
            // Prefer newer version by default
            if localDocument.updatedAt > cloudMetadata.lastModified {
                // Auto-resolve: keep local
                Task {
                    try? await resolveConflict(conflict, resolution: .keepLocal)
                }
            } else {
                // Add to conflicts for manual resolution
                conflictedDocuments.append(conflict)
            }
        }
    }
    
    private func removeSyncQueueItem(_ documentId: UUID) {
        syncQueue.removeAll { $0.documentId == documentId }
        saveSyncQueue()
    }
    
    // MARK: - Persistence
    
    private func loadSyncState() {
        // Load last sync date
        if let timestamp = UserDefaults.standard.object(forKey: lastSyncKey) as? Double {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
        }
        
        // Load sync queue
        if let data = UserDefaults.standard.data(forKey: syncQueueKey),
           let items = try? JSONDecoder().decode([SyncQueueItem].self, from: data) {
            syncQueue = items
        }
        
        // Load settings
        isAutoSyncEnabled = UserDefaults.standard.bool(forKey: "cloudSyncAutoEnabled")
        syncOnCellular = UserDefaults.standard.bool(forKey: "cloudSyncOnCellular")
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastSyncKey)
        }
    }
    
    private func saveSyncQueue() {
        if let data = try? JSONEncoder().encode(syncQueue) {
            UserDefaults.standard.set(data, forKey: syncQueueKey)
        }
    }
}

// MARK: - Supporting Types

/// Sync queue item
public struct SyncQueueItem: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let operation: SyncOperation
    public let encrypted: Bool
    public let timestamp: Date
    
    public enum SyncOperation: String, Codable {
        case upload
        case download
        case delete
    }
    
    public init(documentId: UUID, operation: SyncOperation, encrypted: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.documentId = documentId
        self.operation = operation
        self.encrypted = encrypted
        self.timestamp = timestamp
    }
}

/// Sync conflict
public struct SyncConflict: Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let localDocument: Document
    public let cloudMetadata: CloudDocumentMetadata
    public let localModified: Date
    public let cloudModified: Date
    public let localEncrypted: Bool
    public let cloudEncrypted: Bool
    
    public var newerVersion: ConflictResolution {
        localModified > cloudModified ? .keepLocal : .keepCloud
    }
}

/// Conflict resolution options
public enum ConflictResolution {
    case keepLocal
    case keepCloud
    case keepBoth
}

/// Sync error
public struct CloudSyncError: Identifiable {
    public let id: UUID
    public let error: Error
    public let timestamp: Date
    public let documentId: UUID?
    
    public var localizedDescription: String {
        error.localizedDescription
    }
}


// MARK: - Mock Cloud Storage (for testing)

private final class MockCloudStorage: CloudDocumentStorageProtocol {
    func uploadDocument(_ data: Data, documentId: UUID, encrypted: Bool) async throws -> CloudDocumentMetadata {
        CloudDocumentMetadata(
            documentId: documentId,
            cloudPath: "mock/\(documentId)",
            uploadedAt: Date(),
            lastModified: Date(),
            fileSize: Int64(data.count),
            checksum: "",
            encrypted: encrypted,
            syncStatus: .synced
        )
    }
    
    func downloadDocument(documentId: UUID) async throws -> Data {
        Data()
    }
    
    func deleteDocument(documentId: UUID) async throws {}
    
    func documentExists(documentId: UUID) async throws -> Bool {
        false
    }
    
    func getDocumentMetadata(documentId: UUID) async throws -> CloudDocumentMetadata? {
        nil
    }
    
    func listDocuments() async throws -> [CloudDocumentMetadata] {
        []
    }
    
    func getStorageUsage() async throws -> CloudStorageUsage {
        CloudStorageUsage(usedBytes: 0, totalBytes: 0, documentCount: 0)
    }
    
    func syncDocument(documentId: UUID, data: Data, encrypted: Bool) async throws {}
    
    func syncPendingDocuments() async throws {}
}