//
//  BackupService.swift
//  Core
//
//  Service for creating and restoring complete backup archives
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Compression

@available(iOS 15.0, *)
public final class BackupService: ObservableObject {
    public static let shared = BackupService()
    
    // MARK: - Published Properties
    
    @Published public var isCreatingBackup = false
    @Published public var isRestoringBackup = false
    @Published public var backupProgress: Double = 0.0
    @Published public var currentOperation: String = ""
    @Published public var availableBackups: [BackupInfo] = []
    @Published public var lastBackupDate: Date?
    @Published public var error: BackupError?
    
    // MARK: - Types
    
    public struct BackupInfo: Identifiable, Codable {
        public let id: UUID
        public let createdDate: Date
        public let fileName: String
        public let fileSize: Int64
        public let itemCount: Int
        public let photoCount: Int
        public let receiptCount: Int
        public let appVersion: String
        public let deviceName: String
        public let isEncrypted: Bool
        public let compressionRatio: Double
        public let checksum: String
        
        public var formattedFileSize: String {
            ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
    }
    
    public struct BackupManifest: Codable {
        public let version: Int = 1
        public let createdDate: Date
        public let appVersion: String
        public let deviceName: String
        public let contents: BackupContents
        public let checksum: String
    }
    
    public struct BackupContents: Codable {
        public let items: [Item]
        public let categories: [String] // Category names
        public let locations: [Location]
        public let collections: [Collection]
        public let warranties: [Warranty]
        public let receipts: [Receipt]
        public let tags: [Tag]
        public let storageUnits: [StorageUnit]
        public let budgets: [Budget]
        public let settings: BackupSettings
        public let photoReferences: [PhotoReference]
        public let documentReferences: [DocumentReference]
    }
    
    public struct BackupSettings: Codable {
        public let userPreferences: [String: Any]
        public let notificationSettings: [String: Bool]
        public let privacySettings: [String: Bool]
        
        public init(
            userPreferences: [String: Any] = [:],
            notificationSettings: [String: Bool] = [:],
            privacySettings: [String: Bool] = [:]
        ) {
            self.userPreferences = userPreferences
            self.notificationSettings = notificationSettings
            self.privacySettings = privacySettings
        }
        
        enum CodingKeys: String, CodingKey {
            case userPreferences, notificationSettings, privacySettings
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userPreferences = try container.decode([String: AnyCodable].self, forKey: .userPreferences).mapValues { $0.value }
            notificationSettings = try container.decode([String: Bool].self, forKey: .notificationSettings)
            privacySettings = try container.decode([String: Bool].self, forKey: .privacySettings)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(userPreferences.mapValues { AnyCodable($0) }, forKey: .userPreferences)
            try container.encode(notificationSettings, forKey: .notificationSettings)
            try container.encode(privacySettings, forKey: .privacySettings)
        }
    }
    
    public struct PhotoReference: Codable {
        public let id: UUID
        public let itemId: UUID
        public let fileName: String
        public let checksum: String
    }
    
    public struct DocumentReference: Codable {
        public let id: UUID
        public let type: DocumentType
        public let relatedId: UUID
        public let fileName: String
        public let checksum: String
        
        public enum DocumentType: String, Codable {
            case receipt
            case warranty
            case manual
            case appraisal
            case insurance
        }
    }
    
    public enum BackupError: LocalizedError {
        case creationFailed(String)
        case restorationFailed(String)
        case invalidBackupFile
        case incompatibleVersion
        case checksumMismatch
        case insufficientSpace
        case encryptionFailed
        case decryptionFailed
        
        public var errorDescription: String? {
            switch self {
            case .creationFailed(let reason):
                return "Failed to create backup: \(reason)"
            case .restorationFailed(let reason):
                return "Failed to restore backup: \(reason)"
            case .invalidBackupFile:
                return "Invalid backup file format"
            case .incompatibleVersion:
                return "Backup version is not compatible with this app version"
            case .checksumMismatch:
                return "Backup file integrity check failed"
            case .insufficientSpace:
                return "Not enough storage space for backup"
            case .encryptionFailed:
                return "Failed to encrypt backup"
            case .decryptionFailed:
                return "Failed to decrypt backup"
            }
        }
    }
    
    public enum BackupOptions: Hashable {
        case includePhotos
        case includeReceipts
        case includeDocuments
        case compress
        case encrypt(password: String)
        case excludeDeleted
        case incrementalBackup
    }
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    private let tempDirectory: URL
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    // MARK: - Initialization
    
    private init() {
        // Setup directories
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.backupDirectory = documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
        self.tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("BackupTemp", isDirectory: true)
        
        // Create directories if needed
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Configure JSON encoder/decoder
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        // Load available backups
        loadAvailableBackups()
        loadLastBackupDate()
    }
    
