import Foundation

/// Repository for managing collections
/// Swift 5.9 - No Swift 6 features
public protocol CollectionRepository: Repository where Entity == Collection {
    /// Fetch collections containing a specific item
    func fetchByItemId(_ itemId: UUID) async throws -> [Collection]
    
    /// Add an item to a collection
    func addItem(_ itemId: UUID, to collectionId: UUID) async throws
    
    /// Remove an item from a collection
    func removeItem(_ itemId: UUID, from collectionId: UUID) async throws
    
    /// Fetch active (non-archived) collections
    func fetchActive() async throws -> [Collection]
    
    /// Fetch archived collections
    func fetchArchived() async throws -> [Collection]
    
    /// Archive a collection
    func archive(_ collectionId: UUID) async throws
    
    /// Unarchive a collection
    func unarchive(_ collectionId: UUID) async throws
}