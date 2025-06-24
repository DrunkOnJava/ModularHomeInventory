import Foundation

/// Represents a specific storage unit within a location
/// Swift 5.9 - No Swift 6 features
public struct StorageUnit: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var type: StorageUnitType
    public var locationId: UUID
    public var description: String?
    public var dimensions: Dimensions?
    public var position: String? // e.g., "Top shelf", "Bottom drawer"
    public var capacity: Int? // Maximum number of items
    public var currentItemCount: Int
    public var photoId: UUID?
    public var notes: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: StorageUnitType,
        locationId: UUID,
        description: String? = nil,
        dimensions: Dimensions? = nil,
        position: String? = nil,
        capacity: Int? = nil,
        currentItemCount: Int = 0,
        photoId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.locationId = locationId
        self.description = description
        self.dimensions = dimensions
        self.position = position
        self.capacity = capacity
        self.currentItemCount = currentItemCount
        self.photoId = photoId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Type of storage unit
public enum StorageUnitType: String, Codable, CaseIterable {
    case shelf = "Shelf"
    case drawer = "Drawer"
    case cabinet = "Cabinet"
    case closet = "Closet"
    case box = "Box"
    case bin = "Bin"
    case container = "Container"
    case rack = "Rack"
    case pegboard = "Pegboard"
    case safe = "Safe"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .shelf: return "square.stack.3d.up"
        case .drawer: return "tray.full"
        case .cabinet: return "cabinet"
        case .closet: return "door.left.hand.closed"
        case .box: return "shippingbox"
        case .bin: return "tray.2"
        case .container: return "cube.transparent"
        case .rack: return "square.grid.3x3"
        case .pegboard: return "circle.grid.3x3"
        case .safe: return "lock.square"
        case .other: return "square.dashed"
        }
    }
}

/// Dimensions for storage units
public struct Dimensions: Codable, Equatable {
    public var width: Double
    public var height: Double
    public var depth: Double
    public var unit: MeasurementUnit
    
    public init(width: Double, height: Double, depth: Double, unit: MeasurementUnit = .inches) {
        self.width = width
        self.height = height
        self.depth = depth
        self.unit = unit
    }
    
    public var displayString: String {
        "\(width) × \(height) × \(depth) \(unit.abbreviation)"
    }
}

/// Measurement units
public enum MeasurementUnit: String, Codable, CaseIterable {
    case inches = "Inches"
    case centimeters = "Centimeters"
    case feet = "Feet"
    case meters = "Meters"
    
    public var abbreviation: String {
        switch self {
        case .inches: return "in"
        case .centimeters: return "cm"
        case .feet: return "ft"
        case .meters: return "m"
        }
    }
}

// MARK: - Preview Data
public extension StorageUnit {
    static let previews: [StorageUnit] = [
        StorageUnit(
            name: "Top Shelf",
            type: .shelf,
            locationId: UUID(),
            description: "Top shelf for seasonal items",
            dimensions: Dimensions(width: 48, height: 12, depth: 16),
            position: "Top",
            capacity: 20,
            currentItemCount: 5
        ),
        StorageUnit(
            name: "Tool Drawer",
            type: .drawer,
            locationId: UUID(),
            description: "Main tool storage",
            dimensions: Dimensions(width: 24, height: 6, depth: 18),
            position: "Workbench, 2nd drawer",
            capacity: 50,
            currentItemCount: 32
        ),
        StorageUnit(
            name: "Storage Bin A1",
            type: .bin,
            locationId: UUID(),
            description: "Clear plastic bin for electronics",
            dimensions: Dimensions(width: 16, height: 12, depth: 12),
            position: "Garage shelf unit, row A",
            currentItemCount: 15
        )
    ]
}