import Foundation

/// Mock implementation of BudgetRepository for testing
/// Swift 5.9 - No Swift 6 features
public class MockBudgetRepository: BudgetRepository {
    private var budgets: [UUID: Budget] = {
        var dict: [UUID: Budget] = [:]
        for budget in MockDataService.generateBudgets() {
            dict[budget.id] = budget
        }
        return dict
    }()
    private var statuses: [UUID: BudgetStatus] = [:]
    private var alerts: [BudgetAlert] = []
    private var transactions: [BudgetTransaction] = []
    private var historyEntries: [BudgetHistoryEntry] = []
    
    public init() {}
    
    // MARK: - Budget CRUD
    
    public func create(_ budget: Budget) async throws -> Budget {
        budgets[budget.id] = budget
        return budget
    }
    
    public func update(_ budget: Budget) async throws -> Budget {
        budgets[budget.id] = budget
        return budget
    }
    
    public func delete(_ budget: Budget) async throws {
        budgets.removeValue(forKey: budget.id)
    }
    
    public func fetch(id: UUID) async throws -> Budget? {
        return budgets[id]
    }
    
    public func fetchAll() async throws -> [Budget] {
        return Array(budgets.values)
    }
    
    public func fetchActive() async throws -> [Budget] {
        let now = Date()
        return budgets.values.filter { budget in
            budget.startDate <= now && (budget.endDate == nil || budget.endDate! >= now)
        }
    }
    
    public func fetchByCategory(_ category: ItemCategory) async throws -> [Budget] {
        return budgets.values.filter { $0.category == category }
    }
    
    // MARK: - Budget Status
    
    public func getCurrentStatus(for budgetId: UUID) async throws -> BudgetStatus? {
        return statuses[budgetId]
    }
    
    public func getHistoricalStatuses(for budgetId: UUID, limit: Int) async throws -> [BudgetStatus] {
        return Array(statuses.values.filter { $0.budgetId == budgetId }.prefix(limit))
    }
    
    public func updateStatus(_ status: BudgetStatus) async throws -> BudgetStatus {
        statuses[status.id] = status
        return status
    }
    
    // MARK: - Budget Alerts
    
    public func createAlert(_ alert: BudgetAlert) async throws -> BudgetAlert {
        alerts.append(alert)
        return alert
    }
    
    public func fetchAlerts(for budgetId: UUID) async throws -> [BudgetAlert] {
        return alerts.filter { $0.budgetId == budgetId }
    }
    
    public func fetchUnreadAlerts() async throws -> [BudgetAlert] {
        return alerts.filter { !$0.isRead }
    }
    
    public func markAlertAsRead(_ alertId: UUID) async throws {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            var alert = alerts[index]
            alert.isRead = true
            alerts[index] = alert
        }
    }
    
    // MARK: - Budget Transactions
    
    public func recordTransaction(_ transaction: BudgetTransaction) async throws -> BudgetTransaction {
        transactions.append(transaction)
        return transaction
    }
    
    public func fetchTransactions(for budgetId: UUID, in period: DateInterval?) async throws -> [BudgetTransaction] {
        var filtered = transactions.filter { $0.budgetId == budgetId }
        
        if let period = period {
            filtered = filtered.filter { transaction in
                transaction.date >= period.start && transaction.date <= period.end
            }
        }
        
        return filtered
    }
    
    public func deleteTransaction(_ transactionId: UUID) async throws {
        transactions.removeAll { $0.id == transactionId }
    }
    
    // MARK: - Budget History
    
    public func recordHistoryEntry(_ entry: BudgetHistoryEntry) async throws -> BudgetHistoryEntry {
        historyEntries.append(entry)
        return entry
    }
    
    public func fetchHistory(for budgetId: UUID, limit: Int) async throws -> [BudgetHistoryEntry] {
        return Array(historyEntries.filter { $0.budgetId == budgetId }.prefix(limit))
    }
    
    // MARK: - Analytics
    
    public func calculateSpending(for budgetId: UUID, in period: DateInterval) async throws -> Decimal {
        let transactions = try await fetchTransactions(for: budgetId, in: period)
        return transactions.reduce(0) { $0 + $1.amount }
    }
    
    public func getAverageSpending(for budgetId: UUID, periods: Int) async throws -> Decimal {
        guard periods > 0 else { return 0 }
        
        let allTransactions = transactions.filter { $0.budgetId == budgetId }
        let total = allTransactions.reduce(0) { $0 + $1.amount }
        
        return total / Decimal(periods)
    }
    
    public func getBudgetPerformance(for budgetId: UUID) async throws -> BudgetPerformance {
        let budget = budgets[budgetId]
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let spending = try await calculateSpending(for: budgetId, in: DateInterval(start: oneYearAgo, end: now))
        let avgSpending = try await getAverageSpending(for: budgetId, periods: 12)
        
        return BudgetPerformance(
            budgetId: budgetId,
            averageSpending: avgSpending,
            monthsAnalyzed: 12,
            timesExceeded: 0,
            averagePercentageUsed: Double(truncating: (spending / (budget?.amount ?? 1)) as NSNumber),
            trend: .stable,
            savingsOpportunity: nil
        )
    }
}