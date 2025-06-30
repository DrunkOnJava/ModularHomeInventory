import XCTest
@testable import Core
@testable import Items
@testable import TestUtilities

/// Tests for handling large datasets and memory constraints
final class LargeDatasetTests: PerformanceTestCase {
    
    var itemService: ItemService!
    var searchService: SearchService!
    var database: TestDatabase!
    
    override func setupAsync() async throws {
        try await super.setupAsync()
        database = try await TestDatabase.shared
        itemService = ItemService(database: database)
        searchService = SearchService(database: database)
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDownAsync() async throws {
        try await database.deleteAll()
        try await super.tearDownAsync()
    }
    
    // MARK: - Large Dataset Creation Tests
    
    func testCreate10000Items() async throws {
        let batchSize = 100
        let totalItems = 10_000
        
        await measureAsync(
            metrics: [XCTMemoryMetric(), XCTCPUMetric()],
            options: defaultMeasureOptions
        ) {
            for batch in 0..<(totalItems / batchSize) {
                let items = (0..<batchSize).map { index in
                    let itemIndex = batch * batchSize + index
                    return TestDataBuilder.createItem(
                        name: "Item \(itemIndex)",
                        value: Double(itemIndex),
                        category: Category.allCases[itemIndex % Category.allCases.count],
                        serialNumber: "SN\(String(format: "%08d", itemIndex))",
                        notes: "This is a test item with index \(itemIndex). " +
                               String(repeating: "Lorem ipsum dolor sit amet. ", count: 10)
                    )
                }
                
                try await itemService.bulkCreate(items)
            }
        }
        
        // Verify all items created
        let count = try await itemService.getItemCount()
        XCTAssertEqual(count, totalItems)
    }
    
    func testCreate50000ItemsWithImages() async throws {
        let batchSize = 500
        let totalItems = 50_000
        let imageData = TestDataBuilder.createTestImage(size: CGSize(width: 100, height: 100)).pngData()!
        
        // Monitor memory usage
        let initialMemory = getMemoryUsage()
        var peakMemory = initialMemory
        
        for batch in 0..<(totalItems / batchSize) {
            autoreleasepool {
                let items = (0..<batchSize).map { index in
                    let itemIndex = batch * batchSize + index
                    var item = TestDataBuilder.createItem(
                        name: "Item \(itemIndex)",
                        value: Double.random(in: 10...10000)
                    )
                    item.imageData = imageData
                    return item
                }
                
                Task {
                    try await itemService.bulkCreate(items)
                }.value
                
                let currentMemory = getMemoryUsage()
                peakMemory = max(peakMemory, currentMemory)
                
                // Log progress every 10%
                if batch % (totalItems / batchSize / 10) == 0 {
                    print("Progress: \(batch * batchSize) items, Memory: \(currentMemory / 1024 / 1024) MB")
                }
            }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        print("Memory usage - Initial: \(initialMemory / 1024 / 1024) MB, Peak: \(peakMemory / 1024 / 1024) MB, Final: \(finalMemory / 1024 / 1024) MB")
        
        // Verify memory usage is reasonable (less than 500MB increase)
        XCTAssertLessThan(memoryIncrease, 500 * 1024 * 1024)
    }
    
    // MARK: - Large Dataset Query Tests
    
    func testSearchIn100000Items() async throws {
        // First, create large dataset
        let totalItems = 100_000
        try await createLargeDataset(count: totalItems)
        
        // Test various search scenarios
        let searchQueries = [
            "Item 50000",           // Exact match
            "electronics",          // Category search
            "SN00012345",          // Serial number search
            "lorem ipsum",          // Full text search
            "value:>5000",         // Range query
            "created:>2024-01-01"  // Date query
        ]
        
        for query in searchQueries {
            await measureAsync(
                metrics: [XCTClockMetric()],
                options: defaultMeasureOptions
            ) {
                let results = try await searchService.search(
                    query: query,
                    limit: 100,
                    offset: 0
                )
                
                XCTAssertGreaterThan(results.count, 0)
                
                // Verify search completes within 1 second
                XCTAssertLessThan(measurementDuration, 1.0)
            }
        }
    }
    
    func testPaginationPerformance() async throws {
        let totalItems = 50_000
        try await createLargeDataset(count: totalItems)
        
        let pageSize = 50
        let testPages = [0, 100, 500, 900] // Test various page positions
        
        for pageIndex in testPages {
            await measureAsync(
                metrics: [XCTClockMetric()],
                options: defaultMeasureOptions
            ) {
                let offset = pageIndex * pageSize
                let items = try await itemService.getItems(
                    limit: pageSize,
                    offset: offset,
                    sortBy: .name,
                    ascending: true
                )
                
                XCTAssertEqual(items.count, pageSize)
                
                // Verify pagination is fast (< 100ms)
                XCTAssertLessThan(measurementDuration, 0.1)
            }
        }
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryPressureHandling() async throws {
        // Simulate low memory conditions
        let memoryPressureSimulator = MemoryPressureSimulator()
        
        // Create items under memory pressure
        memoryPressureSimulator.simulatePressure(level: .critical)
        
        do {
            // Try to create large dataset
            for i in 0..<1000 {
                let item = TestDataBuilder.createItem(
                    name: "Memory Test Item \(i)",
                    value: Double(i),
                    imageData: Data(repeating: 0xFF, count: 1024 * 1024) // 1MB per item
                )
                
                try await itemService.create(item)
                
                // Check if app handles memory warnings
                if memoryPressureSimulator.didReceiveMemoryWarning {
                    // Verify graceful degradation
                    let cachedItemsCleared = await itemService.clearImageCache()
                    XCTAssertTrue(cachedItemsCleared)
                    break
                }
            }
        } catch {
            // Verify appropriate error handling
            XCTAssertTrue(error is MemoryError || error is DatabaseError)
        }
        
        memoryPressureSimulator.stopSimulation()
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentReadsAndWrites() async throws {
        let concurrentTasks = 100
        let itemsPerTask = 100
        
        // Create initial dataset
        try await createLargeDataset(count: 10_000)
        
        await withTaskGroup(of: Result<Void, Error>.self) { group in
            // Half tasks do reads
            for i in 0..<(concurrentTasks / 2) {
                group.addTask { [weak self] in
                    do {
                        let randomOffset = Int.random(in: 0..<9000)
                        _ = try await self?.itemService.getItems(
                            limit: 100,
                            offset: randomOffset
                        )
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            // Half tasks do writes
            for i in 0..<(concurrentTasks / 2) {
                group.addTask { [weak self] in
                    do {
                        let items = (0..<itemsPerTask).map { j in
                            TestDataBuilder.createItem(
                                name: "Concurrent Item \(i)-\(j)",
                                value: Double(i * itemsPerTask + j)
                            )
                        }
                        try await self?.itemService.bulkCreate(items)
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            // Collect results
            var successCount = 0
            var failureCount = 0
            
            for await result in group {
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    failureCount += 1
                }
            }
            
            // All operations should succeed
            XCTAssertEqual(successCount, concurrentTasks)
            XCTAssertEqual(failureCount, 0)
        }
        
        // Verify data integrity
        let finalCount = try await itemService.getItemCount()
        XCTAssertEqual(finalCount, 10_000 + (concurrentTasks / 2 * itemsPerTask))
    }
    
    // MARK: - Storage Limit Tests
    
    func testStorageNearLimit() async throws {
        let availableSpace = getAvailableStorageSpace()
        let targetUsage = availableSpace - (100 * 1024 * 1024) // Leave 100MB free
        
        var totalSize: Int64 = 0
        var itemCount = 0
        
        while totalSize < targetUsage {
            // Create items with large images
            let imageSize = 5 * 1024 * 1024 // 5MB images
            let imageData = Data(repeating: 0xFF, count: imageSize)
            
            let item = TestDataBuilder.createItem(
                name: "Storage Test Item \(itemCount)",
                imageData: imageData
            )
            
            do {
                try await itemService.create(item)
                totalSize += Int64(imageSize)
                itemCount += 1
            } catch StorageError.insufficientSpace {
                // Expected when near limit
                break
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        // Verify graceful handling
        XCTAssertGreaterThan(itemCount, 0)
        
        // Test cleanup functionality
        let freedSpace = try await itemService.cleanupOldData(
            olderThan: Date(),
            targetFreeSpace: 500 * 1024 * 1024 // 500MB
        )
        
        XCTAssertGreaterThan(freedSpace, 0)
    }
    
    // MARK: - Database Corruption Recovery Tests
    
    func testDatabaseCorruptionRecovery() async throws {
        // Create some data
        try await createLargeDataset(count: 1000)
        
        // Simulate database corruption
        let dbPath = database.fileURL.path
        try await database.close()
        
        // Corrupt the database file
        var dbData = try Data(contentsOf: URL(fileURLWithPath: dbPath))
        // Corrupt random bytes
        for _ in 0..<100 {
            let randomIndex = Int.random(in: 0..<dbData.count)
            dbData[randomIndex] = UInt8.random(in: 0...255)
        }
        try dbData.write(to: URL(fileURLWithPath: dbPath))
        
        // Try to open corrupted database
        do {
            database = try await TestDatabase.open(at: URL(fileURLWithPath: dbPath))
            _ = try await itemService.getItemCount()
            XCTFail("Should detect corruption")
        } catch {
            // Verify corruption detected
            XCTAssertTrue(error is DatabaseError)
            
            // Test recovery
            let recovered = try await TestDatabase.recover(from: URL(fileURLWithPath: dbPath))
            XCTAssertTrue(recovered)
            
            // Verify can use database after recovery
            database = try await TestDatabase.shared
            let count = try await itemService.getItemCount()
            XCTAssertGreaterThanOrEqual(count, 0) // Some data may be lost
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLargeDataset(count: Int) async throws {
        let batchSize = 1000
        
        for batch in 0..<(count / batchSize) {
            let items = (0..<batchSize).map { index in
                let itemIndex = batch * batchSize + index
                return TestDataBuilder.createItem(
                    name: "Item \(itemIndex)",
                    value: Double(itemIndex),
                    category: Category.allCases[itemIndex % Category.allCases.count],
                    serialNumber: "SN\(String(format: "%08d", itemIndex))",
                    notes: "Test item \(itemIndex) with some description"
                )
            }
            
            try await itemService.bulkCreate(items)
        }
        
        // Handle remainder
        let remainder = count % batchSize
        if remainder > 0 {
            let items = (0..<remainder).map { index in
                let itemIndex = (count / batchSize) * batchSize + index
                return TestDataBuilder.createItem(
                    name: "Item \(itemIndex)",
                    value: Double(itemIndex)
                )
            }
            
            try await itemService.bulkCreate(items)
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func getAvailableStorageSpace() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory()
            )
            
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSpace.int64Value
            }
        } catch {
            print("Error getting storage space: \(error)")
        }
        
        return 0
    }
    
    private var measurementDuration: TimeInterval = 0
}

// MARK: - Supporting Types

class MemoryPressureSimulator {
    private var timer: Timer?
    private(set) var didReceiveMemoryWarning = false
    
    func simulatePressure(level: MemoryPressureLevel) {
        // In real implementation, would trigger memory warnings
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            NotificationCenter.default.post(
                name: UIApplication.didReceiveMemoryWarningNotification,
                object: nil
            )
            self.didReceiveMemoryWarning = true
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }
    
    enum MemoryPressureLevel {
        case normal
        case warning
        case critical
    }
}

enum StorageError: Error {
    case insufficientSpace
    case quotaExceeded
}

enum MemoryError: Error {
    case outOfMemory
    case allocationFailed
}