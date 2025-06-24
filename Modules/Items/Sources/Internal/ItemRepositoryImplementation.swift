import Foundation
import Core

/// Mock implementation of ItemRepository for development
/// This will be replaced with real persistence later
final class ItemRepositoryImplementation: ItemRepository {
    private var items: [Item] = []
    private let queue = DispatchQueue(label: "com.homeinventory.items", attributes: .concurrent)
    
    init() {
        // Initialize with comprehensive mock data
        self.items = MockDataService.generateComprehensiveItems()
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
                    // Post update notification for Spotlight
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .itemUpdated, object: entity)
                    }
                } else {
                    self.items.append(entity)
                    // Post add notification for Spotlight
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .itemAdded, object: entity)
                    }
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
                // Post delete notification for Spotlight
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .itemDeleted, object: id)
                }
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
    
    func fuzzySearch(query: String, threshold: Double = 0.6) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let fuzzyService = Core.FuzzySearchService()
                let results = self.items.fuzzySearch(query: query, fuzzyService: fuzzyService)
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
    
    func fetchByCategoryId(_ categoryId: UUID) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.items.filter { $0.categoryId == categoryId }
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
    
    func searchWithCriteria(_ criteria: ItemSearchCriteria) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                var results = self.items
                
                // Filter by search text
                if let searchText = criteria.searchText, !searchText.isEmpty {
                    let lowercased = searchText.lowercased()
                    results = results.filter { item in
                        item.name.lowercased().contains(lowercased) ||
                        (item.brand?.lowercased().contains(lowercased) ?? false) ||
                        (item.model?.lowercased().contains(lowercased) ?? false) ||
                        (item.notes?.lowercased().contains(lowercased) ?? false) ||
                        item.tags.contains { $0.lowercased().contains(lowercased) }
                    }
                }
                
                // Filter by categories
                if !criteria.categories.isEmpty {
                    results = results.filter { criteria.categories.contains($0.category) }
                }
                
                // Filter by location names
                if !criteria.locationNames.isEmpty {
                    // In a real implementation, this would query location repository
                    // For now, we'll skip location filtering
                }
                
                // Filter by brands
                if !criteria.brands.isEmpty {
                    results = results.filter { item in
                        guard let brand = item.brand else { return false }
                        return criteria.brands.contains { brand.lowercased().contains($0.lowercased()) }
                    }
                }
                
                // Filter by purchase date range
                if criteria.purchaseDateStart != nil || criteria.purchaseDateEnd != nil {
                    results = results.filter { item in
                        guard let purchaseDate = item.purchaseDate else { return false }
                        if let start = criteria.purchaseDateStart, purchaseDate < start {
                            return false
                        }
                        if let end = criteria.purchaseDateEnd, purchaseDate > end {
                            return false
                        }
                        return true
                    }
                }
                
                // Filter by price range
                if criteria.minPrice != nil || criteria.maxPrice != nil {
                    results = results.filter { item in
                        guard let price = item.purchasePrice else { return false }
                        if let min = criteria.minPrice, Decimal(min) > price {
                            return false
                        }
                        if let max = criteria.maxPrice, Decimal(max) < price {
                            return false
                        }
                        return true
                    }
                }
                
                // Filter by conditions
                if !criteria.conditions.isEmpty {
                    results = results.filter { criteria.conditions.contains($0.condition) }
                }
                
                // Filter by warranty status
                if let underWarranty = criteria.underWarranty, underWarranty {
                    // In a real implementation, this would check against warranty repository
                    // For now, filter by items that have a warrantyId
                    results = results.filter { $0.warrantyId != nil }
                }
                
                // Filter by favorite status - removed as Item doesn't have isFavorite property
                
                // Filter by recently added
                if let recentlyAdded = criteria.recentlyAdded, recentlyAdded {
                    let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
                    results = results.filter { $0.createdAt > thirtyDaysAgo }
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchItemsUnderWarranty() async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                // In a real implementation, this would check warranty expiry dates
                // For now, return items that have a warrantyId
                let results = self.items.filter { $0.warrantyId != nil }
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchFavoriteItems() async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                // Item doesn't have isFavorite property, return empty array
                let results: [Item] = []
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchRecentlyAdded(days: Int) async throws -> [Item] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
                let results = self.items.filter { $0.createdAt > cutoffDate }
                continuation.resume(returning: results)
            }
        }
    }
    
    // MARK: - Additional Helper Methods
    
    func createItem(_ item: Item) async throws {
        try await save(item)
    }
}