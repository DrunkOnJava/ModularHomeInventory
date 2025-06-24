import Foundation

/// Default implementation of SearchHistoryRepository using UserDefaults
/// Swift 5.9 - No Swift 6 features
public final class DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let userDefaults: UserDefaults
    private let storageKey = "SearchHistory"
    private let maxHistoryItems = 50
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func fetchRecent(limit: Int) async throws -> [SearchHistoryEntry] {
        guard let data = userDefaults.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([SearchHistoryEntry].self, from: data) else {
            return []
        }
        
        // Return most recent entries first, limited by the requested count
        return Array(entries.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
    
    public func save(_ entry: SearchHistoryEntry) async throws {
        var entries = try await fetchRecent(limit: maxHistoryItems)
        
        // Remove duplicate queries of the same type
        entries.removeAll { $0.query == entry.query && $0.searchType == entry.searchType }
        
        // Add new entry at the beginning
        entries.insert(entry, at: 0)
        
        // Keep only the most recent entries
        if entries.count > maxHistoryItems {
            entries = Array(entries.prefix(maxHistoryItems))
        }
        
        let data = try JSONEncoder().encode(entries)
        userDefaults.set(data, forKey: storageKey)
    }
    
    public func delete(_ entry: SearchHistoryEntry) async throws {
        var entries = try await fetchRecent(limit: maxHistoryItems)
        entries.removeAll { $0.id == entry.id }
        
        let data = try JSONEncoder().encode(entries)
        userDefaults.set(data, forKey: storageKey)
    }
    
    public func deleteAll() async throws {
        userDefaults.removeObject(forKey: storageKey)
    }
    
    public func search(query: String) async throws -> [SearchHistoryEntry] {
        let entries = try await fetchRecent(limit: maxHistoryItems)
        let lowercasedQuery = query.lowercased()
        
        return entries.filter { entry in
            entry.query.lowercased().contains(lowercasedQuery)
        }
    }
}