    // MARK: - Public Methods
    
    /// Create a complete backup archive
    public func createBackup(
        items: [Item],
        categories: [String] = [],
        locations: [Location] = [],
        collections: [Collection] = [],
        warranties: [Warranty] = [],
        receipts: [Receipt] = [],
        tags: [Tag] = [],
        storageUnits: [StorageUnit] = [],
        budgets: [Budget] = [],
        options: Set<BackupOptions> = [.includePhotos, .includeReceipts, .compress]
    ) async throws -> URL {
        isCreatingBackup = true
        backupProgress = 0.0
        currentOperation = "Preparing backup..."
        
        defer {
            isCreatingBackup = false
            backupProgress = 0.0
            currentOperation = ""
        }
        
        // Clean temp directory
        try? fileManager.removeItem(at: tempDirectory)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Create backup directory structure
        let backupId = UUID()
        let backupName = "backup_\(Date().timeIntervalSince1970).hib"
        let backupPath = tempDirectory.appendingPathComponent(backupId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: backupPath, withIntermediateDirectories: true)
        
        // Step 1: Export data (30%)
        currentOperation = "Exporting data..."
        backupProgress = 0.1
        
        let manifest = try await createManifest(
            items: items,
            categories: categories,
            locations: locations,
            collections: collections,
            warranties: warranties,
            receipts: receipts,
            tags: tags,
            storageUnits: storageUnits,
            budgets: budgets,
            options: options
        )
        
        let manifestData = try jsonEncoder.encode(manifest)
        try manifestData.write(to: backupPath.appendingPathComponent("manifest.json"))
        
        backupProgress = 0.3
        
        // Step 2: Copy photos (30%)
        if options.contains(.includePhotos) {
            currentOperation = "Copying photos..."
            try await copyPhotos(for: items, to: backupPath)
        }
        
        backupProgress = 0.6
        
        // Step 3: Copy documents (20%)
        if options.contains(.includeReceipts) || options.contains(.includeDocuments) {
            currentOperation = "Copying documents..."
            try await copyDocuments(
                receipts: receipts,
                warranties: warranties,
                to: backupPath
            )
        }
        
        backupProgress = 0.8
        
        // Step 4: Create archive (20%)
        currentOperation = "Creating archive..."
        let archiveURL = backupDirectory.appendingPathComponent(backupName)
        
        if options.contains(.compress) {
            try await createCompressedArchive(from: backupPath, to: archiveURL)
        } else {
            try await createArchive(from: backupPath, to: archiveURL)
        }
        
        // Step 5: Encrypt if requested
        if case .encrypt(let password) = options.first(where: { if case .encrypt = $0 { return true } else { return false } }) {
            currentOperation = "Encrypting backup..."
            try await encryptBackup(at: archiveURL, password: password)
        }
        
        backupProgress = 1.0
        
        // Update backup info
        let fileSize = try fileManager.attributesOfItem(atPath: archiveURL.path)[.size] as? Int64 ?? 0
        let info = BackupInfo(
            id: backupId,
            createdDate: Date(),
            fileName: backupName,
            fileSize: fileSize,
            itemCount: items.count,
            photoCount: manifest.contents.photoReferences.count,
            receiptCount: manifest.contents.documentReferences.filter { $0.type == .receipt }.count,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            deviceName: await MainActor.run { UIDevice.current.name },
            isEncrypted: options.contains(where: { if case .encrypt = $0 { return true } else { return false } }),
            compressionRatio: options.contains(.compress) ? calculateCompressionRatio(backupPath: backupPath, archiveSize: fileSize) : 1.0,
            checksum: try calculateChecksum(for: archiveURL)
        )
        
        saveBackupInfo(info)
        lastBackupDate = Date()
        saveLastBackupDate()
        
        // Clean up temp directory
        try? fileManager.removeItem(at: tempDirectory)
        
        return archiveURL
    }
    
    /// Restore from backup archive
    public func restoreBackup(from url: URL, password: String? = nil) async throws -> BackupContents {
        isRestoringBackup = true
        backupProgress = 0.0
        currentOperation = "Preparing restoration..."
        
        defer {
            isRestoringBackup = false
            backupProgress = 0.0
            currentOperation = ""
        }
        
        // Clean temp directory
        try? fileManager.removeItem(at: tempDirectory)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Copy backup to temp location
        let tempBackupURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        try fileManager.copyItem(at: url, to: tempBackupURL)
        
        // Decrypt if needed
        if let password = password {
            currentOperation = "Decrypting backup..."
            try await decryptBackup(at: tempBackupURL, password: password)
        }
        
        backupProgress = 0.2
        
        // Extract archive
        currentOperation = "Extracting archive..."
        let extractPath = tempDirectory.appendingPathComponent("extract", isDirectory: true)
        
        if url.pathExtension == "hib" {
            try await extractCompressedArchive(from: tempBackupURL, to: extractPath)
        } else {
            try await extractArchive(from: tempBackupURL, to: extractPath)
        }
        
        backupProgress = 0.4
        
        // Read manifest
        currentOperation = "Reading backup data..."
        let manifestURL = extractPath.appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw BackupError.invalidBackupFile
        }
        
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try jsonDecoder.decode(BackupManifest.self, from: manifestData)
        
