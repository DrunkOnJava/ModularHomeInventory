import Foundation

/// Purchase pattern analysis model for identifying buying habits
/// Swift 5.9 - No Swift 6 features
public struct PurchasePattern: Codable, Identifiable {
    public let id: UUID
    public let analysisDate: Date
    public let periodAnalyzed: DateInterval
    public let patterns: [PatternType]
    public let insights: [PatternInsight]
    public let recommendations: [PatternRecommendation]
    
    public init(
        id: UUID = UUID(),
        analysisDate: Date = Date(),
        periodAnalyzed: DateInterval,
        patterns: [PatternType] = [],
        insights: [PatternInsight] = [],
        recommendations: [PatternRecommendation] = []
    ) {
        self.id = id
        self.analysisDate = analysisDate
        self.periodAnalyzed = periodAnalyzed
        self.patterns = patterns
        self.insights = insights
        self.recommendations = recommendations
    }
}

/// Types of purchase patterns detected
public enum PatternType: Codable, Identifiable {
    case recurring(RecurringPattern)
    case seasonal(SeasonalBuyingPattern)
    case categoryPreference(CategoryPreference)
    case brandLoyalty(BrandLoyalty)
    case priceRange(PriceRangePattern)
    case shoppingTime(ShoppingTimePattern)
    case retailerPreference(RetailerPreference)
    case bulkBuying(BulkBuyingPattern)
    
    public var id: String {
        switch self {
        case .recurring(let pattern): return "recurring_\(pattern.id)"
        case .seasonal(let pattern): return "seasonal_\(pattern.id)"
        case .categoryPreference(let pattern): return "category_\(pattern.id)"
        case .brandLoyalty(let pattern): return "brand_\(pattern.id)"
        case .priceRange(let pattern): return "price_\(pattern.id)"
        case .shoppingTime(let pattern): return "time_\(pattern.id)"
        case .retailerPreference(let pattern): return "retailer_\(pattern.id)"
        case .bulkBuying(let pattern): return "bulk_\(pattern.id)"
        }
    }
}

/// Recurring purchase pattern
public struct RecurringPattern: Codable, Identifiable {
    public let id: UUID
    public let itemName: String
    public let category: ItemCategory
    public let averageInterval: TimeInterval // in days
    public let frequency: PurchaseFrequency
    public let lastPurchaseDate: Date
    public let nextExpectedDate: Date
    public let confidence: Double // 0-1
    
    public init(
        id: UUID = UUID(),
        itemName: String,
        category: ItemCategory,
        averageInterval: TimeInterval,
        frequency: PurchaseFrequency,
        lastPurchaseDate: Date,
        nextExpectedDate: Date,
        confidence: Double
    ) {
        self.id = id
        self.itemName = itemName
        self.category = category
        self.averageInterval = averageInterval
        self.frequency = frequency
        self.lastPurchaseDate = lastPurchaseDate
        self.nextExpectedDate = nextExpectedDate
        self.confidence = confidence
    }
}

/// Purchase frequency
public enum PurchaseFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case irregular = "Irregular"
    
    public var days: Double {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .annually: return 365
        case .irregular: return 0
        }
    }
}

/// Seasonal buying pattern
public struct SeasonalBuyingPattern: Codable, Identifiable {
    public let id: UUID
    public let season: Season
    public let categories: [ItemCategory]
    public let averageSpending: Decimal
    public let peakMonth: String
    public let itemCount: Int
    
    public init(
        id: UUID = UUID(),
        season: Season,
        categories: [ItemCategory],
        averageSpending: Decimal,
        peakMonth: String,
        itemCount: Int
    ) {
        self.id = id
        self.season = season
        self.categories = categories
        self.averageSpending = averageSpending
        self.peakMonth = peakMonth
        self.itemCount = itemCount
    }
}

/// Category preference pattern
public struct CategoryPreference: Codable, Identifiable {
    public let id: UUID
    public let category: ItemCategory
    public let purchaseCount: Int
    public let totalSpent: Decimal
    public let averagePrice: Decimal
    public let percentageOfTotal: Double
    public let trend: TrendDirection
    
    public init(
        id: UUID = UUID(),
        category: ItemCategory,
        purchaseCount: Int,
        totalSpent: Decimal,
        averagePrice: Decimal,
        percentageOfTotal: Double,
        trend: TrendDirection
    ) {
        self.id = id
        self.category = category
        self.purchaseCount = purchaseCount
        self.totalSpent = totalSpent
        self.averagePrice = averagePrice
        self.percentageOfTotal = percentageOfTotal
        self.trend = trend
    }
}

/// Brand loyalty pattern
public struct BrandLoyalty: Codable, Identifiable {
    public let id: UUID
    public let brand: String
    public let category: ItemCategory
    public let purchaseCount: Int
    public let loyaltyScore: Double // 0-1
    public let averageRating: Double?
    public let totalSpent: Decimal
    
    public init(
        id: UUID = UUID(),
        brand: String,
        category: ItemCategory,
        purchaseCount: Int,
        loyaltyScore: Double,
        averageRating: Double? = nil,
        totalSpent: Decimal
    ) {
        self.id = id
        self.brand = brand
        self.category = category
        self.purchaseCount = purchaseCount
        self.loyaltyScore = loyaltyScore
        self.averageRating = averageRating
        self.totalSpent = totalSpent
    }
}

