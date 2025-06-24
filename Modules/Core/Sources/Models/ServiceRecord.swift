import Foundation

/// Represents a service or maintenance record for an item
public struct ServiceRecord: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let itemId: UUID
    public var warrantyId: UUID? // Link to warranty if service was under warranty
    public var type: ServiceType
    public var date: Date
    public var provider: String
    public var technician: String?
    public var description: String
    public var notes: String?
    public var cost: Decimal?
    public var wasUnderWarranty: Bool
    public var documentIds: [UUID]
    public var nextServiceDate: Date?
    public var mileage: Int? // For vehicles
    public var hoursUsed: Int? // For equipment with hour meters
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        warrantyId: UUID? = nil,
        type: ServiceType,
        date: Date = Date(),
        provider: String,
        technician: String? = nil,
        description: String,
        notes: String? = nil,
        cost: Decimal? = nil,
        wasUnderWarranty: Bool = false,
        documentIds: [UUID] = [],
        nextServiceDate: Date? = nil,
        mileage: Int? = nil,
        hoursUsed: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.warrantyId = warrantyId
        self.type = type
        self.date = date
        self.provider = provider
        self.technician = technician
        self.description = description
        self.notes = notes
        self.cost = cost
        self.wasUnderWarranty = wasUnderWarranty
        self.documentIds = documentIds
        self.nextServiceDate = nextServiceDate
        self.mileage = mileage
        self.hoursUsed = hoursUsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Service Type
public enum ServiceType: String, Codable, CaseIterable, Hashable, Sendable {
    case maintenance = "maintenance"
    case repair = "repair"
    case inspection = "inspection"
    case upgrade = "upgrade"
    case cleaning = "cleaning"
    case calibration = "calibration"
    case replacement = "replacement"
    case recall = "recall"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .maintenance: return "Routine Maintenance"
        case .repair: return "Repair"
        case .inspection: return "Inspection"
        case .upgrade: return "Upgrade/Modification"
        case .cleaning: return "Cleaning"
        case .calibration: return "Calibration"
        case .replacement: return "Part Replacement"
        case .recall: return "Recall Service"
        case .other: return "Other Service"
        }
    }
    
    public var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "hammer"
        case .inspection: return "magnifyingglass"
        case .upgrade: return "arrow.up.square"
        case .cleaning: return "sparkles"
        case .calibration: return "slider.horizontal.3"
        case .replacement: return "arrow.triangle.2.circlepath"
        case .recall: return "exclamationmark.triangle"
        case .other: return "ellipsis.circle"
        }
    }
    
    public var color: String {
        switch self {
        case .maintenance: return "blue"
        case .repair: return "orange"
        case .inspection: return "purple"
        case .upgrade: return "green"
        case .cleaning: return "cyan"
        case .calibration: return "indigo"
        case .replacement: return "yellow"
        case .recall: return "red"
        case .other: return "gray"
        }
    }
}

// MARK: - Preview Data
extension ServiceRecord {
    public static var preview: ServiceRecord {
        ServiceRecord(
            itemId: UUID(),
            type: .maintenance,
            date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            provider: "Authorized Service Center",
            technician: "John Smith",
            description: "Annual maintenance service",
            notes: "Replaced filters, checked all systems",
            cost: 149.99,
            wasUnderWarranty: false,
            nextServiceDate: Date().addingTimeInterval(335 * 24 * 60 * 60)
        )
    }
    
    public static var previews: [ServiceRecord] {
        [
            ServiceRecord(
                itemId: UUID(),
                type: .maintenance,
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                provider: "Authorized Service Center",
                description: "Annual maintenance",
                cost: 149.99,
                wasUnderWarranty: false
            ),
            ServiceRecord(
                itemId: UUID(),
                type: .repair,
                date: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                provider: "Local Repair Shop",
                description: "Fixed power issue",
                cost: 89.00,
                wasUnderWarranty: true
            ),
            ServiceRecord(
                itemId: UUID(),
                type: .recall,
                date: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                provider: "Manufacturer",
                description: "Safety recall - replaced component",
                cost: 0,
                wasUnderWarranty: true
            )
        ]
    }
}