import Foundation

/// Template for quickly creating similar items
public struct ItemTemplate: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let templateName: String
    public let brand: String?
    public let model: String?
    public let category: ItemCategory
    public let condition: ItemCondition
    public let tags: [String]
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        templateName: String,
        brand: String? = nil,
        model: String? = nil,
        category: ItemCategory,
        condition: ItemCondition = .good,
        tags: [String] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateName = templateName
        self.brand = brand
        self.model = model
        self.category = category
        self.condition = condition
        self.tags = tags
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Previews
public extension ItemTemplate {
    static var previews: [ItemTemplate] {
        [
            ItemTemplate(
                name: "MacBook Pro",
                templateName: "Laptop Template",
                brand: "Apple",
                model: "16-inch",
                category: .electronics,
                condition: .excellent,
                tags: ["computer", "work"],
                notes: "Work laptop"
            ),
            ItemTemplate(
                name: "Office Chair",
                templateName: "Furniture Template",
                brand: "Herman Miller",
                model: "Aeron",
                category: .furniture,
                condition: .good,
                tags: ["office", "ergonomic"]
            ),
            ItemTemplate(
                name: "Power Drill",
                templateName: "Tool Template",
                brand: "DeWalt",
                model: "DCD771C2",
                category: .tools,
                condition: .good,
                tags: ["power tool", "cordless"]
            )
        ]
    }
}