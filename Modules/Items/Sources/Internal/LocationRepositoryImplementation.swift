import Foundation
import Core

/// Mock implementation of LocationRepository for development
final class LocationRepositoryImplementation: LocationRepository {
    private var locations: [Location] = []
    private let queue = DispatchQueue(label: "com.homeinventory.locations", attributes: .concurrent)
    
    init() {
        // Initialize with comprehensive mock locations
        self.locations = MockDataService.locations
    }
    
    // MARK: - Repository Protocol
    
    func fetchAll() async throws -> [Location] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.locations)
            }
        }
    }
    
    func fetch(id: UUID) async throws -> Location? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let location = self.locations.first { $0.id == id }
                continuation.resume(returning: location)
            }
        }
    }
    
    func save(_ entity: Location) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.locations.firstIndex(where: { $0.id == entity.id }) {
                    self.locations[index] = entity
                } else {
                    self.locations.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    func saveAll(_ entities: [Location]) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                for entity in entities {
                    if let index = self.locations.firstIndex(where: { $0.id == entity.id }) {
                        self.locations[index] = entity
                    } else {
                        self.locations.append(entity)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func delete(_ entity: Location) async throws {
        try await delete(id: entity.id)
    }
    
    func delete(id: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.locations.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    // MARK: - LocationRepository Protocol
    
    func fetchRootLocations() async throws -> [Location] {
        // For now, all locations are root locations
        return try await fetchAll()
    }
    
    func fetchChildren(of parentId: UUID) async throws -> [Location] {
        // No hierarchy implemented yet
        return []
    }
    
    // MARK: - Helper Methods
    
    func getAllLocations() async throws -> [Location] {
        return try await fetchAll()
    }
}