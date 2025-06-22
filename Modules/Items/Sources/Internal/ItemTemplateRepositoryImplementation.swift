import Foundation
import Core

/// Mock implementation of ItemTemplateRepository for development
final class ItemTemplateRepositoryImplementation: ItemTemplateRepository {
    private var templates: [ItemTemplate] = ItemTemplate.previews
    private let queue = DispatchQueue(label: "com.homeinventory.templaterepository", attributes: .concurrent)
    
    func fetchAll() async throws -> [ItemTemplate] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.templates)
            }
        }
    }
    
    func fetch(id: UUID) async throws -> ItemTemplate? {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let template = self.templates.first { $0.id == id }
                continuation.resume(returning: template)
            }
        }
    }
    
    func save(_ entity: ItemTemplate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if let index = self.templates.firstIndex(where: { $0.id == entity.id }) {
                    self.templates[index] = entity
                } else {
                    self.templates.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    func saveAll(_ entities: [ItemTemplate]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for entity in entities {
                    if let index = self.templates.firstIndex(where: { $0.id == entity.id }) {
                        self.templates[index] = entity
                    } else {
                        self.templates.append(entity)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func delete(_ entity: ItemTemplate) async throws {
        try await delete(id: entity.id)
    }
    
    func delete(id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.templates.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - ItemTemplateRepository Methods
    
    func fetchByCategory(_ category: ItemCategory) async throws -> [ItemTemplate] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let results = self.templates.filter { $0.category == category }
                continuation.resume(returning: results)
            }
        }
    }
    
    func search(query: String) async throws -> [ItemTemplate] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let results = self.templates.filter { template in
                    template.name.localizedCaseInsensitiveContains(query) ||
                    template.templateName.localizedCaseInsensitiveContains(query) ||
                    (template.brand?.localizedCaseInsensitiveContains(query) ?? false) ||
                    template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                }
                continuation.resume(returning: results)
            }
        }
    }
}