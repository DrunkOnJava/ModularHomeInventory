import XCTest
@testable import Core
@testable import AppSettings
@testable import TestUtilities

/// Tests for data privacy, redaction, and secure deletion
final class DataPrivacyTests: XCTestCase {
    
    var privacyService: DataPrivacyService!
    var itemService: ItemService!
    var userService: UserService!
    var database: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        database = try await TestDatabase.shared
        privacyService = DataPrivacyService(database: database)
        itemService = ItemService(database: database)
        userService = UserService()
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDown() async throws {
        try await database.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Data Redaction Tests
    
    func testSensitiveDataRedaction() throws {
        let item = TestDataBuilder.createItem(
            name: "MacBook Pro",
            serialNumber: "C02X1234JGH7",
            notes: "Purchased with card ending 4242, PIN: 1234",
            customFields: [
                "SSN": "123-45-6789",
                "License": "DL123456789",
                "Account": "ACC-987654321"
            ]
        )
        
        // Redact sensitive data
        let redactedItem = privacyService.redactSensitiveData(from: item)
        
        // Verify redaction
        XCTAssertEqual(redactedItem.name, "MacBook Pro") // Name not redacted
        XCTAssertEqual(redactedItem.serialNumber, "C02X****JGH7") // Partial redaction
        XCTAssertTrue(redactedItem.notes.contains("****4242")) // Card number redacted
        XCTAssertTrue(redactedItem.notes.contains("PIN: ****")) // PIN redacted
        
        // Verify custom fields redacted
        XCTAssertEqual(redactedItem.customFields["SSN"], "***-**-6789")
        XCTAssertEqual(redactedItem.customFields["License"], "DL*******89")
        XCTAssertEqual(redactedItem.customFields["Account"], "ACC-******21")
    }
    
    func testExportDataRedaction() async throws {
        // Create items with sensitive data
        let items = [
            TestDataBuilder.createItem(
                name: "Credit Card Reader",
                serialNumber: "SN123456",
                notes: "API Key: sk_live_123456789"
            ),
            TestDataBuilder.createItem(
                name: "Security Camera",
                serialNumber: "CAM789012",
                notes: "Password: SecurePass123!"
            )
        ]
        
        for item in items {
            try await itemService.save(item)
        }
        
        // Export with privacy mode
        let exportData = try await privacyService.exportData(
            privacyMode: .redacted,
            includePersonalInfo: false
        )
        
        // Parse export data
        let exportedItems = try JSONDecoder().decode([Item].self, from: exportData)
        
        // Verify sensitive data redacted
        for item in exportedItems {
            XCTAssertFalse(item.notes.contains("sk_live_"))
            XCTAssertFalse(item.notes.contains("SecurePass123!"))
            XCTAssertTrue(item.serialNumber.contains("*"))
        }
    }
    
    func testImagePrivacy() async throws {
        let image = TestDataBuilder.createTestImage(size: CGSize(width: 200, height: 200))
        
        // Add metadata that might contain location
        let imageWithMetadata = TestDataBuilder.addMetadata(
            to: image,
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            timestamp: Date()
        )
        
        // Strip private metadata
        let privateImage = try privacyService.stripPrivateMetadata(from: imageWithMetadata)
        
        // Verify metadata removed
        let metadata = privateImage.cgImage?.metadata
        XCTAssertNil(metadata?[kCGImagePropertyGPSLatitude as String])
        XCTAssertNil(metadata?[kCGImagePropertyGPSLongitude as String])
        XCTAssertNil(metadata?[kCGImagePropertyExifDateTimeOriginal as String])
    }
    
    // MARK: - Secure Deletion Tests
    
    func testSecureItemDeletion() async throws {
        // Create item with sensitive data
        let item = TestDataBuilder.createItem(
            name: "Sensitive Item",
            value: 9999.99,
            serialNumber: "SECRET123",
            notes: "Contains sensitive information"
        )
        
        try await itemService.save(item)
        
        // Attach image
        let image = TestDataBuilder.createTestImage(size: CGSize(width: 100, height: 100))
        let imageData = image.pngData()!
        try await itemService.attachImage(imageData, to: item)
        
        // Perform secure deletion
        try await privacyService.secureDelete(item: item)
        
        // Verify item deleted from database
        let deletedItem = try await itemService.getItem(id: item.id)
        XCTAssertNil(deletedItem)
        
        // Verify associated data wiped
        let imageExists = FileManager.default.fileExists(
            atPath: item.imagePath ?? ""
        )
        XCTAssertFalse(imageExists)
        
        // Verify secure overwrite (check file not recoverable)
        // In a real implementation, this would verify multiple overwrites
    }
    
    func testBulkSecureDeletion() async throws {
        // Create multiple items
        let items = try await createTestItems(count: 50)
        
        // Perform bulk secure deletion
        let progress = privacyService.secureBulkDelete(items: items)
        
        var lastProgress: Double = 0
        for await currentProgress in progress {
            XCTAssertGreaterThanOrEqual(currentProgress, lastProgress)
            lastProgress = currentProgress
        }
        
        XCTAssertEqual(lastProgress, 1.0)
        
        // Verify all items deleted
        for item in items {
            let deleted = try await itemService.getItem(id: item.id)
            XCTAssertNil(deleted)
        }
    }
    
    func testSecureWipeAllData() async throws {
        // Create various data types
        let items = try await createTestItems(count: 20)
        let receipts = try await createTestReceipts(count: 10)
        let backups = try await createTestBackups(count: 5)
        
        // Get initial storage size
        let initialSize = try await privacyService.calculateDataFootprint()
        XCTAssertGreaterThan(initialSize, 0)
        
        // Perform secure wipe
        try await privacyService.secureWipeAllData(
            confirmation: "DELETE_ALL_DATA",
            includeCache: true,
            includeBackups: true
        )
        
        // Verify all data wiped
        let remainingItems = try await itemService.getAllItems()
        XCTAssertEqual(remainingItems.count, 0)
        
        let finalSize = try await privacyService.calculateDataFootprint()
        XCTAssertLessThan(finalSize, initialSize * 0.1) // Allow for some system files
    }
    
    // MARK: - Data Minimization Tests
    
    func testDataRetentionPolicy() async throws {
        // Create old items
        let oldItems = try await (0..<10).asyncMap { i in
            let item = TestDataBuilder.createItem(
                name: "Old Item \(i)",
                createdAt: Date().addingTimeInterval(-400 * 24 * 60 * 60) // 400 days old
            )
            try await itemService.save(item)
            return item
        }
        
        // Create recent items
        let recentItems = try await (0..<10).asyncMap { i in
            let item = TestDataBuilder.createItem(
                name: "Recent Item \(i)",
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days old
            )
            try await itemService.save(item)
            return item
        }
        
        // Apply retention policy (1 year)
        let policy = DataRetentionPolicy(
            maxItemAge: 365 * 24 * 60 * 60, // 1 year
            maxReceiptAge: 7 * 365 * 24 * 60 * 60, // 7 years
            deleteOrArchive: .archive
        )
        
        let archivedCount = try await privacyService.applyRetentionPolicy(policy)
        
        XCTAssertEqual(archivedCount, oldItems.count)
        
        // Verify old items archived
        for item in oldItems {
            let archived = try await itemService.getItem(id: item.id)
            XCTAssertNil(archived) // Removed from main database
            
            let inArchive = try await privacyService.isInArchive(itemId: item.id)
            XCTAssertTrue(inArchive)
        }
        
        // Verify recent items still active
        for item in recentItems {
            let active = try await itemService.getItem(id: item.id)
            XCTAssertNotNil(active)
        }
    }
    
    func testDataMinimization() async throws {
        // Create item with excessive data
        var item = TestDataBuilder.createItem(name: "Test Item")
        item.notes = String(repeating: "A", count: 10000) // 10KB of notes
        item.customFields = Dictionary(
            uniqueKeysWithValues: (0..<100).map { ("field\($0)", "value\($0)") }
        )
        
        try await itemService.save(item)
        
        // Apply data minimization
        let minimized = try await privacyService.minimizeData(for: item)
        
        // Verify data reduced
        XCTAssertLessThan(minimized.notes.count, 1000) // Truncated
        XCTAssertLessThan(minimized.customFields.count, 50) // Limited fields
        
        // Verify essential data preserved
        XCTAssertEqual(minimized.name, item.name)
        XCTAssertEqual(minimized.value, item.value)
        XCTAssertEqual(minimized.id, item.id)
    }
    
    // MARK: - Privacy Controls Tests
    
    func testUserPrivacySettings() async throws {
        let user = try await userService.getCurrentUser()
        
        // Update privacy settings
        try await userService.updatePrivacySettings(
            shareAnalytics: false,
            allowCrashReporting: false,
            enablePersonalization: false,
            shareUsageData: false
        )
        
        // Verify settings applied
        let settings = try await userService.getPrivacySettings()
        XCTAssertFalse(settings.shareAnalytics)
        XCTAssertFalse(settings.allowCrashReporting)
        XCTAssertFalse(settings.enablePersonalization)
        XCTAssertFalse(settings.shareUsageData)
        
        // Verify no analytics data collected
        let analyticsData = try await privacyService.getCollectedAnalytics()
        XCTAssertEqual(analyticsData.count, 0)
    }
    
    func testDataAccessLog() async throws {
        // Enable access logging
        privacyService.enableAccessLogging = true
        
        // Perform various data accesses
        let item = try await createTestItem()
        _ = try await itemService.getItem(id: item.id)
        try await itemService.update(item)
        
        // Export data
        _ = try await privacyService.exportData(privacyMode: .full)
        
        // Get access log
        let accessLog = try await privacyService.getDataAccessLog()
        
        XCTAssertGreaterThan(accessLog.count, 0)
        
        // Verify log entries
        let readAccess = accessLog.first { $0.action == .read }
        XCTAssertNotNil(readAccess)
        XCTAssertEqual(readAccess?.entityId, item.id.uuidString)
        
        let exportAccess = accessLog.first { $0.action == .export }
        XCTAssertNotNil(exportAccess)
        
        // Verify log doesn't contain actual data
        for entry in accessLog {
            XCTAssertNil(entry.dataSnapshot)
        }
    }
    
    // MARK: - GDPR Compliance Tests
    
    func testRightToAccess() async throws {
        // Create user data
        let items = try await createTestItems(count: 10)
        let receipts = try await createTestReceipts(count: 5)
        
        // Request data export (GDPR Article 15)
        let exportPackage = try await privacyService.exportUserData(
            format: .json,
            includeMetadata: true
        )
        
        // Verify comprehensive export
        XCTAssertNotNil(exportPackage.items)
        XCTAssertNotNil(exportPackage.receipts)
        XCTAssertNotNil(exportPackage.metadata)
        
        XCTAssertEqual(exportPackage.items.count, items.count)
        XCTAssertEqual(exportPackage.receipts.count, receipts.count)
        
        // Verify metadata includes processing info
        XCTAssertNotNil(exportPackage.metadata.exportDate)
        XCTAssertNotNil(exportPackage.metadata.dataCategories)
        XCTAssertNotNil(exportPackage.metadata.processingPurposes)
    }
    
    func testRightToErasure() async throws {
        // Create user data
        let items = try await createTestItems(count: 5)
        
        // Request account deletion (GDPR Article 17)
        let deletionRequest = DataDeletionRequest(
            userId: "test-user",
            reason: .userRequest,
            includeBackups: true,
            confirmation: "DELETE_MY_ACCOUNT"
        )
        
        let result = try await privacyService.processDataDeletionRequest(deletionRequest)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.deletionCertificate)
        XCTAssertEqual(result.itemsDeleted, items.count)
        
        // Verify all data deleted
        let remainingItems = try await itemService.getAllItems()
        XCTAssertEqual(remainingItems.count, 0)
        
        // Verify deletion certificate
        XCTAssertNotNil(result.deletionCertificate.timestamp)
        XCTAssertNotNil(result.deletionCertificate.verificationHash)
    }
    
