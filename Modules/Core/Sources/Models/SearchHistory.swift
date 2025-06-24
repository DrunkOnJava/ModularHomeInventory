import Foundation

/// Model representing a search history entry
/// Swift 5.9 - No Swift 6 features
public struct SearchHistoryEntry: Codable, Identifiable, Equatable {
    public let id: UUID
    public let query: String
    public let searchType: SearchType
    public let timestamp: Date
    public let resultCount: Int
    
    public enum SearchType: String, Codable, CaseIterable {
        case natural = "natural"
        case barcode = "barcode"
        case advanced = "advanced"
        
        public var icon: String {
            switch self {
            case .natural:
                return "magnifyingglass"
            case .barcode:
                return "barcode.viewfinder"
            case .advanced:
                return "slider.horizontal.3"
            }
        }
        
        public var displayName: String {
            switch self {
            case .natural:
                return "Natural Language"
            case .barcode:
                return "Barcode"
            case .advanced:
                return "Advanced"
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        query: String,
        searchType: SearchType,
        timestamp: Date = Date(),
        resultCount: Int = 0
    ) {
        self.id = id
        self.query = query
        self.searchType = searchType
        self.timestamp = timestamp
        self.resultCount = resultCount
    }
}

// MARK: - Search History Repository Protocol
public protocol SearchHistoryRepository {
    func fetchRecent(limit: Int) async throws -> [SearchHistoryEntry]
    func save(_ entry: SearchHistoryEntry) async throws
    func delete(_ entry: SearchHistoryEntry) async throws
    func deleteAll() async throws
    func search(query: String) async throws -> [SearchHistoryEntry]
}