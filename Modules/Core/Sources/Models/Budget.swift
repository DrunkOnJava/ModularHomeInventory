import Foundation

/// Budget model for tracking spending limits
/// Swift 5.9 - No Swift 6 features
public struct Budget: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let amount: Decimal
    public let period: BudgetPeriod
    public let category: ItemCategory?
    public let startDate: Date
    public let endDate: Date?
    public let isActive: Bool
    public let notificationThreshold: Double // 0-1 percentage
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        amount: Decimal,
        period: BudgetPeriod,
        category: ItemCategory? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        notificationThreshold: Double = 0.8,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.amount = amount
        self.period = period
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.notificationThreshold = notificationThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Budget period types
public enum BudgetPeriod: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    public var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .custom: return 0
        }
    }
    
    public var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.week"
        case .biweekly: return "calendar.badge.2"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.3"
        case .yearly: return "calendar.badge.12"
        case .custom: return "calendar.badge.plus"
        }
    }
}

/// Budget status tracking
public struct BudgetStatus: Codable, Identifiable {
    public let id: UUID
    public let budgetId: UUID
    public let periodStart: Date
    public let periodEnd: Date
    public let spent: Decimal
    public let remaining: Decimal
    public let percentageUsed: Double
    public let itemCount: Int
    public let isOverBudget: Bool
    public let projectedSpending: Decimal?
    public let lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        budgetId: UUID,
        periodStart: Date,
        periodEnd: Date,
        spent: Decimal,
        remaining: Decimal,
        percentageUsed: Double,
        itemCount: Int,
        isOverBudget: Bool,
        projectedSpending: Decimal? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.budgetId = budgetId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.spent = spent
        self.remaining = remaining
        self.percentageUsed = percentageUsed
        self.itemCount = itemCount
        self.isOverBudget = isOverBudget
        self.projectedSpending = projectedSpending
        self.lastUpdated = lastUpdated
    }
}

/// Budget alert for notifications
public struct BudgetAlert: Codable, Identifiable {
    public let id: UUID
    public let budgetId: UUID
    public let type: BudgetAlertType
    public let title: String
    public let message: String
    public let percentageUsed: Double
    public let amountSpent: Decimal
    public let amountRemaining: Decimal
    public let createdAt: Date
    public let isRead: Bool
    
    public init(
        id: UUID = UUID(),
        budgetId: UUID,
        type: BudgetAlertType,
        title: String,
        message: String,
        percentageUsed: Double,
        amountSpent: Decimal,
        amountRemaining: Decimal,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.budgetId = budgetId
        self.type = type
        self.title = title
        self.message = message
        self.percentageUsed = percentageUsed
        self.amountSpent = amountSpent
        self.amountRemaining = amountRemaining
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

/// Budget alert types
public enum BudgetAlertType: String, Codable {
    case threshold = "Threshold Reached"
    case exceeded = "Budget Exceeded"
    case projected = "Projected to Exceed"
    case periodEnding = "Period Ending Soon"
    
    public var icon: String {
        switch self {
        case .threshold: return "exclamationmark.triangle"
        case .exceeded: return "exclamationmark.octagon"
        case .projected: return "chart.line.uptrend.xyaxis"
        case .periodEnding: return "clock.badge.exclamationmark"
        }
    }
    
    public var color: String {
        switch self {
        case .threshold: return "#F59E0B" // Warning
        case .exceeded: return "#DC2626" // Error
        case .projected: return "#F59E0B" // Warning
        case .periodEnding: return "#3B82F6" // Info
        }
    }
}

/// Budget transaction for tracking
public struct BudgetTransaction: Codable, Identifiable {
    public let id: UUID
    public let budgetId: UUID
    public let itemId: UUID
    public let amount: Decimal
    public let date: Date
    public let category: ItemCategory
    public let itemName: String
    public let storeName: String?
    
    public init(
        id: UUID = UUID(),
        budgetId: UUID,
        itemId: UUID,
        amount: Decimal,
        date: Date,
        category: ItemCategory,
        itemName: String,
        storeName: String? = nil
    ) {
        self.id = id
        self.budgetId = budgetId
        self.itemId = itemId
        self.amount = amount
        self.date = date
        self.category = category
        self.itemName = itemName
        self.storeName = storeName
    }
}

/// Budget history entry
public struct BudgetHistoryEntry: Codable, Identifiable {
    public let id: UUID
    public let budgetId: UUID
    public let period: DateInterval
    public let budgetAmount: Decimal
    public let actualSpent: Decimal
    public let itemCount: Int
    public let wasOverBudget: Bool
    public let percentageUsed: Double
    
    public init(
        id: UUID = UUID(),
        budgetId: UUID,
        period: DateInterval,
        budgetAmount: Decimal,
        actualSpent: Decimal,
        itemCount: Int,
        wasOverBudget: Bool,
        percentageUsed: Double
    ) {
        self.id = id
        self.budgetId = budgetId
        self.period = period
        self.budgetAmount = budgetAmount
        self.actualSpent = actualSpent
        self.itemCount = itemCount
        self.wasOverBudget = wasOverBudget
        self.percentageUsed = percentageUsed
    }
}