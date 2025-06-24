import Foundation

/// Default implementation of OfflineScanQueueRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultOfflineScanQueueRepository: OfflineScanQueueRepository {
    private var queue: [OfflineScanQueueEntry] = []
    private let userDefaults = UserDefaults.standard
    private let storageKey = "com.homeinventory.offlineScanQueue"
    
    public init() {
        loadFromStorage()
    }
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [OfflineScanQueueEntry] {
        return queue
    }
    
    public func fetch(id: UUID) async throws -> OfflineScanQueueEntry? {
        return queue.first { $0.id == id }
    }
    
    public func save(_ entity: OfflineScanQueueEntry) async throws {
        if let index = queue.firstIndex(where: { $0.id == entity.id }) {
            queue[index] = entity
        } else {
            queue.append(entity)
        }
        saveToStorage()
    }
    
    public func saveAll(_ entities: [OfflineScanQueueEntry]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: OfflineScanQueueEntry) async throws {
        queue.removeAll { $0.id == entity.id }
        saveToStorage()
    }
    
    public func delete(id: UUID) async throws {
        queue.removeAll { $0.id == id }
        saveToStorage()
    }
    
    // MARK: - OfflineScanQueueRepository Protocol
    
    public func fetchPending() async throws -> [OfflineScanQueueEntry] {
        return queue.filter { $0.status == .pending }
    }
    
    public func fetchByStatus(_ status: OfflineScanQueueEntry.QueueStatus) async throws -> [OfflineScanQueueEntry] {
        return queue.filter { $0.status == status }
    }
    
    public func updateStatus(id: UUID, status: OfflineScanQueueEntry.QueueStatus) async throws {
        if let index = queue.firstIndex(where: { $0.id == id }) {
            queue[index].status = status
            if status == .processing {
                queue[index].lastRetryDate = Date()
            }
            saveToStorage()
        }
    }
    
    public func incrementRetryCount(id: UUID) async throws {
        if let index = queue.firstIndex(where: { $0.id == id }) {
            queue[index].retryCount += 1
            queue[index].lastRetryDate = Date()
            saveToStorage()
        }
    }
    
    public func clearCompleted() async throws {
        queue.removeAll { $0.status == .completed }
        saveToStorage()
    }
    
    // MARK: - Private Methods
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(queue) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadFromStorage() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OfflineScanQueueEntry].self, from: data) {
            self.queue = decoded
        }
    }
}