import Foundation

/// Core Item model representing an inventory item
public struct Item: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var brand: String?
    public var model: String?
    public var category: ItemCategory // Deprecated - use categoryId
    public var categoryId: UUID
    public var condition: ItemCondition
    public var quantity: Int
    public var value: Decimal?
    public var purchasePrice: Decimal?
    public var purchaseDate: Date?
    public var notes: String?
    public var barcode: String?
    public var serialNumber: String?
    public var tags: [String]
    public var imageIds: [UUID]
    public var locationId: UUID?
    public var storageUnitId: UUID?
    public var warrantyId: UUID?
    public var storeName: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        model: String? = nil,
        category: ItemCategory = .other,
        categoryId: UUID? = nil,
        condition: ItemCondition = .good,
        quantity: Int = 1,
        value: Decimal? = nil,
        purchasePrice: Decimal? = nil,
        purchaseDate: Date? = nil,
        notes: String? = nil,
        barcode: String? = nil,
        serialNumber: String? = nil,
        tags: [String] = [],
        imageIds: [UUID] = [],
        locationId: UUID? = nil,
        storageUnitId: UUID? = nil,
        warrantyId: UUID? = nil,
        storeName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.category = category
        self.categoryId = categoryId ?? ItemCategoryModel.fromItemCategory(category)
        self.condition = condition
        self.quantity = quantity
        self.value = value
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.barcode = barcode
        self.serialNumber = serialNumber
        self.tags = tags
        self.imageIds = imageIds
        self.locationId = locationId
        self.storageUnitId = storageUnitId
        self.warrantyId = warrantyId
        self.storeName = storeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Data
public extension Item {
    static let preview = Item(
        name: "iPhone 15 Pro",
        brand: "Apple",
        model: "A3102",
        category: .electronics,
        condition: .excellent,
        value: 999.00,
        purchasePrice: 999.00,
        purchaseDate: Date(),
        notes: "256GB Space Black",
        tags: ["phone", "work"],
        storeName: "Apple Store"
    )
    
    static let previews: [Item] = [
        preview,
        Item(
            name: "Office Chair",
            brand: "Herman Miller",
            model: "Aeron",
            category: .furniture,
            condition: .good,
            value: 1200.00,
            tags: ["office", "furniture"],
            storeName: "Herman Miller Store"
        ),
        Item(
            name: "Running Shoes",
            brand: "Nike",
            model: "Air Zoom Pegasus",
            category: .clothing,
            condition: .fair,
            quantity: 1,
            value: 120.00,
            tags: ["sports", "shoes"],
            storeName: "Nike Store"
        )
    ]
}