        // Verify checksum
        currentOperation = "Verifying integrity..."
        let calculatedChecksum = try calculateChecksum(for: tempBackupURL)
        guard calculatedChecksum == manifest.checksum else {
            throw BackupError.checksumMismatch
        }
        
        backupProgress = 0.6
        
        // Restore photos
        if !manifest.contents.photoReferences.isEmpty {
            currentOperation = "Restoring photos..."
            try await restorePhotos(references: manifest.contents.photoReferences, from: extractPath)
        }
        
        backupProgress = 0.8
        
        // Restore documents
        if !manifest.contents.documentReferences.isEmpty {
            currentOperation = "Restoring documents..."
            try await restoreDocuments(references: manifest.contents.documentReferences, from: extractPath)
        }
        
        backupProgress = 1.0
        
        // Clean up
        try? fileManager.removeItem(at: tempDirectory)
        
        return manifest.contents
    }
    
    /// Delete backup
    public func deleteBackup(_ info: BackupInfo) throws {
        let backupURL = backupDirectory.appendingPathComponent(info.fileName)
        try fileManager.removeItem(at: backupURL)
        
        availableBackups.removeAll { $0.id == info.id }
        saveAvailableBackups()
    }
    
    /// Get backup file size estimate
    public func estimateBackupSize(
        itemCount: Int,
        photoCount: Int,
        receiptCount: Int,
        compress: Bool = true
    ) -> Int64 {
        // Rough estimates
        let dataSize: Int64 = Int64(itemCount * 1024) // ~1KB per item
        let photoSize: Int64 = Int64(photoCount * 500_000) // ~500KB per photo
        let receiptSize: Int64 = Int64(receiptCount * 200_000) // ~200KB per receipt
        
        let totalSize = dataSize + photoSize + receiptSize
        
        // Compression typically reduces size by 60-80%
        return compress ? Int64(Double(totalSize) * 0.3) : totalSize
    }
    
    /// Export backup to share
    public func exportBackup(_ info: BackupInfo) -> URL {
        backupDirectory.appendingPathComponent(info.fileName)
    }
    
    /// Schedule automatic backup
    public func scheduleAutomaticBackup(interval: BackupInterval) {
        UserDefaults.standard.set(interval.rawValue, forKey: "backup_interval")
        
        // Schedule background task
        // This would use BGTaskScheduler in a real implementation
    }
    
    public enum BackupInterval: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case never = "never"
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .never: return "Never"
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createManifest(
        items: [Item],
        categories: [String],
        locations: [Location],
        collections: [Collection],
        warranties: [Warranty],
        receipts: [Receipt],
        tags: [Tag],
        storageUnits: [StorageUnit],
        budgets: [Budget],
        options: Set<BackupOptions>
    ) async throws -> BackupManifest {
        var photoReferences: [PhotoReference] = []
        var documentReferences: [DocumentReference] = []
        
        // Collect photo references
        if options.contains(.includePhotos) {
            for item in items {
                for (index, imageId) in item.imageIds.enumerated() {
                    photoReferences.append(PhotoReference(
                        id: UUID(),
                        itemId: item.id,
                        fileName: "photos/\(item.id)_\(index).jpg",
                        checksum: "" // Would calculate actual checksum
                    ))
                }
            }
        }
        
        // Collect document references
        if options.contains(.includeReceipts) {
            for receipt in receipts {
                documentReferences.append(DocumentReference(
                    id: UUID(),
                    type: .receipt,
                    relatedId: receipt.id,
                    fileName: "documents/receipts/\(receipt.id).pdf",
                    checksum: ""
                ))
            }
        }
        
        let contents = BackupContents(
            items: items,
            categories: categories,
            locations: locations,
            collections: collections,
            warranties: warranties,
            receipts: receipts,
            tags: tags,
            storageUnits: storageUnits,
            budgets: budgets,
            settings: BackupSettings(
                userPreferences: [:], // Would collect actual preferences
                notificationSettings: [:],
                privacySettings: [:]
            ),
            photoReferences: photoReferences,
            documentReferences: documentReferences
        )
        
        return BackupManifest(
            createdDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            deviceName: await MainActor.run { UIDevice.current.name },
            contents: contents,
            checksum: "" // Will be calculated after archive creation
        )
    }
    
