import Foundation
import Core
import Combine

/// View model for the spending dashboard
/// Swift 5.9 - No Swift 6 features
@MainActor
final class SpendingDashboardViewModel: ObservableObject {
    // Dependencies
    let itemRepository: any ItemRepository
    let receiptRepository: (any ReceiptRepository)?
    let budgetRepository: (any BudgetRepository)?
    
    // Published properties
    @Published var totalSpent: Decimal = 0
    @Published var itemCount: Int = 0
    @Published var averagePrice: Decimal = 0
    @Published var categoryCount: Int = 0
    @Published var spendingData: [SpendingDataPoint] = []
    @Published var topCategories: [CategorySpendingData] = []
    @Published var recentPurchases: [Item] = []
    @Published var topRetailers: [RetailerSpendingData] = []
    @Published var isLoading = false
    
    let currency = "USD"
    
    init(itemRepository: any ItemRepository, receiptRepository: (any ReceiptRepository)? = nil, budgetRepository: (any BudgetRepository)? = nil) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.budgetRepository = budgetRepository
    }
    
    func loadData(for timeRange: SpendingDashboardView.TimeRange) async {
        isLoading = true
        
        do {
            // Load all items
            let allItems = try await itemRepository.fetchAll()
            
            // Filter items by time range
            let filteredItems = filterItems(allItems, by: timeRange)
            
            // Calculate statistics
            calculateStatistics(from: filteredItems)
            
            // Generate spending data points for chart
            generateSpendingData(from: filteredItems, timeRange: timeRange)
            
            // Calculate category breakdown
            calculateCategoryBreakdown(from: filteredItems)
            
            // Get recent purchases
            updateRecentPurchases(from: filteredItems)
            
            // Calculate top retailers (using brand as proxy for now)
            calculateTopRetailers(from: filteredItems)
            
        } catch {
            print("Error loading spending data: \(error)")
        }
        
        isLoading = false
    }
    
    func getItems(for category: ItemCategory) -> [Item] {
        // This would be better with a proper filtered fetch from repository
        return recentPurchases.filter { $0.category == category }
    }
    
    // MARK: - Private Methods
    
    private func filterItems(_ items: [Item], by timeRange: SpendingDashboardView.TimeRange) -> [Item] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeRange {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return items.filter { $0.purchasePrice != nil }
        }
        
        return items.filter { item in
            guard let purchaseDate = item.purchaseDate,
                  item.purchasePrice != nil else { return false }
            return purchaseDate >= startDate
        }
    }
    
    private func calculateStatistics(from items: [Item]) {
        itemCount = items.count
        
        totalSpent = items.reduce(0) { sum, item in
            sum + (item.purchasePrice ?? 0)
        }
        
        averagePrice = itemCount > 0 ? totalSpent / Decimal(itemCount) : 0
        
        let categories = Set(items.map { $0.category })
        categoryCount = categories.count
    }
    
    private func generateSpendingData(from items: [Item], timeRange: SpendingDashboardView.TimeRange) {
        let calendar = Calendar.current
        var dataPoints: [Date: Decimal] = [:]
        
        // Group items by time period
        for item in items {
            guard let purchaseDate = item.purchaseDate,
                  let price = item.purchasePrice else { continue }
            
            let periodDate: Date
            switch timeRange {
            case .week:
                // Group by day
                periodDate = calendar.startOfDay(for: purchaseDate)
            case .month:
                // Group by week
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .quarter, .year:
                // Group by month
                let components = calendar.dateComponents([.year, .month], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .all:
                // Group by year
                let components = calendar.dateComponents([.year], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            }
            
            dataPoints[periodDate, default: 0] += price
        }
        
        // Convert to array and sort
        spendingData = dataPoints.map { SpendingDataPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private func calculateCategoryBreakdown(from items: [Item]) {
        var categoryData: [ItemCategory: (count: Int, total: Decimal)] = [:]
        
        for item in items {
            guard let price = item.purchasePrice else { continue }
            let current = categoryData[item.category, default: (0, 0)]
            categoryData[item.category] = (current.count + 1, current.total + price)
        }
        
        topCategories = categoryData.map { category, data in
            CategorySpendingData(
                id: UUID(),
                category: category,
                itemCount: data.count,
                totalSpent: data.total
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func updateRecentPurchases(from items: [Item]) {
        recentPurchases = items
            .filter { $0.purchaseDate != nil && $0.purchasePrice != nil }
            .sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
    }
    
    private func calculateTopRetailers(from items: [Item]) {
        var retailerData: [String: (count: Int, total: Decimal)] = [:]
        
        for item in items {
            guard let price = item.purchasePrice else { continue }
            // Using brand as proxy for retailer - in real app would have retailer field
            let retailer = item.brand ?? "Unknown"
            let current = retailerData[retailer, default: (0, 0)]
            retailerData[retailer] = (current.count + 1, current.total + price)
        }
        
        topRetailers = retailerData.map { name, data in
            RetailerSpendingData(
                id: UUID(),
                name: name,
                itemCount: data.count,
                totalSpent: data.total
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
    }
}

// MARK: - Data Models

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

struct CategorySpendingData: Identifiable {
    let id: UUID
    let category: ItemCategory
    let itemCount: Int
    let totalSpent: Decimal
}

struct RetailerSpendingData: Identifiable {
    let id: UUID
    let name: String
    let itemCount: Int
    let totalSpent: Decimal
}