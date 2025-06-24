import Foundation

/// Default implementation of SavedSearchRepository using UserDefaults
/// Swift 5.9 - No Swift 6 features
public final class DefaultSavedSearchRepository: SavedSearchRepository {
    private let userDefaults: UserDefaults
    private let storageKey = "SavedSearches"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func fetchAll() async throws -> [SavedSearch] {
        guard let data = userDefaults.data(forKey: storageKey),
              let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) else {
            return []
        }
        
        // Sort by pinned first, then by last used date
        return searches.sorted { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            return first.lastUsedAt > second.lastUsedAt
        }
    }
    
    public func fetchPinned() async throws -> [SavedSearch] {
        let all = try await fetchAll()
        return all.filter { $0.isPinned }
    }
    
    public func save(_ search: SavedSearch) async throws {
        var searches = try await fetchAll()
        
        // Remove any existing search with same ID
        searches.removeAll { $0.id == search.id }
        
        // Add new search
        searches.append(search)
        
        // Save back
        let data = try JSONEncoder().encode(searches)
        userDefaults.set(data, forKey: storageKey)
    }
    
    public func update(_ search: SavedSearch) async throws {
        // Same as save for this implementation
        try await save(search)
    }
    
    public func delete(_ search: SavedSearch) async throws {
        var searches = try await fetchAll()
        searches.removeAll { $0.id == search.id }
        
        let data = try JSONEncoder().encode(searches)
        userDefaults.set(data, forKey: storageKey)
    }
    
    public func deleteAll() async throws {
        userDefaults.removeObject(forKey: storageKey)
    }
    
    public func recordUsage(of search: SavedSearch) async throws {
        let updatedSearch = search.withUpdatedUsage()
        try await update(updatedSearch)
    }
}