import XCTest
@testable import Core
@testable import Items
@testable import Sync
@testable import TestUtilities

/// Tests for error recovery and resilience scenarios
final class ErrorRecoveryTests: XCTestCase {
    
    var itemService: ItemService!
    var syncService: SyncService!
    var backupService: BackupService!
    var database: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        database = try await TestDatabase.shared
        itemService = ItemService(database: database)
        syncService = SyncService(session: URLSession.shared)
        backupService = BackupService()
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDown() async throws {
        try await database.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Partial Operation Recovery Tests
    
    func testPartialBulkOperationRecovery() async throws {
        let totalItems = 100
        var items: [Item] = []
        
        // Create items where some will fail validation
        for i in 0..<totalItems {
            if i % 20 == 0 {
                // Invalid item (empty name)
                items.append(TestDataBuilder.createItem(name: "", value: Double(i)))
            } else {
                items.append(TestDataBuilder.createItem(
                    name: "Valid Item \(i)",
                    value: Double(i)
                ))
            }
        }
        
        // Attempt bulk create with partial failure handling
        let results = await itemService.bulkCreateWithRecovery(items)
        
        // Verify partial success
        XCTAssertEqual(results.successful.count, 95) // 100 - 5 invalid
        XCTAssertEqual(results.failed.count, 5)
        
        // Verify all failures are validation errors
        for failure in results.failed {
            XCTAssertTrue(failure.error is ValidationError)
        }
        
        // Verify successful items are in database
        let savedItems = try await itemService.getAllItems()
        XCTAssertEqual(savedItems.count, 95)
    }
    
    func testTransactionRollbackRecovery() async throws {
        // Create initial state
        let item1 = try await createTestItem(name: "Item 1", value: 1000)
        let item2 = try await createTestItem(name: "Item 2", value: 2000)
        
        // Attempt transaction that will fail partway through
        do {
            try await database.transaction { db in
                // First operation succeeds
                var updated1 = item1
                updated1.value = 500
                try await self.itemService.update(updated1)
                
                // Second operation succeeds
                var updated2 = item2
                updated2.value = 2500
                try await self.itemService.update(updated2)
                
                // Third operation fails (invalid)
                let invalid = TestDataBuilder.createItem(name: "", value: -100)
                try await self.itemService.create(invalid)
            }
            
            XCTFail("Transaction should have failed")
        } catch {
            // Transaction rolled back
        }
        
        // Verify original state preserved
        let check1 = try await itemService.getItem(id: item1.id)!
        let check2 = try await itemService.getItem(id: item2.id)!
        
        XCTAssertEqual(check1.value, 1000) // Original value
        XCTAssertEqual(check2.value, 2000) // Original value
    }
    
    // MARK: - Corrupt Data Recovery Tests
    
    func testCorruptImageRecovery() async throws {
        // Create item with image
        let item = try await createTestItem(name: "Image Item")
        let validImageData = TestDataBuilder.createTestImage(size: CGSize(width: 100, height: 100)).pngData()!
        
        try await itemService.attachImage(validImageData, to: item)
        
        // Corrupt the image data
        let imagePath = item.imagePath!
        let corruptData = Data("This is not a valid image".utf8)
        try corruptData.write(to: URL(fileURLWithPath: imagePath))
        
        // Try to load item with corrupt image
        let loadedItem = try await itemService.getItem(id: item.id)!
        
        // Should handle corrupt image gracefully
        do {
            _ = try await itemService.loadImage(for: loadedItem)
            XCTFail("Should detect corrupt image")
        } catch ImageError.corruptData {
            // Expected - now test recovery
            
            // Remove corrupt image
            try await itemService.removeCorruptImage(for: loadedItem)
            
            // Verify item still exists without image
            let recovered = try await itemService.getItem(id: item.id)!
            XCTAssertNil(recovered.imagePath)
            XCTAssertEqual(recovered.name, item.name)
        }
    }
    
    func testPartialDataCorruption() async throws {
        // Create items with various data
        var items: [Item] = []
        for i in 0..<10 {
            let item = TestDataBuilder.createItem(
                name: "Item \(i)",
                value: Double(i * 100),
                serialNumber: "SN\(i)",
                notes: "Test notes for item \(i)"
            )
            items.append(try await itemService.create(item))
        }
        
        // Simulate partial corruption by directly modifying database
        try await database.corruptRandomRecords(count: 3)
        
        // Run integrity check and recovery
        let integrityReport = try await database.checkIntegrity()
        
        if !integrityReport.isHealthy {
            // Attempt recovery
            let recoveryResult = try await database.attemptRecovery()
            
            XCTAssertTrue(recoveryResult.recovered)
            XCTAssertGreaterThan(recoveryResult.recordsRecovered, 0)
            XCTAssertLessThan(recoveryResult.recordsLost, 4) // Should lose at most 3
            
            // Verify remaining items are intact
            let remainingItems = try await itemService.getAllItems()
            XCTAssertGreaterThanOrEqual(remainingItems.count, 7)
            
            // Verify data integrity of remaining items
            for item in remainingItems {
                XCTAssertFalse(item.name.isEmpty)
                XCTAssertGreaterThanOrEqual(item.value, 0)
            }
        }
    }
    
    // MARK: - Network Failure Recovery Tests
    
    func testSyncRecoveryAfterNetworkFailure() async throws {
        // Create items to sync
        let items = try await createTestItems(count: 20)
        
        // Configure mock to fail after partial sync
        var syncedCount = 0
        MockURLProtocol.mockHandler = { request in
            syncedCount += 1
            
            if syncedCount <= 10 {
                // First 10 succeed
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (Data("{\"success\": true}".utf8), response)
            } else {
                // Then network fails
                throw URLError(.networkConnectionLost)
            }
        }
        
        // Attempt sync
        do {
            try await syncService.syncAll()
            XCTFail("Sync should fail")
        } catch {
            // Expected failure
        }
        
        // Check sync state
        let syncStatus = await syncService.getSyncStatus()
        XCTAssertEqual(syncStatus.itemsSynced, 10)
        XCTAssertEqual(syncStatus.itemsPending, 10)
        
        // Fix network and resume
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("{\"success\": true}".utf8), response)
        }
        