/// Price range pattern
public struct PriceRangePattern: Codable, Identifiable {
    public let id: UUID
    public let category: ItemCategory
    public let minPrice: Decimal
    public let maxPrice: Decimal
    public let averagePrice: Decimal
    public let sweetSpot: Decimal // Most common price point
    public let priceDistribution: [PriceRange: Int]
    
    public init(
        id: UUID = UUID(),
        category: ItemCategory,
        minPrice: Decimal,
        maxPrice: Decimal,
        averagePrice: Decimal,
        sweetSpot: Decimal,
        priceDistribution: [PriceRange: Int]
    ) {
        self.id = id
        self.category = category
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.averagePrice = averagePrice
        self.sweetSpot = sweetSpot
        self.priceDistribution = priceDistribution
    }
}

/// Price range buckets
public enum PriceRange: String, Codable, CaseIterable {
    case under10 = "Under $10"
    case range10to25 = "$10-25"
    case range25to50 = "$25-50"
    case range50to100 = "$50-100"
    case range100to250 = "$100-250"
    case range250to500 = "$250-500"
    case range500to1000 = "$500-1000"
    case over1000 = "Over $1000"
}

/// Shopping time pattern
public struct ShoppingTimePattern: Codable, Identifiable {
    public let id: UUID
    public let preferredDayOfWeek: String
    public let preferredTimeOfDay: TimeOfDay
    public let weekendVsWeekday: WeekdayPreference
    public let monthlyDistribution: [Int: Int] // day of month: count
    
    public init(
        id: UUID = UUID(),
        preferredDayOfWeek: String,
        preferredTimeOfDay: TimeOfDay,
        weekendVsWeekday: WeekdayPreference,
        monthlyDistribution: [Int: Int]
    ) {
        self.id = id
        self.preferredDayOfWeek = preferredDayOfWeek
        self.preferredTimeOfDay = preferredTimeOfDay
        self.weekendVsWeekday = weekendVsWeekday
        self.monthlyDistribution = monthlyDistribution
    }
}

/// Time of day preference
public enum TimeOfDay: String, Codable, CaseIterable {
    case earlyMorning = "Early Morning (6-9am)"
    case morning = "Morning (9am-12pm)"
    case afternoon = "Afternoon (12-5pm)"
    case evening = "Evening (5-9pm)"
    case night = "Night (9pm-12am)"
}

/// Weekday preference
public enum WeekdayPreference: String, Codable {
    case weekday = "Weekday Shopper"
    case weekend = "Weekend Shopper"
    case mixed = "Mixed"
}

/// Retailer preference pattern
public struct RetailerPreference: Codable, Identifiable {
    public let id: UUID
    public let retailer: String
    public let visitCount: Int
    public let totalSpent: Decimal
    public let averageBasketSize: Decimal
    public let categories: [ItemCategory]
    public let loyaltyRank: Int
    
    public init(
        id: UUID = UUID(),
        retailer: String,
        visitCount: Int,
        totalSpent: Decimal,
        averageBasketSize: Decimal,
        categories: [ItemCategory],
        loyaltyRank: Int
    ) {
        self.id = id
        self.retailer = retailer
        self.visitCount = visitCount
        self.totalSpent = totalSpent
        self.averageBasketSize = averageBasketSize
        self.categories = categories
        self.loyaltyRank = loyaltyRank
    }
}

/// Bulk buying pattern
public struct BulkBuyingPattern: Codable, Identifiable {
    public let id: UUID
    public let itemType: String
    public let category: ItemCategory
    public let averageQuantity: Int
    public let bulkSavings: Decimal
    public let frequency: PurchaseFrequency
    
    public init(
        id: UUID = UUID(),
        itemType: String,
        category: ItemCategory,
        averageQuantity: Int,
        bulkSavings: Decimal,
        frequency: PurchaseFrequency
    ) {
        self.id = id
        self.itemType = itemType
        self.category = category
        self.averageQuantity = averageQuantity
        self.bulkSavings = bulkSavings
        self.frequency = frequency
    }
}

/// Pattern insight
public struct PatternInsight: Codable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let title: String
    public let description: String
    public let impact: InsightImpact
    public let actionable: Bool
    
    public init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        impact: InsightImpact,
        actionable: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.impact = impact
        self.actionable = actionable
    }
}

/// Pattern recommendation
public struct PatternRecommendation: Codable, Identifiable {
    public let id: UUID
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let potentialSavings: Decimal?
    public let priority: RecommendationPriority
    
    public init(
        id: UUID = UUID(),
        type: RecommendationType,
        title: String,
        description: String,
        potentialSavings: Decimal? = nil,
        priority: RecommendationPriority
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.potentialSavings = potentialSavings
        self.priority = priority
    }
}

/// Recommendation type
public enum RecommendationType: String, Codable {
    case bulkBuy = "Bulk Buy Opportunity"
    case timing = "Better Timing"
    case alternative = "Alternative Product"
    case budget = "Budget Alert"
    case recurring = "Set Up Recurring"
    case seasonal = "Seasonal Opportunity"
}

/// Recommendation priority
public enum RecommendationPriority: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    public var color: String {
        switch self {
        case .high: return "#DC2626"
        case .medium: return "#F59E0B"
        case .low: return "#3B82F6"
        }
    }
}