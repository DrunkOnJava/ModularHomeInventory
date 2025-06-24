import Foundation

/// Model representing a scan history entry
/// Swift 5.9 - No Swift 6 features
public struct ScanHistoryEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let barcode: String
    public let scanDate: Date
    public let scanType: ScanType
    public var itemId: UUID?
    public var itemName: String?
    public var itemThumbnail: String?
    
    public enum ScanType: String, Codable {
        case single = "Single"
        case batch = "Batch"
        case continuous = "Continuous"
    }
    
    public init(
        id: UUID = UUID(),
        barcode: String,
        scanDate: Date = Date(),
        scanType: ScanType,
        itemId: UUID? = nil,
        itemName: String? = nil,
        itemThumbnail: String? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.scanDate = scanDate
        self.scanType = scanType
        self.itemId = itemId
        self.itemName = itemName
        self.itemThumbnail = itemThumbnail
    }
}

// MARK: - Preview Data
extension ScanHistoryEntry {
    public static let previews: [ScanHistoryEntry] = [
        ScanHistoryEntry(
            barcode: "012345678901",
            scanDate: Date().addingTimeInterval(-300), // 5 minutes ago
            scanType: .single,
            itemId: UUID(),
            itemName: "Apple AirPods Pro",
            itemThumbnail: "airpods"
        ),
        ScanHistoryEntry(
            barcode: "098765432109",
            scanDate: Date().addingTimeInterval(-1800), // 30 minutes ago
            scanType: .batch,
            itemId: UUID(),
            itemName: "Nintendo Switch Pro Controller",
            itemThumbnail: "controller"
        ),
        ScanHistoryEntry(
            barcode: "112233445566",
            scanDate: Date().addingTimeInterval(-3600), // 1 hour ago
            scanType: .continuous,
            itemId: nil,
            itemName: nil,
            itemThumbnail: nil
        ),
        ScanHistoryEntry(
            barcode: "667788990011",
            scanDate: Date().addingTimeInterval(-7200), // 2 hours ago
            scanType: .single,
            itemId: UUID(),
            itemName: "Sony WH-1000XM4 Headphones",
            itemThumbnail: "headphones"
        ),
        ScanHistoryEntry(
            barcode: "223344556677",
            scanDate: Date().addingTimeInterval(-86400), // 1 day ago
            scanType: .batch,
            itemId: UUID(),
            itemName: "Logitech MX Master 3",
            itemThumbnail: "mouse"
        )
    ]
}