import Foundation

/// Depreciation report model for tracking asset value over time
/// Swift 5.9 - No Swift 6 features
public struct DepreciationReport: Codable, Identifiable {
    public let id: UUID
    public let generatedDate: Date
    public let items: [DepreciatingItem]
    public let totalOriginalValue: Decimal
    public let totalCurrentValue: Decimal
    public let totalDepreciation: Decimal
    public let depreciationPercentage: Double
    
    public init(
        id: UUID = UUID(),
        generatedDate: Date = Date(),
        items: [DepreciatingItem] = [],
        totalOriginalValue: Decimal = 0,
        totalCurrentValue: Decimal = 0,
        totalDepreciation: Decimal = 0,
        depreciationPercentage: Double = 0
    ) {
        self.id = id
        self.generatedDate = generatedDate
        self.items = items
        self.totalOriginalValue = totalOriginalValue
        self.totalCurrentValue = totalCurrentValue
        self.totalDepreciation = totalDepreciation
        self.depreciationPercentage = depreciationPercentage
    }
}

/// Individual item depreciation data
public struct DepreciatingItem: Codable, Identifiable {
    public let id: UUID
    public let itemId: UUID
    public let itemName: String
    public let category: ItemCategory
    public let purchaseDate: Date
    public let purchasePrice: Decimal
    public let currentValue: Decimal
    public let depreciationAmount: Decimal
    public let depreciationPercentage: Double
    public let ageInYears: Double
    public let depreciationMethod: DepreciationMethod
    public let estimatedLifespan: Int? // in years
    public let salvageValue: Decimal?
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        category: ItemCategory,
        purchaseDate: Date,
        purchasePrice: Decimal,
        currentValue: Decimal,
        depreciationAmount: Decimal,
        depreciationPercentage: Double,
        ageInYears: Double,
        depreciationMethod: DepreciationMethod,
        estimatedLifespan: Int? = nil,
        salvageValue: Decimal? = nil
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.category = category
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currentValue = currentValue
        self.depreciationAmount = depreciationAmount
        self.depreciationPercentage = depreciationPercentage
        self.ageInYears = ageInYears
        self.depreciationMethod = depreciationMethod
        self.estimatedLifespan = estimatedLifespan
        self.salvageValue = salvageValue
    }
}

/// Depreciation calculation methods
public enum DepreciationMethod: String, Codable, CaseIterable {
    case straightLine = "Straight Line"
    case decliningBalance = "Declining Balance"
    case categoryBased = "Category Based"
    case custom = "Custom"
    
    public var description: String {
        switch self {
        case .straightLine:
            return "Equal depreciation each year"
        case .decliningBalance:
            return "Higher depreciation in early years"
        case .categoryBased:
            return "Based on item category defaults"
        case .custom:
            return "Custom depreciation schedule"
        }
    }
}

/// Depreciation schedule for an item
public struct DepreciationSchedule: Codable, Identifiable {
    public let id: UUID
    public let itemId: UUID
    public let method: DepreciationMethod
    public let purchasePrice: Decimal
    public let salvageValue: Decimal
    public let usefulLife: Int // in years
    public let annualDepreciation: [AnnualDepreciation]
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        method: DepreciationMethod,
        purchasePrice: Decimal,
        salvageValue: Decimal,
        usefulLife: Int,
        annualDepreciation: [AnnualDepreciation] = []
    ) {
        self.id = id
        self.itemId = itemId
        self.method = method
        self.purchasePrice = purchasePrice
        self.salvageValue = salvageValue
        self.usefulLife = usefulLife
        self.annualDepreciation = annualDepreciation
    }
}

/// Annual depreciation entry
public struct AnnualDepreciation: Codable, Identifiable {
    public let id: UUID
    public let year: Int
    public let depreciationAmount: Decimal
    public let accumulatedDepreciation: Decimal
    public let bookValue: Decimal
    
    public init(
        id: UUID = UUID(),
        year: Int,
        depreciationAmount: Decimal,
        accumulatedDepreciation: Decimal,
        bookValue: Decimal
    ) {
        self.id = id
        self.year = year
        self.depreciationAmount = depreciationAmount
        self.accumulatedDepreciation = accumulatedDepreciation
        self.bookValue = bookValue
    }
}

/// Category-specific depreciation rules
public struct CategoryDepreciationRule: Codable {
    public let category: ItemCategory
    public let defaultLifespan: Int // in years
    public let defaultMethod: DepreciationMethod
    public let salvagePercentage: Double // percentage of original value
    
    public init(
        category: ItemCategory,
        defaultLifespan: Int,
        defaultMethod: DepreciationMethod,
        salvagePercentage: Double
    ) {
        self.category = category
        self.defaultLifespan = defaultLifespan
        self.defaultMethod = defaultMethod
        self.salvagePercentage = salvagePercentage
    }
}

/// Default depreciation rules by category
public extension CategoryDepreciationRule {
    static let defaults: [ItemCategory: CategoryDepreciationRule] = [
        .electronics: CategoryDepreciationRule(
            category: .electronics,
            defaultLifespan: 5,
            defaultMethod: .decliningBalance,
            salvagePercentage: 0.1
        ),
        .appliances: CategoryDepreciationRule(
            category: .appliances,
            defaultLifespan: 10,
            defaultMethod: .straightLine,
            salvagePercentage: 0.2
        ),
        .furniture: CategoryDepreciationRule(
            category: .furniture,
            defaultLifespan: 7,
            defaultMethod: .straightLine,
            salvagePercentage: 0.15
        ),
        .tools: CategoryDepreciationRule(
            category: .tools,
            defaultLifespan: 10,
            defaultMethod: .straightLine,
            salvagePercentage: 0.25
        ),
        .sports: CategoryDepreciationRule(
            category: .sports,
            defaultLifespan: 5,
            defaultMethod: .decliningBalance,
            salvagePercentage: 0.2
        ),
        .jewelry: CategoryDepreciationRule(
            category: .jewelry,
            defaultLifespan: 0, // No depreciation
            defaultMethod: .custom,
            salvagePercentage: 1.0
        ),
        .art: CategoryDepreciationRule(
            category: .art,
            defaultLifespan: 0, // May appreciate
            defaultMethod: .custom,
            salvagePercentage: 1.0
        ),
        .collectibles: CategoryDepreciationRule(
            category: .collectibles,
            defaultLifespan: 0, // May appreciate
            defaultMethod: .custom,
            salvagePercentage: 1.0
        )
    ]
}