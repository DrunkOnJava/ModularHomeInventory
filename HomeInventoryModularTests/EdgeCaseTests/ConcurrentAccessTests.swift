import XCTest
@testable import Core
@testable import Items
@testable import Sync
@testable import TestUtilities

/// Tests for concurrent access patterns and race conditions
final class ConcurrentAccessTests: XCTestCase {
    
    var itemService: ItemService!
    var syncService: SyncService!
    var database: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        database = try await TestDatabase.shared
        itemService = ItemService(database: database)
        syncService = SyncService(session: URLSession.shared)
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDown() async throws {
        try await database.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Concurrent Read/Write Tests
    
    func testConcurrentReadsWhileWriting() async throws {
        // Create initial dataset
        let initialItems = try await createTestItems(count: 100)
        
        // Start continuous writes
        let writeTask = Task {
            for i in 0..<50 {
                let item = TestDataBuilder.createItem(
                    name: "Concurrent Write \(i)",
                    value: Double(i)
                )
                try await self.itemService.create(item)
                
                // Small delay to spread writes
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        // Perform concurrent reads
        let readTasks = (0..<10).map { taskId in
            Task {
                var successfulReads = 0
                
                for _ in 0..<20 {
                    // Random read operations
                    let randomId = initialItems.randomElement()!.id
                    
                    if let item = try await self.itemService.getItem(id: randomId) {
                        XCTAssertEqual(item.id, randomId)
                        successfulReads += 1
                    }
                    
                    // Also do range queries
                    let items = try await self.itemService.getItems(
                        limit: 10,
                        offset: Int.random(in: 0..<90)
                    )
                    XCTAssertGreaterThan(items.count, 0)
                    
                    try await Task.sleep(nanoseconds: 5_000_000) // 5ms
                }
                
                return successfulReads
            }
        }
        
        // Wait for all operations
        try await writeTask.value
        
        let readResults = try await withThrowingTaskGroup(of: Int.self) { group in
            for task in readTasks {
                group.addTask { try await task.value }
            }
            
            var totalReads = 0
            for try await reads in group {
                totalReads += reads
            }
            return totalReads
        }
        
        // Verify all reads succeeded
        XCTAssertEqual(readResults, 200) // 10 tasks * 20 reads each
        
        // Verify final state
        let finalCount = try await itemService.getItemCount()
        XCTAssertEqual(finalCount, 150) // 100 initial + 50 written
    }
    
    func testConcurrentUpdatesToSameItem() async throws {
        // Create test item
        let item = try await createTestItem()
        let itemId = item.id
        
        // Track update results
        actor UpdateTracker {
            var successCount = 0
            var failureCount = 0
            var conflicts = 0
            
            func recordSuccess() {
                successCount += 1
            }
            
            func recordFailure() {
                failureCount += 1
            }
            
            func recordConflict() {
                conflicts += 1
            }
            
            func getResults() -> (success: Int, failure: Int, conflicts: Int) {
                return (successCount, failureCount, conflicts)
            }
        }
        
        let tracker = UpdateTracker()
        
        // Concurrent update tasks
        let updateTasks = (0..<20).map { taskId in
            Task {
                do {
                    // Fetch current version
                    guard var currentItem = try await self.itemService.getItem(id: itemId) else {
                        await tracker.recordFailure()
                        return
                    }
                    
                    // Make different modifications
                    switch taskId % 4 {
                    case 0:
                        currentItem.value = Double(taskId * 100)
                    case 1:
                        currentItem.notes = "Updated by task \(taskId)"
                    case 2:
                        currentItem.category = Category.allCases.randomElement()!
                    case 3:
                        currentItem.location = "Location \(taskId)"
                    default:
                        break
                    }
                    
                    // Try to update with optimistic locking
                    try await self.itemService.updateWithOptimisticLock(currentItem)
                    await tracker.recordSuccess()
                    
                } catch ConcurrencyError.optimisticLockFailure {
                    await tracker.recordConflict()
                } catch {
                    await tracker.recordFailure()
                }
            }
        }
        
        // Wait for all updates
        for task in updateTasks {
            await task.value
        }
        
        let results = await tracker.getResults()
        
        // Some updates should succeed, some should conflict
        XCTAssertGreaterThan(results.success, 0)
        XCTAssertGreaterThan(results.conflicts, 0)
        XCTAssertEqual(results.success + results.conflicts, 20)
        
        // Verify item still exists and is valid
        let finalItem = try await itemService.getItem(id: itemId)!
        XCTAssertEqual(finalItem.id, itemId)
    }
    
    // MARK: - Race Condition Tests
    
    func testCreateDeleteRaceCondition() async throws {
        let testId = UUID()
        
        // Concurrent create and delete operations
        let createTask = Task {
            let item = TestDataBuilder.createItem(
                id: testId,
                name: "Race Condition Item"
            )
            
            do {
                try await self.itemService.create(item)
                return true
            } catch {
                return false
            }
        }
        
        // Small delay to increase chance of race condition
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        let deleteTask = Task {
            do {
                try await self.itemService.delete(id: testId)
                return true
            } catch {
                return false
            }
        }
        
        let createResult = await createTask.value
        let deleteResult = await deleteTask.value
        
        // Either create succeeds and delete follows, or delete fails because item doesn't exist
        if createResult {
            // Create succeeded
            if deleteResult {
                // Delete also succeeded - item was created then deleted
                let item = try await itemService.getItem(id: testId)
                XCTAssertNil(item)
            } else {
                // Delete failed - race condition where delete ran before create completed
                let item = try await itemService.getItem(id: testId)
                XCTAssertNotNil(item)
            }
        } else {
            // Create failed (possibly due to conflict)
            XCTAssertFalse(deleteResult) // Delete should also fail
        }
    }
    
    func testSearchIndexConsistency() async throws {
        // Create items rapidly while searching
        let searchQueries = ["Test", "Item", "Concurrent", "Value"]
        
        // Start creating items
        let createTask = Task {
            for i in 0..<100 {
                let item = TestDataBuilder.createItem(
                    name: "Test Item \(i)",
                    notes: "Concurrent indexing test with value \(i)"
                )
                try await self.itemService.create(item)
            }
        }
        
        // Concurrent searches
        let searchTasks = searchQueries.map { query in
            Task {
                var resultCounts: [Int] = []
                
                for _ in 0..<10 {
                    let results = try await self.searchService.search(query: query)
                    resultCounts.append(results.count)
                    
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                
                return resultCounts
            }
        }
        
        // Wait for creation to complete
        try await createTask.value
        
        // Collect search results
        var allResultCounts: [[Int]] = []
        for task in searchTasks {
            let counts = try await task.value
            allResultCounts.append(counts)
        }
        
        // Verify search results are monotonically increasing
        for counts in allResultCounts {
            for i in 1..<counts.count {
                XCTAssertGreaterThanOrEqual(counts[i], counts[i-1],
                    "Search results should not decrease as items are added")
            }
        }
        
        // Final search should find all items
        let finalResults = try await searchService.search(query: "Test")
        XCTAssertEqual(finalResults.count, 100)
    }
    
    // MARK: - Transaction Isolation Tests
    
    func testTransactionIsolation() async throws {
        // Test ACID properties with concurrent transactions
        let initialValue = 1000.0
        
        // Create account items
        let account1 = try await itemService.create(
            TestDataBuilder.createItem(name: "Account 1", value: initialValue)
        )
        let account2 = try await itemService.create(
            TestDataBuilder.createItem(name: "Account 2", value: initialValue)
        )
        
        // Concurrent transfers
        let transferTasks = (0..<10).map { _ in
            Task {
                let amount = Double.random(in: 10...100)
                
                do {
                    try await self.database.transaction { db in
                        // Read current balances
                        guard var from = try await self.itemService.getItem(id: account1.id),
                              var to = try await self.itemService.getItem(id: account2.id) else {
                            throw TransactionError.itemNotFound
                        }
                        
                        // Check sufficient balance
                        guard from.value >= amount else {
                            throw TransactionError.insufficientFunds
                        }
                        
                        // Perform transfer
                        from.value -= amount
                        to.value += amount
                        
                        // Update both accounts
                        try await self.itemService.update(from)
                        try await self.itemService.update(to)
                    }
                    
                    return (success: true, amount: amount)
                } catch {
                    return (success: false, amount: 0.0)
                }
            }
        }
        
        // Wait for all transfers
        var totalTransferred = 0.0
        var successCount = 0
        
        for task in transferTasks {
            let result = await task.value
            if result.success {
                totalTransferred += result.amount
                successCount += 1
            }
        }
        
        // Verify conservation of value
        let finalAccount1 = try await itemService.getItem(id: account1.id)!
        let finalAccount2 = try await itemService.getItem(id: account2.id)!
        
        let totalValue = finalAccount1.value + finalAccount2.value
        XCTAssertEqual(totalValue, initialValue * 2, accuracy: 0.01)
        
        // Verify transfers match balance changes
        XCTAssertEqual(finalAccount1.value, initialValue - totalTransferred, accuracy: 0.01)
        XCTAssertEqual(finalAccount2.value, initialValue + totalTransferred, accuracy: 0.01)
    }
    
    // MARK: - Deadlock Prevention Tests
    
    func testDeadlockPrevention() async throws {
        // Create multiple items that will be accessed in different orders
        let items = try await createTestItems(count: 5)
        let itemIds = items.map { $0.id }
        
        // Task 1: Updates items in order A, B, C, D, E
        let task1 = Task {
            for (index, id) in itemIds.enumerated() {
                do {
                    try await self.database.transaction { _ in
                        if var item = try await self.itemService.getItem(id: id) {
                            item.value = Double(index * 100)
                            try await self.itemService.update(item)
                        }
                        
                        // Simulate work
                        try await Task.sleep(nanoseconds: 5_000_000) // 5ms
                    }
                } catch {
                    return false
                }
            }
            return true
        }
        
        // Task 2: Updates items in reverse order E, D, C, B, A
        let task2 = Task {
            for (index, id) in itemIds.reversed().enumerated() {
                do {
                    try await self.database.transaction { _ in
                        if var item = try await self.itemService.getItem(id: id) {
                            item.notes = "Updated by task 2 - \(index)"
                            try await self.itemService.update(item)
                        }
                        
                        // Simulate work
                        try await Task.sleep(nanoseconds: 5_000_000) // 5ms
                    }
                } catch {
                    return false
                }
            }
            return true
        }
        
        // Both tasks should complete without deadlock
        let result1 = await task1.value
        let result2 = await task2.value
        
        XCTAssertTrue(result1 || result2, "At least one task should succeed")
    }
    
    // MARK: - Cache Coherence Tests
    
    func testCacheCoherenceUnderConcurrency() async throws {
        // Create item
        let item = try await createTestItem()
        
        // Warm up cache
        _ = try await itemService.getItem(id: item.id)
        
        // Concurrent operations mixing cached and uncached access
        await withTaskGroup(of: Void.self) { group in
            // Reader tasks (use cache)
            for i in 0..<5 {
                group.addTask {
                    for j in 0..<10 {
                        let cached = try! await self.itemService.getItem(id: item.id)!
                        
                        // Verify we get consistent data
                        XCTAssertEqual(cached.id, item.id)
                        
                        // Log for debugging
                        print("Reader \(i) iteration \(j): value = \(cached.value)")
                        
                        try! await Task.sleep(nanoseconds: 2_000_000) // 2ms
                    }
                }
            }
            
            // Writer task (invalidates cache)
            group.addTask {
                for i in 0..<5 {
                    try! await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    
                    var updated = try! await self.itemService.getItem(id: item.id)!
                    updated.value = Double(i * 1000)
                    
                    try! await self.itemService.update(updated)
                    
                    print("Writer updated value to \(updated.value)")
                }
            }
        }
        
        // Verify final state
        let finalItem = try await itemService.getItem(id: item.id)!
        XCTAssertEqual(finalItem.value, 4000.0) // Last write was i=4
    }
    
    // MARK: - Bulk Operation Atomicity Tests
    
    func testBulkOperationAtomicity() async throws {
        let batchSize = 100
        let concurrentBatches = 5
        
        // Track successful batches
        actor BatchTracker {
            var successfulBatches: Set<Int> = []
            
            func recordSuccess(batchId: Int) {
                successfulBatches.insert(batchId)
            }
            
            func getSuccessful() -> Set<Int> {
                return successfulBatches
            }
        }
        
        let tracker = BatchTracker()
        
        // Concurrent bulk creates
        let tasks = (0..<concurrentBatches).map { batchId in
            Task {
                let items = (0..<batchSize).map { itemIndex in
                    TestDataBuilder.createItem(
                        name: "Batch \(batchId) Item \(itemIndex)",
                        value: Double(batchId * 1000 + itemIndex)
                    )
                }
                
                do {
                    // Bulk operation should be atomic
                    try await self.itemService.bulkCreate(items)
                    await tracker.recordSuccess(batchId: batchId)
                } catch {
                    // Entire batch should fail
                }
            }
        }
        
        // Wait for all batches
        for task in tasks {
            await task.value
        }
        
        let successfulBatches = await tracker.getSuccessful()
        
        // Verify atomicity - each successful batch should have all its items
        for batchId in successfulBatches {
            let batchItems = try await itemService.search(
                query: "Batch \(batchId)"
            )
            
            XCTAssertEqual(batchItems.count, batchSize,
                "Batch \(batchId) should have exactly \(batchSize) items")
        }
        
        // Verify no partial batches
        let allItems = try await itemService.getAllItems()
        let totalExpected = successfulBatches.count * batchSize
        
        XCTAssertEqual(allItems.count, totalExpected,
            "Should have complete batches only")
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int) async throws -> [Item] {
        try await withThrowingTaskGroup(of: Item.self) { group in
            for i in 0..<count {
                group.addTask {
                    let item = TestDataBuilder.createItem(
                        name: "Test Item \(i)",
                        value: Double(i)
                    )
                    return try await self.itemService.create(item)
                }
            }
            
            var items: [Item] = []
            for try await item in group {
                items.append(item)
            }
            return items
        }
    }
    
    private func createTestItem() async throws -> Item {
        let item = TestDataBuilder.createItem(name: "Test Item")
        return try await itemService.create(item)
    }
}

// MARK: - Supporting Types

enum ConcurrencyError: Error {
    case optimisticLockFailure
    case deadlockDetected
    case transactionTimeout
}

enum TransactionError: Error {
    case itemNotFound
    case insufficientFunds
    case concurrentModification
}

extension ItemService {
    func updateWithOptimisticLock(_ item: Item) async throws {
        // In real implementation, would check version/timestamp
        let current = try await getItem(id: item.id)
        
        guard let current = current,
              current.modifiedAt == item.modifiedAt else {
            throw ConcurrencyError.optimisticLockFailure
        }
        
        var updated = item
        updated.modifiedAt = Date()
        try await update(updated)
    }
}

extension TestDatabase {
    func transaction<T>(_ block: @escaping (Database) async throws -> T) async throws -> T {
        // In real implementation, would handle proper transaction isolation
        return try await block(self as! Database)
    }
}