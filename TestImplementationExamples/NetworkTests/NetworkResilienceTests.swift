import XCTest
@testable import Core
@testable import Sync

/// Tests for network failure handling and offline mode
class NetworkResilienceTests: XCTestCase {
    
    var mockSession: URLSession!
    var syncService: SyncService!
    
    override func setUp() {
        super.setUp()
        
        // Configure mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        // Initialize services with mock session
        syncService = SyncService(session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
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
            let pendingOps = await syncService.pendingOperations
            XCTAssertGreaterThan(pendingOps.count, 0)
            
            // Verify user notification
            let notifications = await NotificationCenterMock.shared.pendingNotifications
            XCTAssertTrue(notifications.contains { $0.identifier == "sync-failed-offline" })
        }
    }
    
    func testRequestTimeout() async throws {
        // Configure 1 second timeout
        syncService.timeoutInterval = 1.0
        
        // Mock slow response (2 seconds)
        MockURLProtocol.mockDelay = 2.0
        MockURLProtocol.mockData = "{}".data(using: .utf8)
        
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
        syncService.retryPolicy = RetryPolicy(
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
        
        syncService.retryPolicy = RetryPolicy(
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
        // Allow some tolerance for async execution
        XCTAssertGreaterThan(attemptTimes[1], 0.05)  // ~0.1s
        XCTAssertGreaterThan(attemptTimes[2], 0.15)  // ~0.2s
        XCTAssertGreaterThan(attemptTimes[3], 0.35)  // ~0.4s
    }
    
    // MARK: - Offline Mode Tests
    
    func testOfflineQueueing() async throws {
        // Enable offline mode
        NetworkMonitor.shared.simulateOffline()
        
        // Create items while offline
        let item1 = try await ItemService.create(name: "Offline Item 1")
        let item2 = try await ItemService.create(name: "Offline Item 2")
        
        // Verify items are marked as pending sync
        XCTAssertTrue(item1.isSyncPending)
        XCTAssertTrue(item2.isSyncPending)
        
        // Verify operations are queued
        let queue = await OfflineSyncQueue.shared.pendingOperations
        XCTAssertEqual(queue.count, 2)
        
        // Verify queue persistence
        let persistedQueue = try await OfflineSyncQueue.loadFromDisk()
        XCTAssertEqual(persistedQueue.count, 2)
    }
    
    func testOfflineToOnlineTransition() async throws {
        // Start offline
        NetworkMonitor.shared.simulateOffline()
        
        // Create items
        let items = try await (0..<5).asyncMap { i in
            try await ItemService.create(name: "Item \(i)")
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
        NetworkMonitor.shared.simulateOnline()
        
        // Wait for auto-sync
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        
        // Verify all items synced
        for item in items {
            let syncedItem = try await ItemService.get(id: item.id)
            XCTAssertFalse(syncedItem.isSyncPending)
        }
        
        // Verify queue is empty
        let queue = await OfflineSyncQueue.shared.pendingOperations
        XCTAssertEqual(queue.count, 0)
    }
    
    func testConflictResolution() async throws {
        let itemId = UUID()
        
        // Create local version
        NetworkMonitor.shared.simulateOffline()
        var localItem = try await ItemService.create(
            id: itemId,
            name: "Local Version",
            modifiedAt: Date()
        )
        
        // Simulate server version
        let serverItem = Item(
            id: itemId,
            name: "Server Version",
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
            
            let conflictData = try! JSONEncoder().encode([
                "conflict": true,
                "serverVersion": serverItem
            ])
            
            return (conflictData, response)
        }
        
        // Go online and trigger sync
        NetworkMonitor.shared.simulateOnline()
        
        do {
            try await syncService.sync()
        } catch SyncError.conflict(let resolution) {
            // Test automatic resolution (last-write-wins)
            XCTAssertEqual(resolution.chosen.name, "Local Version")
            XCTAssertEqual(resolution.discarded.name, "Server Version")
            
            // Test manual resolution option
            let userChoice = try await ConflictResolver.presentToUser(
                local: localItem,
                server: serverItem
            )
            
            XCTAssertNotNil(userChoice)
        }
    }
    
    // MARK: - Partial Failure Tests
    
    func testBatchSyncPartialFailure() async throws {
        let items = try await (0..<10).asyncMap { i in
            try await ItemService.create(name: "Item \(i)")
        }
        
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
        
        XCTAssertEqual(succeeded.count, 7) // ~70% success
        XCTAssertEqual(failed.count, 3)    // ~30% failure
        
        // Verify failed items remain in queue
        let queue = await OfflineSyncQueue.shared.pendingOperations
        XCTAssertEqual(queue.count, 3)
    }
    
    // MARK: - Network Quality Tests
    
    func testPoorNetworkConditions() async throws {
        // Simulate poor network with packet loss
        MockURLProtocol.mockHandler = { request in
            // 30% packet loss
            if Int.random(in: 0..<10) < 3 {
                throw URLError(.networkConnectionLost)
            }
            
            // Variable latency (100ms - 2s)
            let delay = Double.random(in: 0.1...2.0)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        // Should handle poor conditions gracefully
        syncService.retryPolicy = RetryPolicy(
            maxAttempts: 5,
            backoffMultiplier: 1.5,
            initialDelay: 0.5
        )
        
        // Test multiple operations
        let operations = (0..<20).map { i in
            SyncOperation(type: .create, data: ["name": "Item \(i)"])
        }
        
        let results = await syncService.performOperations(operations)
        
        // Should eventually succeed for most operations
        let successRate = Double(results.filter { $0.success }.count) / Double(results.count)
        XCTAssertGreaterThan(successRate, 0.8) // 80% success rate
    }
}

// MARK: - Mock Helpers

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    static var mockHandler: ((URLRequest) async throws -> (Data, HTTPURLResponse))?
    static var mockDelay: TimeInterval = 0
    
    static func reset() {
        mockData = nil
        mockError = nil
        mockHandler = nil
        mockDelay = 0
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        Task {
            do {
                if let delay = Self.mockDelay, delay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                if let error = Self.mockError {
                    client?.urlProtocol(self, didFailWithError: error)
                    return
                }
                
                if let handler = Self.mockHandler {
                    let (data, response) = try await handler(request)
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                } else if let data = Self.mockData {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                }
                
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    override func stopLoading() {
        // No-op
    }
}