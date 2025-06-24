import Foundation

/// Represents a tag that can be applied to items
/// Swift 5.9 - No Swift 6 features
public struct Tag: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var color: String
    public var icon: String?
    public var itemCount: Int
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = "blue",
        icon: String? = nil,
        itemCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.itemCount = itemCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Tag {
    static let previews: [Tag] = [
        Tag(name: "Electronics", color: "blue", icon: "tv", itemCount: 15),
        Tag(name: "Vintage", color: "brown", icon: "clock", itemCount: 8),
        Tag(name: "Gift", color: "pink", icon: "gift", itemCount: 12),
        Tag(name: "Work", color: "purple", icon: "briefcase", itemCount: 24),
        Tag(name: "Travel", color: "orange", icon: "airplane", itemCount: 6),
        Tag(name: "Outdoor", color: "green", icon: "leaf", itemCount: 10),
        Tag(name: "Kitchen", color: "red", icon: "fork.knife", itemCount: 18),
        Tag(name: "Gaming", color: "indigo", icon: "gamecontroller", itemCount: 9)
    ]
}