    private func copyPhotos(for items: [Item], to backupPath: URL) async throws {
        let photosDirectory = backupPath.appendingPathComponent("photos", isDirectory: true)
        try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        
        for item in items {
            // In a real app, would load image data from image storage
            // For now, simulate with empty data
            for (index, imageId) in item.imageIds.enumerated() {
                let photoData = Data() // Would fetch actual image data
                let fileName = "\(item.id)_\(index).jpg"
                let photoURL = photosDirectory.appendingPathComponent(fileName)
                try photoData.write(to: photoURL)
            }
        }
    }
    
    private func copyDocuments(receipts: [Receipt], warranties: [Warranty], to backupPath: URL) async throws {
        let documentsDirectory = backupPath.appendingPathComponent("documents", isDirectory: true)
        let receiptsDirectory = documentsDirectory.appendingPathComponent("receipts", isDirectory: true)
        let warrantiesDirectory = documentsDirectory.appendingPathComponent("warranties", isDirectory: true)
        
        try fileManager.createDirectory(at: receiptsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: warrantiesDirectory, withIntermediateDirectories: true)
        
        // Copy receipt files
        for receipt in receipts {
            if let data = receipt.imageData {
                let fileName = "\(receipt.id).pdf"
                let fileURL = receiptsDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
            }
        }
        
        // Copy warranty documents
        for warranty in warranties {
            // In a real app, would load document data from document storage
            // For now, simulate with empty data
            if !warranty.documentIds.isEmpty {
                let fileName = "\(warranty.id).pdf"
                let fileURL = warrantiesDirectory.appendingPathComponent(fileName)
                let documentData = Data() // Would fetch actual document data
                try documentData.write(to: fileURL)
            }
        }
    }
    
    private func createCompressedArchive(from source: URL, to destination: URL) async throws {
        // Would use Compression framework or zip utilities
        // For now, simple file copy
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }
    
    private func createArchive(from source: URL, to destination: URL) async throws {
        // In a real implementation, would create proper archive
        // For now, just copy directory
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }
    
    private func extractCompressedArchive(from source: URL, to destination: URL) async throws {
        // Would use Compression framework or zip utilities
        try fileManager.copyItem(at: source, to: destination)
    }
    
    private func extractArchive(from source: URL, to destination: URL) async throws {
        try fileManager.copyItem(at: source, to: destination)
    }
    
    private func encryptBackup(at url: URL, password: String) async throws {
        // Would implement actual encryption using CryptoKit
        // This is a placeholder
    }
    
    private func decryptBackup(at url: URL, password: String) async throws {
        // Would implement actual decryption using CryptoKit
        // This is a placeholder
    }
    
    private func restorePhotos(references: [PhotoReference], from backupPath: URL) async throws {
        // Would restore photos to appropriate location
    }
    
    private func restoreDocuments(references: [DocumentReference], from backupPath: URL) async throws {
        // Would restore documents to appropriate location
    }
    
    private func calculateChecksum(for url: URL) throws -> String {
        // Would calculate actual checksum using CryptoKit
        return "placeholder_checksum"
    }
    
    private func calculateCompressionRatio(backupPath: URL, archiveSize: Int64) -> Double {
        do {
            let originalSize = try calculateDirectorySize(backupPath)
            return Double(originalSize) / Double(archiveSize)
        } catch {
            return 1.0
        }
    }
    
    private func calculateDirectorySize(_ url: URL) throws -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                size += Int64(fileSize)
            }
        }
        
        return size
    }
    
    // MARK: - Persistence
    
    private func loadAvailableBackups() {
        guard let data = UserDefaults.standard.data(forKey: "available_backups"),
              let backups = try? jsonDecoder.decode([BackupInfo].self, from: data) else {
            return
        }
        availableBackups = backups
    }
    
    private func saveAvailableBackups() {
        guard let data = try? jsonEncoder.encode(availableBackups) else { return }
        UserDefaults.standard.set(data, forKey: "available_backups")
    }
    
    private func saveBackupInfo(_ info: BackupInfo) {
        availableBackups.append(info)
        availableBackups.sort { $0.createdDate > $1.createdDate }
        saveAvailableBackups()
    }
    
    private func loadLastBackupDate() {
        lastBackupDate = UserDefaults.standard.object(forKey: "last_backup_date") as? Date
    }
    
    private func saveLastBackupDate() {
        UserDefaults.standard.set(lastBackupDate, forKey: "last_backup_date")
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}