import Foundation

/// Default in-memory implementation of TagRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultTagRepository: TagRepository {
    private var tags: [Tag] = Tag.previews
    private let queue = DispatchQueue(label: "com.homeinventory.tagrepository", attributes: .concurrent)
    
    public init() {}
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.tags)
            }
        }
    }
    
    public func fetch(id: UUID) async throws -> Tag? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let tag = self.tags.first { $0.id == id }
                continuation.resume(returning: tag)
            }
        }
    }
    
    public func save(_ entity: Tag) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == entity.id }) {
                    self.tags[index] = entity
                } else {
                    self.tags.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    public func saveAll(_ entities: [Tag]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: Tag) async throws {
        try await delete(id: entity.id)
    }
    
    public func delete(id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.tags.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - TagRepository Protocol
    
    public func fetchByItemId(_ itemId: UUID) async throws -> [Tag] {
        // In a real implementation, this would query the relationship
        // For now, return empty array
        return []
    }
    
    public func search(query: String) async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let filtered = self.tags.filter { tag in
                    tag.name.localizedCaseInsensitiveContains(query)
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    public func incrementItemCount(for tagId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == tagId }) {
                    self.tags[index].itemCount += 1
                    self.tags[index].updatedAt = Date()
                }
                continuation.resume()
            }
        }
    }
    
    public func decrementItemCount(for tagId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.tags.firstIndex(where: { $0.id == tagId }) {
                    self.tags[index].itemCount = max(0, self.tags[index].itemCount - 1)
                    self.tags[index].updatedAt = Date()
                }
                continuation.resume()
            }
        }
    }
    
    public func fetchMostUsed(limit: Int) async throws -> [Tag] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let sorted = self.tags.sorted { $0.itemCount > $1.itemCount }
                let limited = Array(sorted.prefix(limit))
                continuation.resume(returning: limited)
            }
        }
    }
    
    public func findByName(_ name: String) async throws -> Tag? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let tag = self.tags.first { $0.name.lowercased() == name.lowercased() }
                continuation.resume(returning: tag)
            }
        }
    }
}