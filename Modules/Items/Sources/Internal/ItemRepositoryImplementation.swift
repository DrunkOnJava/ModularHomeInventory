import Foundation
import Core

/// Mock implementation of ItemRepository for development
/// This will be replaced with real persistence later
final class ItemRepositoryImplementation: ItemRepository {
    private var items: [Item] = []
    private let queue = DispatchQueue(label: "com.homeinventory.items", attributes: .concurrent)
    
    init() {
        // Initialize with some sample data
        self.items = Item.previews
    }
    
    // MARK: - Repository Protocol
    
    func fetchAll() async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.items)
            }
        }
    }
    
    func fetch(id: UUID) async throws -> Item? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let item = self.items.first { $0.id == id }
                continuation.resume(returning: item)
            }
        }
    }
    
    func save(_ entity: Item) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.items.firstIndex(where: { $0.id == entity.id }) {
                    self.items[index] = entity
                } else {
                    self.items.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    func saveAll(_ entities: [Item]) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                for entity in entities {
                    if let index = self.items.firstIndex(where: { $0.id == entity.id }) {
                        self.items[index] = entity
                    } else {
                        self.items.append(entity)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func delete(_ entity: Item) async throws {
        try await delete(id: entity.id)
    }
    
    func delete(id: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.items.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - ItemRepository Protocol
    
    func search(query: String) async throws -> [Item] {
        let lowercasedQuery = query.lowercased()
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.items.filter { item in
                    item.name.lowercased().contains(lowercasedQuery) ||
                    (item.brand?.lowercased().contains(lowercasedQuery) ?? false) ||
                    (item.model?.lowercased().contains(lowercasedQuery) ?? false) ||
                    (item.notes?.lowercased().contains(lowercasedQuery) ?? false) ||
                    item.tags.contains { $0.lowercased().contains(lowercasedQuery) }
                }
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.items.filter { $0.category == category }
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchByLocation(_ locationId: UUID) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.items.filter { $0.locationId == locationId }
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchByBarcode(_ barcode: String) async throws -> Item? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let item = self.items.first { $0.barcode == barcode }
                continuation.resume(returning: item)
            }
        }
    }
    
    // MARK: - Additional Helper Methods
    
    func createItem(_ item: Item) async throws {
        try await save(item)
    }
}