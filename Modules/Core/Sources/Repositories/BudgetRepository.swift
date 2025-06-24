import Foundation

/// Repository protocol for budget management
/// Swift 5.9 - No Swift 6 features
public protocol BudgetRepository {
    // MARK: - Budget CRUD
    func create(_ budget: Budget) async throws -> Budget
    func update(_ budget: Budget) async throws -> Budget
    func delete(_ budget: Budget) async throws
    func fetch(id: UUID) async throws -> Budget?
    func fetchAll() async throws -> [Budget]
    func fetchActive() async throws -> [Budget]
    func fetchByCategory(_ category: ItemCategory) async throws -> [Budget]
    
    // MARK: - Budget Status
    func getCurrentStatus(for budgetId: UUID) async throws -> BudgetStatus?
    func getHistoricalStatuses(for budgetId: UUID, limit: Int) async throws -> [BudgetStatus]
    func updateStatus(_ status: BudgetStatus) async throws -> BudgetStatus
    
    // MARK: - Budget Alerts
    func createAlert(_ alert: BudgetAlert) async throws -> BudgetAlert
    func fetchAlerts(for budgetId: UUID) async throws -> [BudgetAlert]
    func fetchUnreadAlerts() async throws -> [BudgetAlert]
    func markAlertAsRead(_ alertId: UUID) async throws
    
    // MARK: - Budget Transactions
    func recordTransaction(_ transaction: BudgetTransaction) async throws -> BudgetTransaction
    func fetchTransactions(for budgetId: UUID, in period: DateInterval?) async throws -> [BudgetTransaction]
    func deleteTransaction(_ transactionId: UUID) async throws
    
    // MARK: - Budget History
    func recordHistoryEntry(_ entry: BudgetHistoryEntry) async throws -> BudgetHistoryEntry
    func fetchHistory(for budgetId: UUID, limit: Int) async throws -> [BudgetHistoryEntry]
    
    // MARK: - Analytics
    func calculateSpending(for budgetId: UUID, in period: DateInterval) async throws -> Decimal
    func getAverageSpending(for budgetId: UUID, periods: Int) async throws -> Decimal
    func getBudgetPerformance(for budgetId: UUID) async throws -> BudgetPerformance
}

/// Budget performance analytics
public struct BudgetPerformance: Codable, Identifiable {
    public var id: UUID { budgetId }
    public let budgetId: UUID
    public let averageSpending: Decimal
    public let monthsAnalyzed: Int
    public let timesExceeded: Int
    public let averagePercentageUsed: Double
    public let trend: TrendDirection
    public let savingsOpportunity: Decimal?
    
    public init(
        budgetId: UUID,
        averageSpending: Decimal,
        monthsAnalyzed: Int,
        timesExceeded: Int,
        averagePercentageUsed: Double,
        trend: TrendDirection,
        savingsOpportunity: Decimal? = nil
    ) {
        self.budgetId = budgetId
        self.averageSpending = averageSpending
        self.monthsAnalyzed = monthsAnalyzed
        self.timesExceeded = timesExceeded
        self.averagePercentageUsed = averagePercentageUsed
        self.trend = trend
        self.savingsOpportunity = savingsOpportunity
    }
}