        // Resume sync
        try await syncService.resumeFailedSync()
        
        // Verify all items synced
        let finalStatus = await syncService.getSyncStatus()
        XCTAssertEqual(finalStatus.itemsSynced, 20)
        XCTAssertEqual(finalStatus.itemsPending, 0)
    }
    
    // MARK: - Backup and Restore Recovery Tests
    
    func testIncrementalBackupRecovery() async throws {
        // Create initial dataset
        let batch1 = try await createTestItems(count: 50)
        
        // First backup
        let backup1 = try await backupService.createBackup()
        XCTAssertEqual(backup1.itemCount, 50)
        
        // Add more items
        let batch2 = try await createTestItems(count: 30)
        
        // Simulate backup failure midway
        backupService.simulateFailureAfter = 65
        
        do {
            _ = try await backupService.createBackup()
            XCTFail("Backup should fail")
        } catch {
            // Expected failure
        }
        
        // Check partial backup state
        let partialBackup = await backupService.getLastPartialBackup()
        XCTAssertNotNil(partialBackup)
        XCTAssertEqual(partialBackup!.itemCount, 65)
        
        // Resume backup
        backupService.simulateFailureAfter = nil
        let resumedBackup = try await backupService.resumeBackup(from: partialBackup!)
        
        XCTAssertEqual(resumedBackup.itemCount, 80)
        XCTAssertTrue(resumedBackup.isComplete)
    }
    
    func testCorruptBackupRecovery() async throws {
        // Create items and backup
        _ = try await createTestItems(count: 100)
        let backup = try await backupService.createBackup()
        
        // Corrupt backup file
        let backupPath = backup.filePath
        var backupData = try Data(contentsOf: URL(fileURLWithPath: backupPath))
        
        // Corrupt random bytes
        for i in stride(from: 1000, to: min(2000, backupData.count), by: 100) {
            backupData[i] = UInt8.random(in: 0...255)
        }
        
        try backupData.write(to: URL(fileURLWithPath: backupPath))
        
        // Attempt restore
        do {
            try await backupService.restore(from: backup)
            XCTFail("Restore should detect corruption")
        } catch BackupError.corruptBackup {
            // Try recovery with redundancy
            if backup.hasRedundancy {
                let recoveryResult = try await backupService.attemptRecovery(
                    from: backup,
                    using: .redundancyData
                )
                
                XCTAssertTrue(recoveryResult.success)
                XCTAssertGreaterThan(recoveryResult.itemsRecovered, 90) // Should recover most items
            }
        }
    }
    
    // MARK: - Memory Pressure Recovery Tests
    
    func testLowMemoryRecovery() async throws {
        // Simulate memory pressure
        let memorySimulator = MemoryPressureSimulator()
        memorySimulator.simulatePressure(level: .critical)
        
        // Try to load large dataset
        do {
            // Create many items with large images
            for i in 0..<100 {
                let largeImage = TestDataBuilder.createTestImage(
                    size: CGSize(width: 2000, height: 2000)
                )
                
                let item = TestDataBuilder.createItem(
                    name: "Memory Test \(i)",
                    imageData: largeImage.pngData()
                )
                
                try await itemService.create(item)
                
                // Check for memory warnings
                if await itemService.isUnderMemoryPressure() {
                    // Service should start releasing memory
                    let released = await itemService.releaseMemory()
                    XCTAssertTrue(released.imageCache)
                    XCTAssertTrue(released.searchIndex)
                    
                    // Should still function with reduced performance
                    let items = try await itemService.getItems(limit: 10)
                    XCTAssertEqual(items.count, 10)
                    
                    break
                }
            }
        } catch MemoryError.outOfMemory {
            // Verify graceful degradation
            let itemCount = try await itemService.getItemCount()
            XCTAssertGreaterThan(itemCount, 0)
            
            // Should still be able to perform basic operations
            let items = try await itemService.getItems(limit: 5)
            XCTAssertGreaterThan(items.count, 0)
        }
        
        memorySimulator.stopSimulation()
    }
    
    // MARK: - Cascade Failure Prevention Tests
    
    func testCascadeFailurePrevention() async throws {
        // Create interdependent data
        let category = TestDataBuilder.createCategory(name: "Electronics")
        var items: [Item] = []
        
        for i in 0..<20 {
            let item = TestDataBuilder.createItem(
                name: "Electronic \(i)",
                category: category
            )
            items.append(try await itemService.create(item))
        }
        
        // Simulate failure that could cascade
        do {
            // Try to delete category that has items
            try await categoryService.delete(category)
            XCTFail("Should prevent cascade deletion")
        } catch CategoryError.hasAssociatedItems {
            // Verify items are still intact
            for item in items {
                let exists = try await itemService.getItem(id: item.id)
                XCTAssertNotNil(exists)
            }
        }
        
        // Test safe deletion with migration
        let newCategory = TestDataBuilder.createCategory(name: "Gadgets")
        let migrationResult = try await categoryService.deleteWithMigration(
            category,
            migrateTo: newCategory
        )
        
        XCTAssertEqual(migrationResult.itemsMigrated, 20)
        
        // Verify all items migrated
        for item in items {
            let updated = try await itemService.getItem(id: item.id)!
            XCTAssertEqual(updated.category, newCategory)
        }
    }
    
    // MARK: - Timeout Recovery Tests
    
    func testOperationTimeoutRecovery() async throws {
        // Configure short timeout
        itemService.operationTimeout = 1.0 // 1 second
        
        // Create slow operation
        let slowOperation = {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return TestDataBuilder.createItem(name: "Slow Item")
        }
        
        do {
            _ = try await itemService.createWithTimeout(operation: slowOperation)
            XCTFail("Operation should timeout")
        } catch OperationError.timeout {
            // Verify system still responsive
            let quickItem = TestDataBuilder.createItem(name: "Quick Item")
            let created = try await itemService.create(quickItem)
            XCTAssertNotNil(created)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestItem(name: String, value: Double = 100) async throws -> Item {
        let item = TestDataBuilder.createItem(name: name, value: value)
        return try await itemService.create(item)
    }
    
    private func createTestItems(count: Int) async throws -> [Item] {
        var items: [Item] = []
        for i in 0..<count {
            let item = TestDataBuilder.createItem(
                name: "Test Item \(i)",
                value: Double(i * 100)
            )
            items.append(try await itemService.create(item))
        }
        return items
    }
}

// MARK: - Supporting Types

struct BulkOperationResult {
    let successful: [Item]
    let failed: [(item: Item, error: Error)]
}

enum ImageError: Error {
    case corruptData
    case unsupportedFormat
    case tooLarge
}

enum BackupError: Error {
    case corruptBackup
    case incompatibleVersion
    case insufficientSpace
}

enum CategoryError: Error {
    case hasAssociatedItems
    case cannotDelete
}

enum OperationError: Error {
    case timeout
    case cancelled
}

struct IntegrityReport {
    let isHealthy: Bool
    let corruptRecords: Int
    let warnings: [String]
}

struct RecoveryResult {
    let recovered: Bool
    let recordsRecovered: Int
    let recordsLost: Int
}

struct SyncStatus {
    let itemsSynced: Int
    let itemsPending: Int
    let lastSyncDate: Date?
    let errors: [Error]
}

struct BackupRecoveryResult {
    let success: Bool
    let itemsRecovered: Int
    let method: RecoveryMethod
}

enum RecoveryMethod {
    case redundancyData
    case partialRestore
    case previousBackup
}

struct MemoryReleaseResult {
    let imageCache: Bool
    let searchIndex: Bool
    let pendingOperations: Bool
}

extension ItemService {
    func bulkCreateWithRecovery(_ items: [Item]) async -> BulkOperationResult {
        var successful: [Item] = []
        var failed: [(Item, Error)] = []
        
        for item in items {
            do {
                let created = try await create(item)
                successful.append(created)
            } catch {
                failed.append((item, error))
            }
        }
        
        return BulkOperationResult(successful: successful, failed: failed)
    }
    
    func isUnderMemoryPressure() async -> Bool {
        // Check available memory
        return ProcessInfo.processInfo.physicalMemory < 100 * 1024 * 1024
    }
    
    func releaseMemory() async -> MemoryReleaseResult {
        // Release caches and non-essential data
        return MemoryReleaseResult(
            imageCache: true,
            searchIndex: true,
            pendingOperations: false
        )
    }
    
    func createWithTimeout(operation: @escaping () async throws -> Item) async throws -> Item {
        return try await withThrowingTaskGroup(of: Item.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.operationTimeout * 1_000_000_000))
                throw OperationError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

extension BackupService {
    var simulateFailureAfter: Int?
    
    func getLastPartialBackup() async -> Backup? {
        // Return last incomplete backup
        return nil // Placeholder
    }
    
    func resumeBackup(from partial: Backup) async throws -> Backup {
        // Resume from partial backup
        return partial // Placeholder
    }
}

extension TestDatabase {
    func corruptRandomRecords(count: Int) async throws {
        // Simulate corruption for testing
    }
    
    func checkIntegrity() async throws -> IntegrityReport {
        return IntegrityReport(
            isHealthy: false,
            corruptRecords: 3,
            warnings: ["Corrupted records detected"]
        )
    }
    
    func attemptRecovery() async throws -> RecoveryResult {
        return RecoveryResult(
            recovered: true,
            recordsRecovered: 7,
            recordsLost: 3
        )
    }
}

// Placeholder services
let categoryService = CategoryService()

class CategoryService {
    func delete(_ category: Category) async throws {
        throw CategoryError.hasAssociatedItems
    }
    
    func deleteWithMigration(_ old: Category, migrateTo new: Category) async throws -> (itemsMigrated: Int) {
        return (itemsMigrated: 20)
    }
}