import Foundation

/// Retailer analytics model for tracking store performance metrics
/// Swift 5.9 - No Swift 6 features
public struct RetailerAnalytics: Codable, Identifiable, Equatable {
    public let id: UUID
    public let storeName: String
    public let totalSpent: Decimal
    public let itemCount: Int
    public let averageItemPrice: Decimal
    public let lastPurchaseDate: Date?
    public let firstPurchaseDate: Date?
    public let purchaseFrequency: PurchaseFrequency
    public let topCategories: [CategorySpending]
    public let monthlySpending: [MonthlySpending]
    public let lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        storeName: String,
        totalSpent: Decimal,
        itemCount: Int,
        averageItemPrice: Decimal,
        lastPurchaseDate: Date? = nil,
        firstPurchaseDate: Date? = nil,
        purchaseFrequency: PurchaseFrequency = .occasional,
        topCategories: [CategorySpending] = [],
        monthlySpending: [MonthlySpending] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.storeName = storeName
        self.totalSpent = totalSpent
        self.itemCount = itemCount
        self.averageItemPrice = averageItemPrice
        self.lastPurchaseDate = lastPurchaseDate
        self.firstPurchaseDate = firstPurchaseDate
        self.purchaseFrequency = purchaseFrequency
        self.topCategories = topCategories
        self.monthlySpending = monthlySpending
        self.lastUpdated = lastUpdated
    }
}

/// Purchase frequency classification
public enum PurchaseFrequency: String, Codable, CaseIterable, Identifiable {
    public var id: String { rawValue }
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case occasional = "Occasional"
    case rare = "Rare"
    
    public var icon: String {
        switch self {
        case .daily: return "clock.fill"
        case .weekly: return "calendar.circle"
        case .monthly: return "calendar"
        case .occasional: return "clock"
        case .rare: return "clock.badge.questionmark"
        }
    }
    
    public var color: String {
        switch self {
        case .daily: return "#FF6B6B"      // Red
        case .weekly: return "#4ECDC4"     // Teal
        case .monthly: return "#95E1D3"    // Mint
        case .occasional: return "#FFE66D" // Yellow
        case .rare: return "#C7CEEA"       // Lavender
        }
    }
}

/// Category spending breakdown
public struct CategorySpending: Codable, Identifiable, Equatable {
    public let id: UUID
    public let category: ItemCategory
    public let totalSpent: Decimal
    public let itemCount: Int
    public let percentage: Double
    
    public init(
        id: UUID = UUID(),
        category: ItemCategory,
        totalSpent: Decimal,
        itemCount: Int,
        percentage: Double
    ) {
        self.id = id
        self.category = category
        self.totalSpent = totalSpent
        self.itemCount = itemCount
        self.percentage = percentage
    }
}

/// Monthly spending data
public struct MonthlySpending: Codable, Identifiable, Equatable {
    public let id: UUID
    public let month: Date
    public let amount: Decimal
    public let itemCount: Int
    
    public init(
        id: UUID = UUID(),
        month: Date,
        amount: Decimal,
        itemCount: Int
    ) {
        self.id = id
        self.month = month
        self.amount = amount
        self.itemCount = itemCount
    }
}

/// Store ranking by various metrics
public struct StoreRanking: Codable, Identifiable {
    public let id: UUID
    public let storeName: String
    public let metric: RankingMetric
    public let value: Decimal
    public let rank: Int
    
    public init(
        id: UUID = UUID(),
        storeName: String,
        metric: RankingMetric,
        value: Decimal,
        rank: Int
    ) {
        self.id = id
        self.storeName = storeName
        self.metric = metric
        self.value = value
        self.rank = rank
    }
}

/// Ranking metric types
public enum RankingMetric: String, Codable, CaseIterable {
    case totalSpent = "Total Spent"
    case itemCount = "Item Count"
    case frequency = "Purchase Frequency"
    case averageTransaction = "Average Transaction"
    
    public var icon: String {
        switch self {
        case .totalSpent: return "dollarsign.circle.fill"
        case .itemCount: return "cube.box.fill"
        case .frequency: return "clock.fill"
        case .averageTransaction: return "chart.bar.fill"
        }
    }
}

/// Retailer insights summary
public struct RetailerInsights: Codable {
    public let favoriteStore: String?
    public let totalStores: Int
    public let totalSpentAllStores: Decimal
    public let averagePerStore: Decimal
    public let mostExpensiveStore: String?
    public let mostFrequentStore: String?
    public let categoryLeaders: [CategoryLeader]
    
    public init(
        favoriteStore: String? = nil,
        totalStores: Int = 0,
        totalSpentAllStores: Decimal = 0,
        averagePerStore: Decimal = 0,
        mostExpensiveStore: String? = nil,
        mostFrequentStore: String? = nil,
        categoryLeaders: [CategoryLeader] = []
    ) {
        self.favoriteStore = favoriteStore
        self.totalStores = totalStores
        self.totalSpentAllStores = totalSpentAllStores
        self.averagePerStore = averagePerStore
        self.mostExpensiveStore = mostExpensiveStore
        self.mostFrequentStore = mostFrequentStore
        self.categoryLeaders = categoryLeaders
    }
}

/// Category leader - store that's best for a specific category
public struct CategoryLeader: Codable, Identifiable {
    public let id: UUID
    public let category: ItemCategory
    public let storeName: String
    public let itemCount: Int
    public let averagePrice: Decimal
    
    public init(
        id: UUID = UUID(),
        category: ItemCategory,
        storeName: String,
        itemCount: Int,
        averagePrice: Decimal
    ) {
        self.id = id
        self.category = category
        self.storeName = storeName
        self.itemCount = itemCount
        self.averagePrice = averagePrice
    }
}

// MARK: - Preview Data
public extension RetailerAnalytics {
    static let preview = RetailerAnalytics(
        storeName: "Amazon",
        totalSpent: 2543.67,
        itemCount: 47,
        averageItemPrice: 54.12,
        lastPurchaseDate: Date(),
        firstPurchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
        purchaseFrequency: .weekly,
        topCategories: [
            CategorySpending(
                category: .electronics,
                totalSpent: 1234.56,
                itemCount: 15,
                percentage: 48.5
            ),
            CategorySpending(
                category: .home,
                totalSpent: 567.89,
                itemCount: 12,
                percentage: 22.3
            )
        ],
        monthlySpending: [
            MonthlySpending(
                month: Date(),
                amount: 234.56,
                itemCount: 5
            ),
            MonthlySpending(
                month: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                amount: 456.78,
                itemCount: 8
            )
        ]
    )
    
    static let previews = [
        preview,
        RetailerAnalytics(
            storeName: "Target",
            totalSpent: 1234.56,
            itemCount: 23,
            averageItemPrice: 53.68,
            lastPurchaseDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            firstPurchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
            purchaseFrequency: .monthly
        ),
        RetailerAnalytics(
            storeName: "Best Buy",
            totalSpent: 3456.78,
            itemCount: 12,
            averageItemPrice: 288.07,
            lastPurchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            firstPurchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
            purchaseFrequency: .occasional
        )
    ]
}