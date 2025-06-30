import Foundation
import Core

/// Mock network service for testing
public class MockNetworkService: NetworkServiceProtocol {
    
    public var mockResponses: [String: Result<Data, Error>] = [:]
    public var requestCount = 0
    public var lastRequest: URLRequest?
    public var delay: TimeInterval = 0
    
    public init() {}
    
    public func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        requestCount += 1
        lastRequest = try endpoint.urlRequest()
        
        // Simulate delay
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Get mock response
        let key = "\(endpoint.method.rawValue):\(endpoint.path)"
        guard let result = mockResponses[key] else {
            throw NetworkError.noMockResponse
        }
        
        switch result {
        case .success(let data):
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
            
        case .failure(let error):
            throw error
        }
    }
    
    public func setMockResponse<T: Encodable>(
        for endpoint: Endpoint,
        response: T
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(response)
        
        let key = "\(endpoint.method.rawValue):\(endpoint.path)"
        mockResponses[key] = .success(data)
    }
    
    public func setMockError(
        for endpoint: Endpoint,
        error: Error
    ) {
        let key = "\(endpoint.method.rawValue):\(endpoint.path)"
        mockResponses[key] = .failure(error)
    }
    
    public func reset() {
        mockResponses.removeAll()
        requestCount = 0
        lastRequest = nil
        delay = 0
    }
}

// MARK: - Mock Sync Service

public class MockSyncService: SyncServiceProtocol {
    
    public var syncCallCount = 0
    public var shouldFail = false
    public var syncDelay: TimeInterval = 0
    public var pendingOperations: [SyncOperation] = []
    public var lastSyncDate: Date?
    public var conflictHandler: ((SyncConflict) async -> ConflictResolution)?
    
    public init() {}
    
    public func sync() async throws {
        syncCallCount += 1
        
        if syncDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
        }
        
        if shouldFail {
            throw SyncError.syncFailed("Mock sync failure")
        }
        
        lastSyncDate = Date()
        pendingOperations.removeAll()
    }
    
    public func syncItem(_ item: Item) async throws {
        if shouldFail {
            throw SyncError.syncFailed("Mock sync failure")
        }
        
        pendingOperations.append(
            SyncOperation(
                type: .update,
                entityId: item.id.uuidString,
                data: try JSONEncoder().encode(item)
            )
        )
    }
    
    public func resolveConflict(_ conflict: SyncConflict) async throws -> ConflictResolution {
        if let handler = conflictHandler {
            return await handler(conflict)
        }
        
        // Default: last write wins
        return .useLocal
    }
    
    public func getPendingOperations() async -> [SyncOperation] {
        return pendingOperations
    }
    
    public func getLastSyncDate() async -> Date? {
        return lastSyncDate
    }
    
    public func reset() {
        syncCallCount = 0
        shouldFail = false
        syncDelay = 0
        pendingOperations.removeAll()
        lastSyncDate = nil
        conflictHandler = nil
    }
}

// MARK: - Mock Item Service

public class MockItemService: ItemServiceProtocol {
    
    public var items: [Item] = []
    public var createCallCount = 0
    public var shouldFailCreate = false
    
    public init() {}
    
    public func create(
        name: String,
        value: Double? = nil,
        category: Category? = nil
    ) async throws -> Item {
        createCallCount += 1
        
        if shouldFailCreate {
            throw ItemError.creationFailed
        }
        
        let item = Item(
            id: UUID(),
            name: name,
            value: value,
            category: category,
            createdAt: Date(),
            modifiedAt: Date()
        )
        
        items.append(item)
        return item
    }
    
    public func get(id: UUID) async throws -> Item? {
        return items.first { $0.id == id }
    }
    
    public func getAll() async throws -> [Item] {
        return items
    }
    
    public func update(_ item: Item) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw ItemError.notFound
        }
        items[index] = item
    }
    
    public func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }
    
    public func search(query: String) async throws -> [Item] {
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    public func reset() {
        items.removeAll()
        createCallCount = 0
        shouldFailCreate = false
    }
}

// MARK: - Errors

public enum NetworkError: LocalizedError {
    case noMockResponse
    
    public var errorDescription: String? {
        switch self {
        case .noMockResponse:
            return "No mock response configured for this endpoint"
        }
    }
}

public enum ItemError: LocalizedError {
    case creationFailed
    case notFound
    
    public var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create item"
        case .notFound:
            return "Item not found"
        }
    }
}

public enum SyncError: LocalizedError {
    case syncFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}