import Foundation

/// Repository protocol for managing tags
/// Swift 5.9 - No Swift 6 features
public protocol TagRepository: Repository where Entity == Tag {
    /// Fetch tags by item ID
    func fetchByItemId(_ itemId: UUID) async throws -> [Tag]
    
    /// Search tags by name
    func search(query: String) async throws -> [Tag]
    
    /// Increment item count for a tag
    func incrementItemCount(for tagId: UUID) async throws
    
    /// Decrement item count for a tag
    func decrementItemCount(for tagId: UUID) async throws
    
    /// Fetch most used tags
    func fetchMostUsed(limit: Int) async throws -> [Tag]
    
    /// Find tag by name (case insensitive)
    func findByName(_ name: String) async throws -> Tag?
}