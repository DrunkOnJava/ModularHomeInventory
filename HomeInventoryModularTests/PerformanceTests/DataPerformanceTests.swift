import XCTest
@testable import Core
@testable import Items
@testable import TestUtilities

/// Performance tests for data operations
final class DataPerformanceTests: PerformanceTestCase {
    
    var itemService: ItemService!
    var searchService: SearchService!
    var testDatabase: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        
        testDatabase = await TestDatabase.inMemory()
        itemService = ItemService(database: testDatabase)
        searchService = SearchService()
    }
    
    override func tearDown() async throws {
        try await testDatabase.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Data Loading Tests
    
    func testLargeDatasetLoading() async throws {
        // Create test data
        let items = TestDataBuilder.createItems(count: 1000)
        
        // Pre-populate database
        for item in items {
            _ = try await itemService.create(item: item)
        }
        
        // Measure loading performance
        await measureAsync(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let loadedItems = try await self.itemService.getAllItems()
            XCTAssertEqual(loadedItems.count, 1000)
        }
    }
    
    func testIncrementalDataLoading() async throws {
        // Create large dataset
        let totalItems = 5000
        for i in 0..<totalItems {
            _ = try await itemService.create(
                name: "Item \(i)",
                value: Double(i)
            )
        }
        
        // Measure paginated loading
        await measureAsync {
            var loadedCount = 0
            let pageSize = 50
            
            while loadedCount < totalItems {
                let items = try await self.itemService.getItems(
                    offset: loadedCount,
                    limit: pageSize
                )
                loadedCount += items.count
                
                if items.isEmpty {
                    break
                }
            }
            
            XCTAssertEqual(loadedCount, totalItems)
        }
    }
    
    // MARK: - Search Performance Tests
    
    func testSearchPerformance() async throws {
        // Pre-index items
        let itemCount = 10000
        let items = TestDataBuilder.createItems(count: itemCount)
        await searchService.indexItems(items)
        
        // Test various search queries
        let queries = [
            "test",
            "item 999",
            "electronics",
            "value:>500",
            "created:today"
        ]
        
        measure(metrics: [XCTClockMetric()]) {
            for query in queries {
                let results = self.searchService.search(query: query)
                XCTAssertNotNil(results)
            }
        }
    }
    
    func testSearchIndexingPerformance() async throws {
        let items = TestDataBuilder.createItems(count: 5000)
        
        await measureAsync {
            await self.searchService.indexItems(items)
            
            // Verify indexing worked
            let results = self.searchService.search(query: "Item")
            XCTAssertGreaterThan(results.count, 0)
        }
    }
    
    func testComplexQueryPerformance() async throws {
        // Create diverse dataset
        let items = (0..<1000).map { i in
            TestDataBuilder.createItem(
                name: "Item \(i)",
                value: Double(i * 10),
                category: Category.allCases[i % Category.allCases.count],
                notes: i % 2 == 0 ? "Special item with warranty" : nil
            )
        }
        
        await searchService.indexItems(items)
        
        // Complex query with multiple filters
        let complexQuery = "category:electronics value:>1000 warranty:active sort:value-desc"
        
        measure {
            let results = self.searchService.search(query: complexQuery)
            XCTAssertNotNil(results)
        }
    }
    
    // MARK: - Database Performance Tests
    
    func testBatchInsertPerformance() async throws {
        let items = TestDataBuilder.createItems(count: 1000)
        
        await measureAsync {
            try await self.itemService.batchInsert(items)
            
            let count = try await self.itemService.getItemCount()
            XCTAssertEqual(count, 1000)
        }
    }
    
    func testConcurrentDatabaseAccess() async throws {
        let concurrentOperations = 100
        
        await measureAsync {
            await withTaskGroup(of: Item?.self) { group in
                // Concurrent writes
                for i in 0..<concurrentOperations {
                    group.addTask {
                        try? await self.itemService.create(
                            name: "Concurrent Item \(i)",
                            value: Double(i)
                        )
                    }
                }
                
                // Concurrent reads
                for _ in 0..<concurrentOperations {
                    group.addTask {
                        try? await self.itemService.getAllItems().first
                    }
                }
                
                // Wait for all operations
                var successCount = 0
                for await result in group {
                    if result != nil {
                        successCount += 1
                    }
                }
                
                XCTAssertGreaterThan(successCount, 0)
            }
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageWithLargeImages() async throws {
        let imageSize = 4 // MB per image
        let itemCount = 100
        
        let startMemory = getMemoryUsage()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Create items with large images
            let items = (0..<itemCount).map { i in
                let image = TestDataBuilder.createLargeTestImage(sizeMB: imageSize)
                return TestDataBuilder.createItem(
                    name: "Item with Image \(i)",
                    images: [image]
                )
            }
            
            // Simulate processing
            _ = items.compactMap { item in
                item.images.first?.count
            }
        }
        
        let endMemory = getMemoryUsage()
        let memoryGrowth = endMemory - startMemory
        
        print("Memory growth: \(formatBytes(memoryGrowth))")
        
        // Ensure reasonable memory usage
        XCTAssertLessThan(
            memoryGrowth,
            Int64(itemCount * imageSize * 2 * 1024 * 1024),
            "Memory usage exceeded expected bounds"
        )
    }
    
    // MARK: - Export Performance Tests
    
    func testCSVExportPerformance() async throws {
        // Create dataset
        let items = TestDataBuilder.createItems(count: 5000)
        for item in items {
            _ = try await itemService.create(item: item)
        }
        
        let exportService = CSVExportService()
        
        await measureAsync {
            let csvData = try await exportService.exportItems(items)
            XCTAssertGreaterThan(csvData.count, 0)
            
            // Verify CSV is valid
            let csvString = String(data: csvData, encoding: .utf8)!
            let lines = csvString.components(separatedBy: .newlines)
            XCTAssertEqual(lines.count - 1, items.count) // -1 for header
        }
    }
}