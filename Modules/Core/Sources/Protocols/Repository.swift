import Foundation

/// Base repository protocol for data access
public protocol Repository {
    associatedtype Entity: Identifiable
    
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
}

/// Item-specific repository protocol
public protocol ItemRepository: Repository where Entity == Item {
    /// Search items by query
    func search(query: String) async throws -> [Item]
    
    /// Fetch items by category
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item]
    
    /// Fetch items by location
    func fetchByLocation(_ locationId: UUID) async throws -> [Item]
    
    /// Fetch items by barcode
    func fetchByBarcode(_ barcode: String) async throws -> Item?
}

/// Location-specific repository protocol  
public protocol LocationRepository: Repository where Entity == Location {
    /// Fetch root locations (no parent)
    func fetchRootLocations() async throws -> [Location]
    
    /// Fetch child locations
    func fetchChildren(of parentId: UUID) async throws -> [Location]
    
    /// Fetch all locations
    func getAllLocations() async throws -> [Location]
}

// MARK: - Default Implementations
public extension LocationRepository {
    func getAllLocations() async throws -> [Location] {
        try await fetchAll()
    }
}

public extension ItemRepository {
    /// Create a new item (alias for save)
    func createItem(_ item: Item) async throws {
        try await save(item)
    }
}