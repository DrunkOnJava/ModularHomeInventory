import XCTest
@testable import Core
@testable import Sync
@testable import TestUtilities

/// Tests for network failure handling and offline mode
final class NetworkResilienceTests: IntegrationTestCase {
    
    var syncService: SyncService!
    var itemService: ItemService!
    var offlineQueue: OfflineSyncQueue!
    
    override func setupAsync() async {
        await super.setupAsync()
        
        syncService = SyncService(session: testSession)
        itemService = ItemService(database: testDatabase)
        offlineQueue = OfflineSyncQueue.shared
        
        // Clear offline queue
        await offlineQueue.clear()
    }
    
    // MARK: - Network Failure Tests
    
    func testSyncWithNoInternet() async throws {
        // Configure mock to simulate no internet
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)
        
        do {
            try await syncService.sync()
            XCTFail("Sync should fail with no internet")
        } catch {
            // Verify correct error type
            XCTAssertTrue(error is URLError)
            let urlError = error as! URLError
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
            
            // Verify offline queue has pending operations
            let pendingOps = await offlineQueue.pendingOperations
            XCTAssertGreaterThan(pendingOps.count, 0)
        }
    }
    
    func testRequestTimeout() async throws {
        // Configure 1 second timeout
        syncService.configuration.timeoutInterval = 1.0
        
        // Mock slow response (2 seconds)
        MockURLProtocol.mockHandler = { request in
            try await Task.sleep(seconds: 2.0)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        do {
            try await syncService.sync()
            XCTFail("Request should timeout")
        } catch {
            XCTAssertTrue(error is URLError)
            let urlError = error as! URLError
            XCTAssertEqual(urlError.code, .timedOut)
        }
    }
    
    func testRetryMechanism() async throws {
        var attemptCount = 0
        
        // Configure mock to fail first 2 attempts
        MockURLProtocol.mockHandler = { request in
            attemptCount += 1
            
            if attemptCount < 3 {
                throw URLError(.networkConnectionLost)
            }
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        // Configure retry policy
        syncService.configuration.retryPolicy = RetryPolicy(
            maxAttempts: 3,
            backoffMultiplier: 2.0,
            initialDelay: 0.1
        )
        
        // Should succeed on 3rd attempt
        try await syncService.sync()
        
        XCTAssertEqual(attemptCount, 3)
    }
    
    func testExponentialBackoff() async throws {
        var attemptTimes: [TimeInterval] = []
        let startTime = Date()
        
        MockURLProtocol.mockHandler = { request in
            attemptTimes.append(Date().timeIntervalSince(startTime))
            throw URLError(.badServerResponse)
        }
        
        syncService.configuration.retryPolicy = RetryPolicy(
            maxAttempts: 4,
            backoffMultiplier: 2.0,
            initialDelay: 0.1
        )
        
        do {
            try await syncService.sync()
        } catch {
            // Expected to fail after all retries
        }
        
        // Verify exponential backoff timing
        XCTAssertEqual(attemptTimes.count, 4)
        
        // First attempt should be immediate
        XCTAssertLessThan(attemptTimes[0], 0.05)
        
        // Subsequent attempts should follow exponential backoff
        XCTAssertGreaterThan(attemptTimes[1], 0.05)  // ~0.1s
        XCTAssertGreaterThan(attemptTimes[2], 0.15)  // ~0.2s
        XCTAssertGreaterThan(attemptTimes[3], 0.35)  // ~0.4s
    }
    
    // MARK: - Offline Mode Tests
    
    func testOfflineQueueing() async throws {
        // Enable offline mode
        simulateNetworkCondition(.offline)
        
        // Create items while offline
        let item1 = try await itemService.create(name: "Offline Item 1", value: 100)
        let item2 = try await itemService.create(name: "Offline Item 2", value: 200)
        
        // Verify items are marked as pending sync
        XCTAssertEqual(item1.syncStatus, .pending)
        XCTAssertEqual(item2.syncStatus, .pending)
        
        // Verify operations are queued
        let queue = await offlineQueue.pendingOperations
        XCTAssertEqual(queue.count, 2)
        
        // Verify queue persistence
        let persistedQueue = try await OfflineSyncQueue.loadFromDisk()
        XCTAssertEqual(persistedQueue.count, 2)
    }
    
    func testOfflineToOnlineTransition() async throws {
        // Start offline
        simulateNetworkCondition(.offline)
        
        // Create items
        let items = try await (0..<5).asyncMap { i in
            try await itemService.create(name: "Item \(i)", value: Double(i * 100))
        }
        
        // Configure successful sync response
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        // Go online
        simulateNetworkCondition(.online)
        
        // Trigger auto-sync
        try await syncService.syncPendingOperations()
        
        // Verify all items synced
        for item in items {
            let syncedItem = try await itemService.getItem(id: item.id)!
            XCTAssertEqual(syncedItem.syncStatus, .synced)
        }
        
        // Verify queue is empty
        let queue = await offlineQueue.pendingOperations
        XCTAssertEqual(queue.count, 0)
    }
    
    func testConflictResolution() async throws {
        let itemId = UUID()
        
        // Create local version
        simulateNetworkCondition(.offline)
        let localItem = try await itemService.create(
            id: itemId,
            name: "Local Version",
            value: 100,
            modifiedAt: Date()
        )
        
        // Simulate server version
        let serverItem = Item(
            id: itemId,
            name: "Server Version",
            value: 200,
            modifiedAt: Date().addingTimeInterval(-60) // 1 minute older
        )
        
        MockURLProtocol.mockHandler = { request in
            // Return conflict response
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 409, // Conflict
                httpVersion: nil,
                headerFields: nil
            )!
            
            let conflictData = try JSONEncoder().encode(
                ConflictResponse(
                    conflict: true,
                    localVersion: localItem,
                    serverVersion: serverItem
                )
            )
            
            return (conflictData, response)
        }
        
        // Go online and trigger sync
        simulateNetworkCondition(.online)
        
        // Configure conflict resolution strategy
        syncService.conflictResolutionStrategy = .lastWriteWins
        
        try await syncService.sync()
        
        // Verify local version won (newer timestamp)
        let resolvedItem = try await itemService.getItem(id: itemId)!
        XCTAssertEqual(resolvedItem.name, "Local Version")
        XCTAssertEqual(resolvedItem.value, 100)
    }
    
    // MARK: - Partial Failure Tests
    
    func testBatchSyncPartialFailure() async throws {
        let items = try await createTestItems(count: 10)
        
        var processedCount = 0
        
        MockURLProtocol.mockHandler = { request in
            processedCount += 1
            
            // Fail every 3rd request
            if processedCount % 3 == 0 {
                throw URLError(.badServerResponse)
            }
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        let results = await syncService.syncBatch(items)
        
        // Verify partial success
        let succeeded = results.filter { $0.success }
        let failed = results.filter { !$0.success }
        
        XCTAssertGreaterThan(succeeded.count, 0)
        XCTAssertGreaterThan(failed.count, 0)
        XCTAssertEqual(succeeded.count + failed.count, items.count)
        
        // Verify failed items remain in queue
        let queue = await offlineQueue.pendingOperations
        XCTAssertEqual(queue.count, failed.count)
    }
    
    // MARK: - Network Quality Tests
    
    func testPoorNetworkConditions() async throws {
        // Simulate poor network with packet loss
        simulateNetworkCondition(.lossy(packetLossRate: 0.3))
        
        MockURLProtocol.mockHandler = { request in
            // 30% packet loss simulation is handled by MockURLProtocol
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        // Configure aggressive retry policy
        syncService.configuration.retryPolicy = RetryPolicy(
            maxAttempts: 5,
            backoffMultiplier: 1.5,
            initialDelay: 0.5
        )
        
        // Test multiple operations
        let operations = (0..<20).map { i in
            SyncOperation(
                type: .create,
                entityType: "Item",
                entityId: UUID().uuidString,
                data: Data("{\"name\": \"Item \(i)\"}".utf8)
            )
        }
        
        let results = await syncService.performOperations(operations)
        
        // Should eventually succeed for most operations
        let successRate = Double(results.filter { $0.success }.count) / Double(results.count)
        XCTAssertGreaterThan(successRate, 0.7) // 70% success rate minimum
    }
    
    func testNetworkReachabilityMonitoring() async throws {
        let reachability = NetworkReachability.shared
        
        // Start monitoring
        await reachability.startMonitoring()
        
        // Test offline detection
        simulateNetworkCondition(.offline)
        await waitForAsync { await reachability.isReachable == false }
        
        XCTAssertFalse(await reachability.isReachable)
        XCTAssertEqual(await reachability.connectionType, .none)
        
        // Test online detection
        simulateNetworkCondition(.online)
        await waitForAsync { await reachability.isReachable == true }
        
        XCTAssertTrue(await reachability.isReachable)
        XCTAssertNotEqual(await reachability.connectionType, .none)
        
        // Stop monitoring
        await reachability.stopMonitoring()
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityDuringNetworkFailure() async throws {
        // Create item
        let originalItem = try await itemService.create(
            name: "Test Item",
            value: 100,
            notes: "Original notes"
        )
        
        // Start update operation
        let updateTask = Task {
            originalItem.notes = "Updated notes"
            try await itemService.update(originalItem)
        }
        
        // Simulate network failure mid-operation
        MockURLProtocol.mockHandler = { request in
            // Simulate partial data transmission
            try await Task.sleep(seconds: 0.1)
            throw URLError(.networkConnectionLost)
        }
        
        do {
            try await updateTask.value
            try await syncService.sync()
        } catch {
            // Expected to fail
        }
        
        // Verify local data integrity
        let localItem = try await itemService.getItem(id: originalItem.id)!
        XCTAssertEqual(localItem.notes, "Updated notes") // Local update should persist
        XCTAssertEqual(localItem.syncStatus, .pending) // Should be marked for retry
        
        // Verify item is in offline queue
        let queue = await offlineQueue.pendingOperations
        XCTAssertTrue(queue.contains { $0.entityId == originalItem.id.uuidString })
    }
}

// MARK: - Supporting Types

struct ConflictResponse: Codable {
    let conflict: Bool
    let localVersion: Item
    let serverVersion: Item
}

struct SyncBatchResult {
    let itemId: UUID
    let success: Bool
    let error: Error?
}

extension Array where Element == Int {
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        var results = [T]()
        for element in self {
            let result = try await transform(element)
            results.append(result)
        }
        return results
    }
}