import Foundation

/// Repository protocol for managing item templates
public protocol ItemTemplateRepository: Repository where Entity == ItemTemplate {
    /// Fetch templates by category
    func fetchByCategory(_ category: ItemCategory) async throws -> [ItemTemplate]
    
    /// Search templates by name or tags
    func search(query: String) async throws -> [ItemTemplate]
}

// MARK: - Default Implementations
public extension ItemTemplateRepository {
    /// Get all templates
    func getAllTemplates() async throws -> [ItemTemplate] {
        return try await fetchAll()
    }
}