import Foundation

/// Location model for organizing where items are stored
public struct Location: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var parentId: UUID?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "location",
        parentId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.parentId = parentId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Full path including parent locations
    public func fullPath(with allLocations: [Location]) -> String {
        var path = [name]
        var currentParentId = parentId
        
        while let parentId = currentParentId {
            if let parent = allLocations.first(where: { $0.id == parentId }) {
                path.insert(parent.name, at: 0)
                currentParentId = parent.parentId
            } else {
                break
            }
        }
        
        return path.joined(separator: " > ")
    }
}

// MARK: - Preview Data
public extension Location {
    static let preview = Location(name: "Home", icon: "house")
    
    static let previews: [Location] = [
        Location(id: UUID(), name: "Home", icon: "house"),
        Location(id: UUID(), name: "Living Room", icon: "sofa", parentId: UUID()),
        Location(id: UUID(), name: "Bedroom", icon: "bed.double", parentId: UUID()),
        Location(id: UUID(), name: "Kitchen", icon: "refrigerator", parentId: UUID()),
        Location(id: UUID(), name: "Garage", icon: "car.fill", parentId: UUID()),
        Location(id: UUID(), name: "Office", icon: "desktopcomputer", parentId: UUID())
    ]
}