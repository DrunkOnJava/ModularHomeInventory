import Foundation

/// Mock implementation of WarrantyRepository for development
/// Swift 5.9 - No Swift 6 features
public final class MockWarrantyRepository: WarrantyRepository {
    private var warranties: [UUID: Warranty] = [:]
    private let queue = DispatchQueue(label: "com.homeinventory.warranties", attributes: .concurrent)
    
    public init() {
        // Initialize with mock warranties
        let mockWarranties = MockDataService.generateWarranties()
        for warranty in mockWarranties {
            warranties[warranty.id] = warranty
        }
    }
    
    // MARK: - WarrantyRepository Protocol
    
    public func create(_ warranty: Warranty) async throws -> Warranty {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.warranties[warranty.id] = warranty
                continuation.resume(returning: warranty)
            }
        }
    }
    
    public func update(_ warranty: Warranty) async throws -> Warranty {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.warranties[warranty.id] = warranty
                continuation.resume(returning: warranty)
            }
        }
    }
    
    public func delete(_ warrantyId: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.warranties.removeValue(forKey: warrantyId)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Repository Protocol Requirements
    
    public func save(_ entity: Warranty) async throws {
        return try await update(entity)
    }
    
    public func saveAll(_ entities: [Warranty]) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                for entity in entities {
                    self.warranties[entity.id] = entity
                }
                continuation.resume()
            }
        }
    }
    
    public func delete(_ entity: Warranty) async throws {
        return try await delete(entity.id)
    }
    
    public func delete(id: UUID) async throws {
        return try await delete(id)
    }
    
    public func fetch(id: UUID) async throws -> Warranty? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.warranties[id])
            }
        }
    }
    
    public func fetchByItem(_ itemId: UUID) async throws -> Warranty? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let warranty = self.warranties.values.first { $0.itemId == itemId }
                continuation.resume(returning: warranty)
            }
        }
    }
    
    public func fetchAll() async throws -> [Warranty] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: Array(self.warranties.values))
            }
        }
    }
    
    public func fetchActive() async throws -> [Warranty] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let now = Date()
                let active = self.warranties.values.filter { warranty in
                    warranty.endDate > now
                }
                continuation.resume(returning: active)
            }
        }
    }
    
    public func fetchExpiring(within days: Int) async throws -> [Warranty] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let now = Date()
                let cutoffDate = now.addingTimeInterval(Double(days) * 24 * 60 * 60)
                let expiring = self.warranties.values.filter { warranty in
                    warranty.endDate > now && warranty.endDate <= cutoffDate
                }
                continuation.resume(returning: expiring)
            }
        }
    }
    
    public func fetchExpired() async throws -> [Warranty] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let now = Date()
                let expired = self.warranties.values.filter { warranty in
                    warranty.endDate <= now
                }
                continuation.resume(returning: expired)
            }
        }
    }
    
    public func searchByProvider(_ query: String) async throws -> [Warranty] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let results = self.warranties.values.filter { warranty in
                    warranty.provider.localizedCaseInsensitiveContains(query)
                }
                continuation.resume(returning: results)
            }
        }
    }
    
    public func attachDocument(_ documentId: UUID, to warrantyId: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if var warranty = self.warranties[warrantyId] {
                    warranty.documentIds.append(documentId)
                    self.warranties[warrantyId] = warranty
                }
                continuation.resume()
            }
        }
    }
    
    public func removeDocument(_ documentId: UUID, from warrantyId: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if var warranty = self.warranties[warrantyId] {
                    warranty.documentIds.removeAll { $0 == documentId }
                    self.warranties[warrantyId] = warranty
                }
                continuation.resume()
            }
        }
    }
}