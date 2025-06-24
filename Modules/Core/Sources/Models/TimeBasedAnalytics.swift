import Foundation

/// Time-based analytics model for tracking trends over different periods
/// Swift 5.9 - No Swift 6 features
public struct TimeBasedAnalytics: Codable, Identifiable {
    public let id: UUID
    public let period: AnalyticsPeriod
    public let startDate: Date
    public let endDate: Date
    public let metrics: TimeMetrics
    public let trends: [TrendData]
    public let comparisons: PeriodComparison?
    public let insights: [TimeInsight]
    public let lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        period: AnalyticsPeriod,
        startDate: Date,
        endDate: Date,
        metrics: TimeMetrics,
        trends: [TrendData] = [],
        comparisons: PeriodComparison? = nil,
        insights: [TimeInsight] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.metrics = metrics
        self.trends = trends
        self.comparisons = comparisons
        self.insights = insights
        self.lastUpdated = lastUpdated
    }
}

/// Analytics period types
public enum AnalyticsPeriod: String, Codable, CaseIterable {
    case day = "Daily"
    case week = "Weekly"
    case month = "Monthly"
    case quarter = "Quarterly"
    case year = "Yearly"
    case custom = "Custom"
    
    public var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        case .custom: return .day
        }
    }
}

/// Time-based metrics
public struct TimeMetrics: Codable {
    public let totalSpent: Decimal
    public let itemsAdded: Int
    public let averageItemValue: Decimal
    public let mostExpensiveItem: Item?
    public let mostActiveDay: Date?
    public let categoryBreakdown: [CategoryTimeMetric]
    public let storeBreakdown: [StoreTimeMetric]
    
    public init(
        totalSpent: Decimal = 0,
        itemsAdded: Int = 0,
        averageItemValue: Decimal = 0,
        mostExpensiveItem: Item? = nil,
        mostActiveDay: Date? = nil,
        categoryBreakdown: [CategoryTimeMetric] = [],
        storeBreakdown: [StoreTimeMetric] = []
    ) {
        self.totalSpent = totalSpent
        self.itemsAdded = itemsAdded
        self.averageItemValue = averageItemValue
        self.mostExpensiveItem = mostExpensiveItem
        self.mostActiveDay = mostActiveDay
        self.categoryBreakdown = categoryBreakdown
        self.storeBreakdown = storeBreakdown
    }
}

/// Category metrics over time
public struct CategoryTimeMetric: Codable, Identifiable {
    public let id: UUID
    public let category: ItemCategory
    public let totalSpent: Decimal
    public let itemCount: Int
    public let percentageOfTotal: Double
    
    public init(
        id: UUID = UUID(),
        category: ItemCategory,
        totalSpent: Decimal,
        itemCount: Int,
        percentageOfTotal: Double
    ) {
        self.id = id
        self.category = category
        self.totalSpent = totalSpent
        self.itemCount = itemCount
        self.percentageOfTotal = percentageOfTotal
    }
}

/// Store metrics over time
public struct StoreTimeMetric: Codable, Identifiable {
    public let id: UUID
    public let storeName: String
    public let totalSpent: Decimal
    public let itemCount: Int
    public let percentageOfTotal: Double
    
    public init(
        id: UUID = UUID(),
        storeName: String,
        totalSpent: Decimal,
        itemCount: Int,
        percentageOfTotal: Double
    ) {
        self.id = id
        self.storeName = storeName
        self.totalSpent = totalSpent
        self.itemCount = itemCount
        self.percentageOfTotal = percentageOfTotal
    }
}

/// Trend data point for charts
public struct TrendData: Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public let value: Decimal
    public let itemCount: Int
    public let label: String
    
    public init(
        id: UUID = UUID(),
        date: Date,
        value: Decimal,
        itemCount: Int,
        label: String
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.itemCount = itemCount
        self.label = label
    }
}

/// Period comparison data
public struct PeriodComparison: Codable {
    public let previousPeriod: TimeMetrics
    public let spendingChange: Decimal
    public let spendingChangePercentage: Double
    public let itemCountChange: Int
    public let itemCountChangePercentage: Double
    public let trend: TrendDirection
    
    public init(
        previousPeriod: TimeMetrics,
        spendingChange: Decimal,
        spendingChangePercentage: Double,
        itemCountChange: Int,
        itemCountChangePercentage: Double,
        trend: TrendDirection
    ) {
        self.previousPeriod = previousPeriod
        self.spendingChange = spendingChange
        self.spendingChangePercentage = spendingChangePercentage
        self.itemCountChange = itemCountChange
        self.itemCountChangePercentage = itemCountChangePercentage
        self.trend = trend
    }
}

/// Trend direction
public enum TrendDirection: String, Codable {
    case up = "Up"
    case down = "Down"
    case stable = "Stable"
    
    public var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .up: return "#10B981"    // Green
        case .down: return "#EF4444"  // Red
        case .stable: return "#6B7280" // Gray
        }
    }
}

/// Time-based insight
public struct TimeInsight: Codable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let title: String
    public let description: String
    public let impact: InsightImpact
    
    public init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        impact: InsightImpact
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.impact = impact
    }
}

/// Insight types
public enum InsightType: String, Codable {
    case spending = "Spending"
    case acquisition = "Acquisition"
    case category = "Category"
    case seasonal = "Seasonal"
    case anomaly = "Anomaly"
    
    public var icon: String {
        switch self {
        case .spending: return "dollarsign.circle"
        case .acquisition: return "plus.circle"
        case .category: return "folder.circle"
        case .seasonal: return "calendar.circle"
        case .anomaly: return "exclamationmark.triangle"
        }
    }
}

/// Insight impact level
public enum InsightImpact: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    public var color: String {
        switch self {
        case .high: return "#DC2626"    // Red
        case .medium: return "#F59E0B"  // Amber
        case .low: return "#3B82F6"     // Blue
        }
    }
}

/// Seasonal pattern data
public struct SeasonalPattern: Codable {
    public let season: Season
    public let averageSpending: Decimal
    public let typicalCategories: [ItemCategory]
    public let peakMonth: String
    
    public init(
        season: Season,
        averageSpending: Decimal,
        typicalCategories: [ItemCategory],
        peakMonth: String
    ) {
        self.season = season
        self.averageSpending = averageSpending
        self.typicalCategories = typicalCategories
        self.peakMonth = peakMonth
    }
}

/// Season enumeration
public enum Season: String, Codable, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    
    public var months: [Int] {
        switch self {
        case .spring: return [3, 4, 5]
        case .summer: return [6, 7, 8]
        case .fall: return [9, 10, 11]
        case .winter: return [12, 1, 2]
        }
    }
    
    public var icon: String {
        switch self {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "wind"
        case .winter: return "snowflake"
        }
    }
}