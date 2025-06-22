import Foundation

/// Receipt domain model
/// Swift 5.9 - No Swift 6 features
public struct Receipt: Identifiable, Codable, Equatable {
    public let id: UUID
    public var storeName: String
    public var date: Date
    public var totalAmount: Decimal
    public var itemIds: [UUID]
    public var imageData: Data?
    public var rawText: String?
    public var confidence: Double
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        storeName: String,
        date: Date,
        totalAmount: Decimal,
        itemIds: [UUID] = [],
        imageData: Data? = nil,
        rawText: String? = nil,
        confidence: Double = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.itemIds = itemIds
        self.imageData = imageData
        self.rawText = rawText
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sample Data
public extension Receipt {
    static let preview = Receipt(
        storeName: "Whole Foods Market",
        date: Date().addingTimeInterval(-86400), // Yesterday
        totalAmount: 157.42,
        itemIds: [UUID(), UUID(), UUID()],
        confidence: 0.95
    )
    
    static let previews: [Receipt] = [
        Receipt(
            storeName: "Whole Foods Market",
            date: Date().addingTimeInterval(-86400),
            totalAmount: 157.42,
            itemIds: [UUID(), UUID(), UUID()],
            confidence: 0.95
        ),
        Receipt(
            storeName: "Target",
            date: Date().addingTimeInterval(-172800),
            totalAmount: 89.99,
            itemIds: [UUID(), UUID()],
            confidence: 0.88
        ),
        Receipt(
            storeName: "Home Depot",
            date: Date().addingTimeInterval(-259200),
            totalAmount: 234.56,
            itemIds: [UUID(), UUID(), UUID(), UUID()],
            confidence: 0.92
        )
    ]
}