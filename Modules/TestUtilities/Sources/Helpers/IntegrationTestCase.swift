import XCTest
import Core
import SharedUI

/// Base class for integration tests with setup/teardown and data management
open class IntegrationTestCase: XCTestCase {
    
    /// Test database instance
    public var testDatabase: TestDatabase!
    
    /// Test network session
    public var testSession: URLSession!
    
    /// Test user for authentication
    public var testUser: TestUser!
    
    /// Flag to determine if test data should be cleaned up
    public var shouldCleanupTestData = true
    
    open override func setUp() {
        super.setUp()
        
        Task {
            await setupAsync()
        }
    }
    
    open override func tearDown() {
        Task {
            await tearDownAsync()
        }
        
        super.tearDown()
    }
    
    /// Async setup for integration tests
    open func setupAsync() async {
        // Initialize test database
        testDatabase = await TestDatabase.inMemory()
        
        // Configure test network session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        testSession = URLSession(configuration: configuration)
        
        // Create test user
        testUser = try! await TestUser.create(
            email: "test@example.com",
            name: "Test User"
        )
        
        // Configure services to use test instances
        await ServiceLocator.shared.configure(for: .testing) { container in
            container.register(Database.self) { _ in self.testDatabase }
            container.register(URLSession.self) { _ in self.testSession }
            container.register(User.self) { _ in self.testUser }
        }
    }
    
    /// Async teardown for integration tests
    open func tearDownAsync() async {
        if shouldCleanupTestData {
            await cleanupTestData()
        }
        
        // Reset service locator
        await ServiceLocator.shared.reset()
        
        // Clear mock responses
        MockURLProtocol.reset()
    }
    
    /// Clean up all test data
    public func cleanupTestData() async {
        do {
            try await testDatabase.deleteAll()
            try await TestFileManager.cleanupTestFiles()
            await TestNotificationCenter.clearAll()
        } catch {
            XCTFail("Failed to cleanup test data: \(error)")
        }
    }
    
    /// Wait for condition with timeout
    public func waitForCondition(
        timeout: TimeInterval = 10,
        pollingInterval: TimeInterval = 0.1,
        condition: @escaping () async -> Bool
    ) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }
        
        throw TestError.timeout("Condition not met within \(timeout) seconds")
    }
    
    /// Create test items
    public func createTestItems(count: Int) async throws -> [Item] {
        return try await withThrowingTaskGroup(of: Item.self) { group in
            for i in 0..<count {
                group.addTask {
                    try await ItemService.create(
                        name: "Test Item \(i)",
                        value: Double(i * 10),
                        category: Category.allCases.randomElement()!
                    )
                }
            }
            
            var items: [Item] = []
            for try await item in group {
                items.append(item)
            }
            return items
        }
    }
    
    /// Simulate network conditions
    public func simulateNetworkCondition(_ condition: NetworkCondition) {
        MockURLProtocol.networkCondition = condition
    }
    
    /// Verify no memory leaks
    public func verifyNoMemoryLeaks(for object: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Memory leak detected", file: file, line: line)
        }
    }
}

// MARK: - Test Error

public enum TestError: LocalizedError {
    case timeout(String)
    case invalidState(String)
    case setupFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .timeout(let message):
            return "Timeout: \(message)"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .setupFailed(let message):
            return "Setup failed: \(message)"
        }
    }
}

// MARK: - Network Conditions

public enum NetworkCondition {
    case online
    case offline
    case slow3G
    case lossy(packetLossRate: Double)
    case latency(milliseconds: Int)
    
    var urlProtocolDelay: TimeInterval? {
        switch self {
        case .online:
            return nil
        case .offline:
            return nil
        case .slow3G:
            return 0.5
        case .lossy:
            return 0.2
        case .latency(let ms):
            return Double(ms) / 1000.0
        }
    }
}