import Foundation

/// Service for budget management and monitoring
/// Swift 5.9 - No Swift 6 features
public final class BudgetService {
    private let budgetRepository: any BudgetRepository
    private let itemRepository: any ItemRepository
    private let calendar = Calendar.current
    
    public init(
        budgetRepository: any BudgetRepository,
        itemRepository: any ItemRepository
    ) {
        self.budgetRepository = budgetRepository
        self.itemRepository = itemRepository
    }
    
    // MARK: - Budget Management
    
    /// Create a new budget
    public func createBudget(_ budget: Budget) async throws -> Budget {
        let created = try await budgetRepository.create(budget)
        
        // Initialize first status
        let period = getCurrentPeriod(for: budget)
        let status = try await calculateStatus(for: created, in: period)
        _ = try await budgetRepository.updateStatus(status)
        
        return created
    }
    
    /// Update budget and recalculate status
    public func updateBudget(_ budget: Budget) async throws -> Budget {
        let updated = try await budgetRepository.update(budget)
        
        // Recalculate current status
        let period = getCurrentPeriod(for: updated)
        let status = try await calculateStatus(for: updated, in: period)
        _ = try await budgetRepository.updateStatus(status)
        
        return updated
    }
    
    /// Delete budget and related data
    public func deleteBudget(_ budget: Budget) async throws {
        try await budgetRepository.delete(budget)
    }
    
    // MARK: - Budget Monitoring
    
    /// Check all active budgets and create alerts if needed
    public func checkBudgets() async throws {
        let activeBudgets = try await budgetRepository.fetchActive()
        
        for budget in activeBudgets {
            try await checkBudget(budget)
        }
    }
    
    /// Check a specific budget
    private func checkBudget(_ budget: Budget) async throws {
        let period = getCurrentPeriod(for: budget)
        let status = try await calculateStatus(for: budget, in: period)
        
        // Update status
        _ = try await budgetRepository.updateStatus(status)
        
        // Check for alerts
        if status.percentageUsed >= budget.notificationThreshold && !status.isOverBudget {
            try await createThresholdAlert(for: budget, status: status)
        }
        
        if status.isOverBudget {
            try await createExceededAlert(for: budget, status: status)
        }
        
        // Check projected spending
        if let projected = status.projectedSpending, projected > budget.amount {
            try await createProjectedAlert(for: budget, status: status, projected: projected)
        }
        
        // Check if period is ending soon
        let daysUntilEnd = calendar.dateComponents([.day], from: Date(), to: period.end).day ?? 0
        if daysUntilEnd <= 3 && daysUntilEnd > 0 {
            try await createPeriodEndingAlert(for: budget, daysRemaining: daysUntilEnd)
        }
    }
    
    /// Calculate budget status for a period
    private func calculateStatus(for budget: Budget, in period: DateInterval) async throws -> BudgetStatus {
        let items = try await itemRepository.fetchAll()
        
        // Filter items by budget criteria
        let relevantItems = items.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            guard period.contains(purchaseDate) else { return false }
            
            // Check category filter
            if let budgetCategory = budget.category {
                return item.category == budgetCategory
            }
            
            return true
        }
        
        // Calculate spending
        let spent = relevantItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
        let remaining = max(0, budget.amount - spent)
        let percentageUsed = budget.amount > 0 ? 
            min(1.0, NSDecimalNumber(decimal: spent).doubleValue / NSDecimalNumber(decimal: budget.amount).doubleValue) : 0
        
        // Calculate projected spending
        let daysElapsed = calendar.dateComponents([.day], from: period.start, to: Date()).day ?? 0
        let totalDays = calendar.dateComponents([.day], from: period.start, to: period.end).day ?? 1
        let projectedSpending: Decimal? = daysElapsed > 0 && daysElapsed < totalDays ?
            spent * Decimal(totalDays) / Decimal(daysElapsed) : nil
        
