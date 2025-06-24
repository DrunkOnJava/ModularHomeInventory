import Foundation

/// Category model supporting both built-in and custom categories
/// Swift 5.9 - No Swift 6 features
public struct ItemCategoryModel: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var color: String
    public var isBuiltIn: Bool
    public var parentId: UUID? // For future subcategory support
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String = "blue",
        isBuiltIn: Bool = false,
        parentId: UUID? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isBuiltIn = isBuiltIn
        self.parentId = parentId
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Built-in Categories
public extension ItemCategoryModel {
    static let builtInCategories: [ItemCategoryModel] = [
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Electronics",
            icon: "tv",
            color: "blue",
            isBuiltIn: true,
            sortOrder: 1
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Furniture",
            icon: "chair",
            color: "brown",
            isBuiltIn: true,
            sortOrder: 2
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Clothing",
            icon: "tshirt",
            color: "purple",
            isBuiltIn: true,
            sortOrder: 3
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Books",
            icon: "book",
            color: "orange",
            isBuiltIn: true,
            sortOrder: 4
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Kitchen",
            icon: "fork.knife",
            color: "red",
            isBuiltIn: true,
            sortOrder: 5
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Tools",
            icon: "wrench",
            color: "gray",
            isBuiltIn: true,
            sortOrder: 6
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            name: "Sports",
            icon: "sportscourt",
            color: "green",
            isBuiltIn: true,
            sortOrder: 7
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            name: "Toys",
            icon: "teddybear",
            color: "pink",
            isBuiltIn: true,
            sortOrder: 8
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            name: "Jewelry",
            icon: "sparkles",
            color: "yellow",
            isBuiltIn: true,
            sortOrder: 9
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            name: "Art",
            icon: "paintpalette",
            color: "indigo",
            isBuiltIn: true,
            sortOrder: 10
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            name: "Collectibles",
            icon: "star",
            color: "gold",
            isBuiltIn: true,
            sortOrder: 11
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            name: "Appliances",
            icon: "washer",
            color: "cyan",
            isBuiltIn: true,
            sortOrder: 12
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
            name: "Outdoor",
            icon: "tent",
            color: "mint",
            isBuiltIn: true,
            sortOrder: 13
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
            name: "Office",
            icon: "paperclip",
            color: "teal",
            isBuiltIn: true,
            sortOrder: 14
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!,
            name: "Automotive",
            icon: "car",
            color: "navy",
            isBuiltIn: true,
            sortOrder: 15
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000016")!,
            name: "Health",
            icon: "heart",
            color: "pink",
            isBuiltIn: true,
            sortOrder: 16
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            name: "Beauty",
            icon: "eyebrow",
            color: "rose",
            isBuiltIn: true,
            sortOrder: 17
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!,
            name: "Home",
            icon: "house",
            color: "amber",
            isBuiltIn: true,
            sortOrder: 18
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!,
            name: "Garden",
            icon: "leaf",
            color: "lime",
            isBuiltIn: true,
            sortOrder: 19
        ),
        ItemCategoryModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
            name: "Other",
            icon: "square.grid.2x2",
            color: "gray",
            isBuiltIn: true,
            sortOrder: 20
        )
    ]
    
    static let defaultCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000020")! // Other
}

// MARK: - Migration Helper
public extension ItemCategoryModel {
    /// Convert from old ItemCategory enum to new Category
    static func fromItemCategory(_ itemCategory: ItemCategory) -> UUID {
        switch itemCategory {
        case .electronics: return builtInCategories[0].id
        case .furniture: return builtInCategories[1].id
        case .clothing: return builtInCategories[2].id
        case .books: return builtInCategories[3].id
        case .kitchen: return builtInCategories[4].id
        case .tools: return builtInCategories[5].id
        case .sports: return builtInCategories[6].id
        case .toys: return builtInCategories[7].id
        case .jewelry: return builtInCategories[8].id
        case .art: return builtInCategories[9].id
        case .collectibles: return builtInCategories[10].id
        case .appliances: return builtInCategories[11].id
        case .outdoor: return builtInCategories[12].id
        case .office: return builtInCategories[13].id
        case .automotive: return builtInCategories[14].id
        case .health: return builtInCategories[15].id
        case .beauty: return builtInCategories[16].id
        case .home: return builtInCategories[17].id
        case .garden: return builtInCategories[18].id
        case .other: return builtInCategories[19].id
        }
    }
}