    func testDataPortability() async throws {
        // Create data
        let items = try await createTestItems(count: 10)
        
        // Export in portable format (GDPR Article 20)
        let portableData = try await privacyService.exportPortableData(
            format: .csv,
            includeImages: true
        )
        
        // Verify machine-readable format
        XCTAssertNotNil(portableData.csvData)
        XCTAssertNotNil(portableData.imageArchive)
        
        // Verify can be imported elsewhere
        let csvString = String(data: portableData.csvData, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("name,value,category"))
        XCTAssertEqual(csvString.components(separatedBy: "\n").count - 1, items.count + 1) // +1 for header
    }
    
    // MARK: - Third-Party Sharing Tests
    
    func testThirdPartyDataSharing() async throws {
        // Configure sharing preferences
        try await privacyService.configureDataSharing(
            allowedServices: [.backup, .sync],
            deniedServices: [.analytics, .advertising],
            requireExplicitConsent: true
        )
        
        // Attempt to share with allowed service
        let backupResult = try await privacyService.shareData(
            with: .backup,
            data: Data("test".utf8),
            purpose: .userBackup
        )
        
        XCTAssertTrue(backupResult.allowed)
        
        // Attempt to share with denied service
        do {
            _ = try await privacyService.shareData(
                with: .analytics,
                data: Data("test".utf8),
                purpose: .improvement
            )
            XCTFail("Should not allow sharing with denied service")
        } catch PrivacyError.sharingDenied {
            // Expected
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int) async throws -> [Item] {
        try await (0..<count).asyncMap { i in
            let item = TestDataBuilder.createItem(
                name: "Item \(i)",
                value: Double(i * 100)
            )
            try await itemService.save(item)
            return item
        }
    }
    
    private func createTestReceipts(count: Int) async throws -> [Receipt] {
        try await (0..<count).asyncMap { i in
            Receipt(
                id: UUID(),
                storeName: "Store \(i)",
                date: Date(),
                total: Double(i * 50)
            )
        }
    }
    
    private func createTestBackups(count: Int) async throws -> [Backup] {
        try await (0..<count).asyncMap { i in
            Backup(
                id: UUID(),
                date: Date().addingTimeInterval(Double(-i * 24 * 60 * 60)),
                size: Int64(i * 1024 * 1024)
            )
        }
    }
    
    private func createTestItem() async throws -> Item {
        let item = TestDataBuilder.createItem(name: "Test Item")
        try await itemService.save(item)
        return item
    }
}

// MARK: - Supporting Types

enum PrivacyError: Error {
    case sharingDenied
    case invalidConfirmation
    case dataNotFound
}

struct DataRetentionPolicy {
    enum Action {
        case delete
        case archive
    }
    