        return BudgetStatus(
            budgetId: budget.id,
            periodStart: period.start,
            periodEnd: period.end,
            spent: spent,
            remaining: remaining,
            percentageUsed: percentageUsed,
            itemCount: relevantItems.count,
            isOverBudget: spent > budget.amount,
            projectedSpending: projectedSpending
        )
    }
    
    // MARK: - Period Calculation
    
    /// Get current period for a budget
    public func getCurrentPeriod(for budget: Budget) -> DateInterval {
        let now = Date()
        
        switch budget.period {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)
            
        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return DateInterval(start: start, end: end)
            
        case .biweekly:
            // Calculate based on budget start date
            let daysSinceStart = calendar.dateComponents([.day], from: budget.startDate, to: now).day ?? 0
            let periodNumber = daysSinceStart / 14
            let periodStart = calendar.date(byAdding: .day, value: periodNumber * 14, to: budget.startDate)!
            let periodEnd = calendar.date(byAdding: .day, value: 14, to: periodStart)!
            return DateInterval(start: periodStart, end: periodEnd)
            
        case .monthly:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)
            
        case .quarterly:
            let start = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 3, to: start)!
            return DateInterval(start: start, end: end)
            
        case .yearly:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return DateInterval(start: start, end: end)
            
        case .custom:
            // Use budget start and end dates
            return DateInterval(start: budget.startDate, end: budget.endDate ?? Date())
        }
    }
    
    // MARK: - Alert Creation
    
    private func createThresholdAlert(for budget: Budget, status: BudgetStatus) async throws {
        let alert = BudgetAlert(
            budgetId: budget.id,
            type: .threshold,
            title: "Budget Threshold Reached",
            message: "You've used \(Int(status.percentageUsed * 100))% of your \(budget.name) budget",
            percentageUsed: status.percentageUsed,
            amountSpent: status.spent,
            amountRemaining: status.remaining
        )
        
        _ = try await budgetRepository.createAlert(alert)
    }
    
    private func createExceededAlert(for budget: Budget, status: BudgetStatus) async throws {
        let alert = BudgetAlert(
            budgetId: budget.id,
            type: .exceeded,
            title: "Budget Exceeded",
            message: "You've exceeded your \(budget.name) budget by \((status.spent - budget.amount).formatted())",
            percentageUsed: status.percentageUsed,
            amountSpent: status.spent,
            amountRemaining: status.remaining
        )
        
        _ = try await budgetRepository.createAlert(alert)
    }
    
    private func createProjectedAlert(for budget: Budget, status: BudgetStatus, projected: Decimal) async throws {
        let alert = BudgetAlert(
            budgetId: budget.id,
            type: .projected,
            title: "Projected to Exceed Budget",
            message: "At current spending rate, you'll exceed your \(budget.name) budget by \((projected - budget.amount).formatted())",
            percentageUsed: status.percentageUsed,
            amountSpent: status.spent,
            amountRemaining: status.remaining
        )
        
        _ = try await budgetRepository.createAlert(alert)
    }
    
    private func createPeriodEndingAlert(for budget: Budget, daysRemaining: Int) async throws {
        if let status = try await budgetRepository.getCurrentStatus(for: budget.id) {
            let alert = BudgetAlert(
                budgetId: budget.id,
                type: .periodEnding,
                title: "Budget Period Ending Soon",
                message: "Your \(budget.name) budget period ends in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")",
                percentageUsed: status.percentageUsed,
                amountSpent: status.spent,
                amountRemaining: status.remaining
            )
            
            _ = try await budgetRepository.createAlert(alert)
        }
    }
    
    // MARK: - Transaction Recording
    
    /// Record a new purchase against budgets
    public func recordPurchase(_ item: Item) async throws {
        guard let purchaseDate = item.purchaseDate,
              let purchasePrice = item.purchasePrice else { return }
        
        // Find applicable budgets
        let activeBudgets = try await budgetRepository.fetchActive()
        
        for budget in activeBudgets {
            // Check if item matches budget criteria
            let period = getCurrentPeriod(for: budget)
            guard period.contains(purchaseDate) else { continue }
            
            if let budgetCategory = budget.category {
                guard item.category == budgetCategory else { continue }
            }
            
            // Record transaction
            let transaction = BudgetTransaction(
                budgetId: budget.id,
                itemId: item.id,
                amount: purchasePrice,
                date: purchaseDate,
                category: item.category,
                itemName: item.name,
                storeName: item.storeName
            )
            
            _ = try await budgetRepository.recordTransaction(transaction)
            
            // Check budget status
            try await checkBudget(budget)
        }
    }
    
    // MARK: - History Management
    
    /// Close a budget period and record history
    public func closePeriod(for budget: Budget, period: DateInterval) async throws {
        let status = try await calculateStatus(for: budget, in: period)
        
        let historyEntry = BudgetHistoryEntry(
            budgetId: budget.id,
            period: period,
            budgetAmount: budget.amount,
            actualSpent: status.spent,
            itemCount: status.itemCount,
            wasOverBudget: status.isOverBudget,
            percentageUsed: status.percentageUsed
        )
        
        _ = try await budgetRepository.recordHistoryEntry(historyEntry)
    }
    
    // MARK: - Analytics
    
    /// Get budget insights and recommendations
    public func getBudgetInsights(for budget: Budget) async throws -> BudgetInsights {
        let performance = try await budgetRepository.getBudgetPerformance(for: budget.id)
        let history = try await budgetRepository.fetchHistory(for: budget.id, limit: 12)
        let currentStatus = try await budgetRepository.getCurrentStatus(for: budget.id)
        
        var insights: [String] = []
        var recommendations: [String] = []
        
        // Analyze performance
        if performance.timesExceeded > performance.monthsAnalyzed / 2 {
            insights.append("This budget is exceeded more than 50% of the time")
            let percentageIncrease = NSDecimalNumber(decimal: (performance.averageSpending - budget.amount) / budget.amount * 100).intValue
            recommendations.append("Consider increasing your budget by \(percentageIncrease)%")
        }
        
        if performance.averagePercentageUsed < 0.5 {
            insights.append("You typically use less than 50% of this budget")
            recommendations.append("Consider reducing your budget to save for other goals")
        }
        
        // Analyze trends
        if performance.trend == .up {
            insights.append("Your spending in this category is trending upward")
            recommendations.append("Review recent purchases to identify areas to cut back")
        }
        
        // Seasonal analysis
        if history.count >= 12 {
            let monthlySpending = Dictionary(grouping: history) { entry in
                calendar.component(.month, from: entry.period.start)
            }
            
            let averageByMonth = monthlySpending.mapValues { entries in
                entries.reduce(Decimal(0)) { $0 + $1.actualSpent } / Decimal(entries.count)
            }
            
            if let maxMonth = averageByMonth.max(by: { $0.value < $1.value }) {
                let monthName = DateFormatter().monthSymbols[maxMonth.key - 1]
                insights.append("You typically spend the most in \(monthName)")
            }
        }
        
        return BudgetInsights(
            budget: budget,
            currentStatus: currentStatus,
            performance: performance,
            insights: insights,
            recommendations: recommendations,
            projectedAnnualSavings: performance.savingsOpportunity
        )
    }
}

/// Budget insights model
public struct BudgetInsights {
    public let budget: Budget
    public let currentStatus: BudgetStatus?
    public let performance: BudgetPerformance
    public let insights: [String]
    public let recommendations: [String]
    public let projectedAnnualSavings: Decimal?
    
    public init(
        budget: Budget,
        currentStatus: BudgetStatus?,
        performance: BudgetPerformance,
        insights: [String],
        recommendations: [String],
        projectedAnnualSavings: Decimal?
    ) {
        self.budget = budget
        self.currentStatus = currentStatus
        self.performance = performance
        self.insights = insights
        self.recommendations = recommendations
        self.projectedAnnualSavings = projectedAnnualSavings
    }
}