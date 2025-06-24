import Foundation

/// Default in-memory implementation of CollectionRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultCollectionRepository: CollectionRepository {
    private var collections: [Collection] = []
    
    public init() {}
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [Collection] {
        collections
    }
    
    public func fetch(id: UUID) async throws -> Collection? {
        collections.first { $0.id == id }
    }
    
    public func save(_ entity: Collection) async throws {
        if let index = collections.firstIndex(where: { $0.id == entity.id }) {
            var updated = entity
            updated.updatedAt = Date()
            collections[index] = updated
        } else {
            collections.append(entity)
        }
    }
    
    public func saveAll(_ entities: [Collection]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: Collection) async throws {
        collections.removeAll { $0.id == entity.id }
    }
    
    public func delete(id: UUID) async throws {
        collections.removeAll { $0.id == id }
    }
    
    // MARK: - CollectionRepository Protocol
    
    public func fetchByItemId(_ itemId: UUID) async throws -> [Collection] {
        collections.filter { $0.itemIds.contains(itemId) }
    }
    
    public func addItem(_ itemId: UUID, to collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        var collection = collections[index]
        if !collection.itemIds.contains(itemId) {
            collection.itemIds.append(itemId)
            collection.updatedAt = Date()
            collections[index] = collection
        }
    }
    
    public func removeItem(_ itemId: UUID, from collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        var collection = collections[index]
        collection.itemIds.removeAll { $0 == itemId }
        collection.updatedAt = Date()
        collections[index] = collection
    }
    
    public func fetchActive() async throws -> [Collection] {
        collections.filter { !$0.isArchived }
    }
    
    public func fetchArchived() async throws -> [Collection] {
        collections.filter { $0.isArchived }
    }
    
    public func archive(_ collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        collections[index].isArchived = true
        collections[index].updatedAt = Date()
    }
    
    public func unarchive(_ collectionId: UUID) async throws {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw RepositoryError.notFound
        }
        
        collections[index].isArchived = false
        collections[index].updatedAt = Date()
    }
}

enum RepositoryError: LocalizedError {
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found"
        }
    }
}