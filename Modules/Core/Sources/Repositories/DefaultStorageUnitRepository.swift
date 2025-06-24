import Foundation

/// Default in-memory implementation of StorageUnitRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultStorageUnitRepository: StorageUnitRepository {
    private var storageUnits: [StorageUnit] = StorageUnit.previews
    private let queue = DispatchQueue(label: "com.homeinventory.storageunitrepository", attributes: .concurrent)
    
    public init() {}
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [StorageUnit] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.storageUnits)
            }
        }
    }
    
    public func fetch(id: UUID) async throws -> StorageUnit? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let unit = self.storageUnits.first { $0.id == id }
                continuation.resume(returning: unit)
            }
        }
    }
    
    public func save(_ entity: StorageUnit) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.storageUnits.firstIndex(where: { $0.id == entity.id }) {
                    self.storageUnits[index] = entity
                } else {
                    self.storageUnits.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    public func saveAll(_ entities: [StorageUnit]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: StorageUnit) async throws {
        try await delete(id: entity.id)
    }
    
    public func delete(id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.storageUnits.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - StorageUnitRepository Protocol
    
    public func fetchByLocation(_ locationId: UUID) async throws -> [StorageUnit] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let units = self.storageUnits.filter { $0.locationId == locationId }
                continuation.resume(returning: units)
            }
        }
    }
    
    public func fetchByType(_ type: StorageUnitType) async throws -> [StorageUnit] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let units = self.storageUnits.filter { $0.type == type }
                continuation.resume(returning: units)
            }
        }
    }
    
    public func search(query: String) async throws -> [StorageUnit] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let filtered = self.storageUnits.filter { unit in
                    unit.name.localizedCaseInsensitiveContains(query) ||
                    (unit.description?.localizedCaseInsensitiveContains(query) ?? false) ||
                    (unit.position?.localizedCaseInsensitiveContains(query) ?? false)
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    public func fetchWithAvailableCapacity() async throws -> [StorageUnit] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let units = self.storageUnits.filter { unit in
                    guard let capacity = unit.capacity else { return true } // No capacity limit
                    return unit.currentItemCount < capacity
                }
                continuation.resume(returning: units)
            }
        }
    }
    
    public func updateItemCount(for unitId: UUID, count: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.storageUnits.firstIndex(where: { $0.id == unitId }) {
                    self.storageUnits[index].currentItemCount = max(0, count)
                    self.storageUnits[index].updatedAt = Date()
                }
                continuation.resume()
            }
        }
    }
    
    public func fetchByItemId(_ itemId: UUID) async throws -> StorageUnit? {
        // In a real implementation, this would query the relationship
        // For now, return nil
        return nil
    }
}