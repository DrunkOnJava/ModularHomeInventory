import Foundation
import CryptoKit

/// Cloud storage service for documents with encryption
/// Swift 5.9 - No Swift 6 features
public protocol CloudDocumentStorageProtocol {
    /// Upload document to cloud storage
    func uploadDocument(_ data: Data, documentId: UUID, encrypted: Bool) async throws -> CloudDocumentMetadata
    
    /// Download document from cloud storage
    func downloadDocument(documentId: UUID) async throws -> Data
    
    /// Delete document from cloud storage
    func deleteDocument(documentId: UUID) async throws
    
    /// Check if document exists in cloud
    func documentExists(documentId: UUID) async throws -> Bool
    
    /// Get document metadata
    func getDocumentMetadata(documentId: UUID) async throws -> CloudDocumentMetadata?
    
    /// List all documents in cloud
    func listDocuments() async throws -> [CloudDocumentMetadata]
    
    /// Get storage usage info
    func getStorageUsage() async throws -> CloudStorageUsage
    
    /// Sync local document to cloud
    func syncDocument(documentId: UUID, data: Data, encrypted: Bool) async throws
    
    /// Sync all pending documents
    func syncPendingDocuments() async throws
}

/// Cloud document metadata
public struct CloudDocumentMetadata: Codable, Identifiable {
    public var id: UUID { documentId }
    public let documentId: UUID
    public let cloudPath: String
    public let uploadedAt: Date
    public let lastModified: Date
    public let fileSize: Int64
    public let checksum: String
    public let encrypted: Bool
    public let syncStatus: SyncStatus
    
    public enum SyncStatus: String, Codable {
        case synced = "synced"
        case pending = "pending"
        case uploading = "uploading"
        case failed = "failed"
    }
}

/// Generic sync status for UI display
public enum SyncStatus: String, CaseIterable {
    case synced = "synced"
    case pending = "pending"
    case uploading = "uploading"
    case failed = "failed"
    case error = "error"
    case conflict = "conflict"
    case notSynced = "notSynced"
    
    public var color: String {
        switch self {
        case .synced: return "#4CAF50"
        case .pending, .uploading: return "#FF9800"
        case .failed, .error: return "#E91E63"
        case .conflict: return "#F44336"
        case .notSynced: return "#9E9E9E"
        }
    }
    
    public var icon: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .pending: return "arrow.triangle.2.circlepath"
        case .uploading: return "arrow.up.circle.fill"
        case .failed, .error: return "xmark.circle.fill"
        case .conflict: return "exclamationmark.triangle.fill"
        case .notSynced: return "icloud.slash.fill"
        }
    }
}

/// Cloud storage usage information
public struct CloudStorageUsage {
    public let usedBytes: Int64
    public let totalBytes: Int64
    public let documentCount: Int
    
    public var percentageUsed: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    public init(usedBytes: Int64, totalBytes: Int64, documentCount: Int) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.documentCount = documentCount
    }
}

/// iCloud Document Storage Implementation
public final class ICloudDocumentStorage: CloudDocumentStorageProtocol {
    private let containerIdentifier = "iCloud.com.homeinventory.documents"
    private let encryptionKey: SymmetricKey
    private let documentsDirectory: URL
    private let metadataStore: URL
    
    public init() throws {
        // Get iCloud container
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            throw CloudStorageError.iCloudNotAvailable
        }
        
        // Setup directories
        self.documentsDirectory = containerURL.appendingPathComponent("Documents")
        self.metadataStore = containerURL.appendingPathComponent("Metadata")
        
