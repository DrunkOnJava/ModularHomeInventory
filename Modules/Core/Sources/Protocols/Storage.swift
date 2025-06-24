import Foundation

/// Storage protocol for data persistence
/// Swift 5.9 - No Swift 6 features
public protocol Storage<Entity> {
    associatedtype Entity: Identifiable & Codable
    
    /// Fetch all entities
    func fetchAll() async throws -> [Entity]
    
    /// Fetch entity by ID
    func fetch(id: Entity.ID) async throws -> Entity?
    
    /// Save an entity
    func save(_ entity: Entity) async throws
    
    /// Save multiple entities
    func saveAll(_ entities: [Entity]) async throws
    
    /// Delete an entity
    func delete(_ entity: Entity) async throws
    
    /// Delete entity by ID
    func delete(id: Entity.ID) async throws
    
    /// Delete all entities
    func deleteAll() async throws
}

// MARK: - Default implementations
public extension Storage {
    func saveAll(_ entities: [Entity]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: Entity) async throws {
        try await delete(id: entity.id)
    }
}