import Foundation

/// A collection groups related items together
/// Swift 5.9 - No Swift 6 features
public struct Collection: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var icon: String
    public var color: String
    public var itemIds: [UUID]
    public var isArchived: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        icon: String = "folder",
        color: String = "blue",
        itemIds: [UUID] = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.itemIds = itemIds
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Collection {
    static let preview = Collection(
        name: "Summer Vacation Gear",
        description: "Everything needed for beach trips",
        icon: "sun.max",
        color: "orange",
        itemIds: []
    )
    
    static let previews: [Collection] = [
        preview,
        Collection(
            name: "Home Office Setup",
            description: "Work from home equipment",
            icon: "desktopcomputer",
            color: "purple",
            itemIds: []
        ),
        Collection(
            name: "Emergency Kit",
            description: "Essential items for emergencies",
            icon: "cross.case",
            color: "red",
            itemIds: []
        ),
        Collection(
            name: "Travel Essentials",
            description: "Must-have items for trips",
            icon: "airplane",
            color: "blue",
            itemIds: []
        )
    ]
}