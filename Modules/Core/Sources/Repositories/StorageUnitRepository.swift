import Foundation

/// Repository protocol for managing storage units
/// Swift 5.9 - No Swift 6 features
public protocol StorageUnitRepository: Repository where Entity == StorageUnit {
    /// Fetch storage units by location ID
    func fetchByLocation(_ locationId: UUID) async throws -> [StorageUnit]
    
    /// Fetch storage units by type
    func fetchByType(_ type: StorageUnitType) async throws -> [StorageUnit]
    
    /// Search storage units by name or description
    func search(query: String) async throws -> [StorageUnit]
    
    /// Fetch storage units with available capacity
    func fetchWithAvailableCapacity() async throws -> [StorageUnit]
    
    /// Update item count for a storage unit
    func updateItemCount(for unitId: UUID, count: Int) async throws
    
    /// Get storage unit by item ID (find which unit contains an item)
    func fetchByItemId(_ itemId: UUID) async throws -> StorageUnit?
}