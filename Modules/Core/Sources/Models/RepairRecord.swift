import Foundation

/// Represents a repair record for an item
public struct RepairRecord: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let itemId: UUID
    public var serviceRecordId: UUID? // Link to service record if part of a service
    public var warrantyId: UUID? // Link to warranty if repair was under warranty
    public var date: Date
    public var completionDate: Date?
    public var status: RepairStatus
    public var priority: RepairPriority
    public var issue: String
    public var diagnosis: String?
    public var resolution: String?
    public var provider: String
    public var technician: String?
    public var trackingNumber: String?
    public var cost: RepairCost
    public var partsUsed: [RepairPart]
    public var documentIds: [UUID]
    public var photoIds: [UUID]
    public var notes: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        serviceRecordId: UUID? = nil,
        warrantyId: UUID? = nil,
        date: Date = Date(),
        completionDate: Date? = nil,
        status: RepairStatus = .pending,
        priority: RepairPriority = .normal,
        issue: String,
        diagnosis: String? = nil,
        resolution: String? = nil,
        provider: String,
        technician: String? = nil,
        trackingNumber: String? = nil,
        cost: RepairCost = RepairCost(),
        partsUsed: [RepairPart] = [],
        documentIds: [UUID] = [],
        photoIds: [UUID] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.serviceRecordId = serviceRecordId
        self.warrantyId = warrantyId
        self.date = date
        self.completionDate = completionDate
        self.status = status
        self.priority = priority
        self.issue = issue
        self.diagnosis = diagnosis
        self.resolution = resolution
        self.provider = provider
        self.technician = technician
        self.trackingNumber = trackingNumber
        self.cost = cost
        self.partsUsed = partsUsed
        self.documentIds = documentIds
        self.photoIds = photoIds
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Types

public enum RepairStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case pending = "pending"
    case inProgress = "in_progress"
    case awaitingParts = "awaiting_parts"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .awaitingParts: return "Awaiting Parts"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "wrench.and.screwdriver"
        case .awaitingParts: return "shippingbox"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .inProgress: return "blue"
        case .awaitingParts: return "purple"
        case .completed: return "green"
        case .cancelled: return "gray"
        }
    }
}

public enum RepairPriority: String, Codable, CaseIterable, Hashable, Sendable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "gray"
        case .normal: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

public struct RepairCost: Codable, Hashable, Sendable {
    public var labor: Decimal
    public var parts: Decimal
    public var shipping: Decimal
    public var tax: Decimal
    public var other: Decimal
    public var wasUnderWarranty: Bool
    public var warrantyCovered: Decimal // Amount covered by warranty
    
    public var subtotal: Decimal {
        labor + parts + shipping + other
    }
    
    public var total: Decimal {
        subtotal + tax
    }
    
    public var outOfPocket: Decimal {
        max(0, total - warrantyCovered)
    }
    
    public init(
        labor: Decimal = 0,
        parts: Decimal = 0,
        shipping: Decimal = 0,
        tax: Decimal = 0,
        other: Decimal = 0,
        wasUnderWarranty: Bool = false,
        warrantyCovered: Decimal = 0
    ) {
        self.labor = labor
        self.parts = parts
        self.shipping = shipping
        self.tax = tax
        self.other = other
        self.wasUnderWarranty = wasUnderWarranty
        self.warrantyCovered = warrantyCovered
    }
}

public struct RepairPart: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var partNumber: String?
    public var manufacturer: String?
    public var quantity: Int
    public var unitCost: Decimal
    public var notes: String?
    
    public var totalCost: Decimal {
        unitCost * Decimal(quantity)
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        partNumber: String? = nil,
        manufacturer: String? = nil,
        quantity: Int = 1,
        unitCost: Decimal,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.manufacturer = manufacturer
        self.quantity = quantity
        self.unitCost = unitCost
        self.notes = notes
    }
}

// MARK: - Computed Properties
extension RepairRecord {
    public var isCompleted: Bool {
        status == .completed
    }
    
    public var isActive: Bool {
        status == .inProgress || status == .awaitingParts
    }
    
    public var duration: TimeInterval? {
        guard let completionDate = completionDate else { return nil }
        return completionDate.timeIntervalSince(date)
    }
    
    public var durationDays: Int? {
        guard let duration = duration else { return nil }
        return Int(duration / (24 * 60 * 60))
    }
}

// MARK: - Preview Data
extension RepairRecord {
    public static var preview: RepairRecord {
        RepairRecord(
            itemId: UUID(),
            date: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            status: .inProgress,
            priority: .normal,
            issue: "Device not powering on",
            diagnosis: "Power supply failure",
            provider: "Tech Repair Center",
            technician: "Jane Doe",
            cost: RepairCost(
                labor: 75,
                parts: 45,
                tax: 10.50,
                wasUnderWarranty: false
            ),
            partsUsed: [
                RepairPart(
                    name: "Power Supply Unit",
                    partNumber: "PSU-12345",
                    manufacturer: "OEM",
                    quantity: 1,
                    unitCost: 45
                )
            ]
        )
    }
    
    public static var previews: [RepairRecord] {
        [
            RepairRecord(
                itemId: UUID(),
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                completionDate: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                status: .completed,
                priority: .high,
                issue: "Screen cracked",
                diagnosis: "Impact damage to display",
                resolution: "Replaced display assembly",
                provider: "Authorized Service",
                cost: RepairCost(
                    labor: 150,
                    parts: 299,
                    tax: 39.29,
                    wasUnderWarranty: false
                )
            ),
            RepairRecord(
                itemId: UUID(),
                date: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                status: .awaitingParts,
                priority: .normal,
                issue: "Battery not holding charge",
                diagnosis: "Battery degradation",
                provider: "Local Repair Shop",
                trackingNumber: "SHIP123456",
                cost: RepairCost(
                    labor: 50,
                    parts: 89,
                    wasUnderWarranty: true,
                    warrantyCovered: 139
                )
            ),
            RepairRecord(
                itemId: UUID(),
                date: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                completionDate: Date().addingTimeInterval(-58 * 24 * 60 * 60),
                status: .completed,
                priority: .urgent,
                issue: "Complete failure - recall",
                diagnosis: "Manufacturing defect",
                resolution: "Unit replaced under recall",
                provider: "Manufacturer",
                cost: RepairCost(
                    wasUnderWarranty: true,
                    warrantyCovered: 0
                )
            )
        ]
    }
}