import Foundation

/// Repository protocol for managing tags
public protocol TagRepository: Repository where Entity == Tag {
    /// Search tags by name
    func search(query: String) async throws -> [Tag]
    
    /// Fetch tags by IDs
    func fetchByIds(_ ids: [UUID]) async throws -> [Tag]
}

// MARK: - Default Implementations
public extension TagRepository {
    /// Get all tags
    func getAllTags() async throws -> [Tag] {
        return try await fetchAll()
    }
}