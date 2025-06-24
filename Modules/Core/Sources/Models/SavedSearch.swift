import Foundation

/// Model representing a saved search query
/// Swift 5.9 - No Swift 6 features
public struct SavedSearch: Codable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let query: String
    public let searchType: SearchHistoryEntry.SearchType
    public let criteria: ItemSearchCriteria?
    public let color: String
    public let icon: String
    public let createdAt: Date
    public let lastUsedAt: Date
    public let useCount: Int
    public let isPinned: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        query: String,
        searchType: SearchHistoryEntry.SearchType,
        criteria: ItemSearchCriteria? = nil,
        color: String = "#4ECDC4",
        icon: String = "magnifyingglass",
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        useCount: Int = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.query = query
        self.searchType = searchType
        self.criteria = criteria
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
        self.isPinned = isPinned
    }
    
    /// Create a copy with updated usage stats
    public func withUpdatedUsage() -> SavedSearch {
        SavedSearch(
            id: id,
            name: name,
            query: query,
            searchType: searchType,
            criteria: criteria,
            color: color,
            icon: icon,
            createdAt: createdAt,
            lastUsedAt: Date(),
            useCount: useCount + 1,
            isPinned: isPinned
        )
    }
    
    /// Create a copy with updated pin status
    public func togglePinned() -> SavedSearch {
        SavedSearch(
            id: id,
            name: name,
            query: query,
            searchType: searchType,
            criteria: criteria,
            color: color,
            icon: icon,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            useCount: useCount,
            isPinned: !isPinned
        )
    }
}

// MARK: - Saved Search Repository Protocol
public protocol SavedSearchRepository {
    func fetchAll() async throws -> [SavedSearch]
    func fetchPinned() async throws -> [SavedSearch]
    func save(_ search: SavedSearch) async throws
    func update(_ search: SavedSearch) async throws
    func delete(_ search: SavedSearch) async throws
    func deleteAll() async throws
    func recordUsage(of search: SavedSearch) async throws
}

// MARK: - Available Icons
public struct SavedSearchIcon {
    public static let all = [
        "magnifyingglass",
        "star.fill",
        "heart.fill",
        "tag.fill",
        "folder.fill",
        "archivebox.fill",
        "cart.fill",
        "bag.fill",
        "house.fill",
        "location.fill",
        "calendar",
        "clock.fill",
        "dollarsign.circle.fill",
        "creditcard.fill",
        "gift.fill",
        "wrench.fill",
        "hammer.fill",
        "paintbrush.fill",
        "scissors",
        "camera.fill"
    ]
}

// MARK: - Available Colors
public struct SavedSearchColor {
    public static let all = [
        "#FF6B6B", // Red
        "#4ECDC4", // Teal
        "#45B7D1", // Blue
        "#96CEB4", // Green
        "#FECA57", // Yellow
        "#FF9FF3", // Pink
        "#DDA0DD", // Plum
        "#98D8C8", // Mint
        "#F7DC6F", // Light Yellow
        "#BB8FCE", // Purple
        "#85C1E2", // Sky Blue
        "#F8B500", // Orange
        "#7FB3D5", // Light Blue
        "#C39BD3", // Lavender
        "#7DCEA0", // Sea Green
    ]
}