        // Create directories if needed
        try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: metadataStore, withIntermediateDirectories: true)
        
        // Generate or retrieve encryption key
        self.encryptionKey = try Self.getOrCreateEncryptionKey()
    }
    
    public func uploadDocument(_ data: Data, documentId: UUID, encrypted: Bool) async throws -> CloudDocumentMetadata {
        let cloudPath = "documents/\(documentId.uuidString)"
        let fileURL = documentsDirectory.appendingPathComponent(cloudPath)
        
        // Encrypt data if requested
        let dataToUpload = encrypted ? try encryptData(data) : data
        
        // Calculate checksum
        let checksum = SHA256.hash(data: dataToUpload).compactMap { String(format: "%02x", $0) }.joined()
        
        // Write to iCloud
        try dataToUpload.write(to: fileURL)
        
        // Create metadata
        let metadata = CloudDocumentMetadata(
            documentId: documentId,
            cloudPath: cloudPath,
            uploadedAt: Date(),
            lastModified: Date(),
            fileSize: Int64(dataToUpload.count),
            checksum: checksum,
            encrypted: encrypted,
            syncStatus: .synced
        )
        
        // Save metadata
        try await saveMetadata(metadata)
        
        return metadata
    }
    
    public func downloadDocument(documentId: UUID) async throws -> Data {
        guard let metadata = try await getDocumentMetadata(documentId: documentId) else {
            throw CloudStorageError.documentNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(metadata.cloudPath)
        let encryptedData = try Data(contentsOf: fileURL)
        
        // Decrypt if needed
        return metadata.encrypted ? try decryptData(encryptedData) : encryptedData
    }
    
    public func deleteDocument(documentId: UUID) async throws {
        guard let metadata = try await getDocumentMetadata(documentId: documentId) else {
            throw CloudStorageError.documentNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(metadata.cloudPath)
        try FileManager.default.removeItem(at: fileURL)
        
        // Remove metadata
        let metadataURL = metadataStore.appendingPathComponent("\(documentId.uuidString).json")
        try FileManager.default.removeItem(at: metadataURL)
    }
    
    public func documentExists(documentId: UUID) async throws -> Bool {
        let metadata = try await getDocumentMetadata(documentId: documentId)
        return metadata != nil
    }
    
    public func getDocumentMetadata(documentId: UUID) async throws -> CloudDocumentMetadata? {
        let metadataURL = metadataStore.appendingPathComponent("\(documentId.uuidString).json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: metadataURL)
        return try JSONDecoder().decode(CloudDocumentMetadata.self, from: data)
    }
    
    public func listDocuments() async throws -> [CloudDocumentMetadata] {
        let metadataFiles = try FileManager.default.contentsOfDirectory(
            at: metadataStore,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        var documents: [CloudDocumentMetadata] = []
        
        for file in metadataFiles {
            if let data = try? Data(contentsOf: file),
               let metadata = try? JSONDecoder().decode(CloudDocumentMetadata.self, from: data) {
                documents.append(metadata)
            }
        }
        
        return documents.sorted { $0.uploadedAt > $1.uploadedAt }
    }
    
    public func getStorageUsage() async throws -> CloudStorageUsage {
        var totalSize: Int64 = 0
        var documentCount = 0
        
        let documents = try await listDocuments()
        documentCount = documents.count
        totalSize = documents.reduce(0) { $0 + $1.fileSize }
        
        // Get iCloud quota (simplified - in real app would use proper API)
        let totalBytes: Int64 = 5 * 1024 * 1024 * 1024 // 5GB default
        
        return CloudStorageUsage(
            usedBytes: totalSize,
            totalBytes: totalBytes,
            documentCount: documentCount
        )
    }
    
    public func syncDocument(documentId: UUID, data: Data, encrypted: Bool) async throws {
        _ = try await uploadDocument(data, documentId: documentId, encrypted: encrypted)
    }
    
    public func syncPendingDocuments() async throws {
        // In a real implementation, this would sync documents marked as pending
        // For now, this is a placeholder
    }
    
    // MARK: - Private Methods
    
    private func saveMetadata(_ metadata: CloudDocumentMetadata) async throws {
        let metadataURL = metadataStore.appendingPathComponent("\(metadata.documentId.uuidString).json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let encrypted = sealedBox.combined else {
            throw CloudStorageError.encryptionFailed
        }
        return encrypted
    }
    
    private func decryptData(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    private static func getOrCreateEncryptionKey() throws -> SymmetricKey {
        let keychain = KeychainService()
        let keyIdentifier = "com.homeinventory.documents.encryptionKey"
        
        if let keyData = try? keychain.load(key: keyIdentifier) {
            return SymmetricKey(data: keyData)
        } else {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            try keychain.save(keyData, key: keyIdentifier)
            return key
        }
    }
}

/// Cloud storage errors
public enum CloudStorageError: LocalizedError {
    case iCloudNotAvailable
    case documentNotFound
    case uploadFailed
    case downloadFailed
    case encryptionFailed
    case decryptionFailed
    case quotaExceeded
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please check your iCloud settings."
        case .documentNotFound:
            return "Document not found in cloud storage"
        case .uploadFailed:
            return "Failed to upload document"
        case .downloadFailed:
            return "Failed to download document"
        case .encryptionFailed:
            return "Failed to encrypt document"
        case .decryptionFailed:
            return "Failed to decrypt document"
        case .quotaExceeded:
            return "Cloud storage quota exceeded"
        case .networkError:
            return "Network error occurred"
        }
    }
}

/// Simple keychain service for encryption key storage
private final class KeychainService {
    func save(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data else {
            throw KeychainError.loadFailed
        }
        
        return data
    }
    
    enum KeychainError: Error {
        case saveFailed
        case loadFailed
    }
}