    let maxItemAge: TimeInterval
    let maxReceiptAge: TimeInterval
    let deleteOrArchive: Action
}

struct DataAccessLogEntry {
    enum Action {
        case read
        case write
        case delete
        case export
    }
    
    let timestamp: Date
    let action: Action
    let entityType: String
    let entityId: String
    let userId: String?
    let dataSnapshot: Data? // Should be nil for privacy
}

struct DataDeletionRequest {
    enum Reason {
        case userRequest
        case dataRetention
        case legal
    }
    
    let userId: String
    let reason: Reason
    let includeBackups: Bool
    let confirmation: String
}

struct DeletionResult {
    let success: Bool
    let itemsDeleted: Int
    let receiptsDeleted: Int
    let backupsDeleted: Int
    let deletionCertificate: DeletionCertificate
}

struct DeletionCertificate {
    let timestamp: Date
    let userId: String
    let dataCategories: [String]
    let verificationHash: String
}

struct UserDataExportPackage {
    let items: [Item]
    let receipts: [Receipt]
    let images: [Data]
    let metadata: ExportMetadata
}

struct ExportMetadata {
    let exportDate: Date
    let dataCategories: [String]
    let processingPurposes: [String]
    let retentionPeriods: [String: TimeInterval]
}

struct PortableDataExport {
    let csvData: Data
    let jsonData: Data
    let imageArchive: Data?
}

enum DataSharingService {
    case backup
    case sync
    case analytics
    case advertising
}

enum DataSharingPurpose {
    case userBackup
    case synchronization
    case improvement
    case marketing
}

struct DataSharingResult {
    let allowed: Bool
    let service: DataSharingService
    let purpose: DataSharingPurpose
    let consentTimestamp: Date?
}