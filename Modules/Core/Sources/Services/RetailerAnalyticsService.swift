import Foundation

/// Service for calculating and managing retailer analytics
/// Swift 5.9 - No Swift 6 features
public final class RetailerAnalyticsService {
    private let itemRepository: any ItemRepository
    private let receiptRepository: (any ReceiptRepository)?
    
    public init(
        itemRepository: any ItemRepository,
        receiptRepository: (any ReceiptRepository)? = nil
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
    }
    
    /// Calculate analytics for all retailers
    public func calculateAllRetailerAnalytics() async throws -> [RetailerAnalytics] {
        let items = try await itemRepository.fetchAll()
        
        // Group items by store
        let itemsByStore = Dictionary(grouping: items.filter { $0.storeName != nil }) { $0.storeName! }
        
        var analytics: [RetailerAnalytics] = []
        
        for (storeName, storeItems) in itemsByStore {
            let analytic = try await calculateRetailerAnalytics(
                storeName: storeName,
                items: storeItems
            )
            analytics.append(analytic)
        }
        
        // Sort by total spent descending
        return analytics.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    /// Calculate analytics for a specific retailer
    public func calculateRetailerAnalytics(
        storeName: String,
        items: [Item]? = nil
    ) async throws -> RetailerAnalytics {
        let storeItems: [Item]
        
        if let items = items {
            storeItems = items
        } else {
            let allItems = try await itemRepository.fetchAll()
            storeItems = allItems.filter { $0.storeName == storeName }
        }
        
        // Calculate total spent
        let totalSpent = storeItems.reduce(Decimal(0)) { sum, item in
            sum + (item.purchasePrice ?? 0)
        }
        
        // Calculate average item price
        let averageItemPrice = storeItems.isEmpty ? Decimal(0) : totalSpent / Decimal(storeItems.count)
        
        // Find date range
        let purchaseDates = storeItems.compactMap { $0.purchaseDate }.sorted()
        let firstPurchaseDate = purchaseDates.first
        let lastPurchaseDate = purchaseDates.last
        
        // Calculate purchase frequency
        let purchaseFrequency = calculatePurchaseFrequency(
            dates: purchaseDates,
            firstDate: firstPurchaseDate,
            lastDate: lastPurchaseDate
        )
        
        // Calculate top categories
        let topCategories = calculateTopCategories(items: storeItems, totalSpent: totalSpent)
        
        // Calculate monthly spending
        let monthlySpending = calculateMonthlySpending(items: storeItems)
        
        return RetailerAnalytics(
            storeName: storeName,
            totalSpent: totalSpent,
            itemCount: storeItems.count,
            averageItemPrice: averageItemPrice,
            lastPurchaseDate: lastPurchaseDate,
            firstPurchaseDate: firstPurchaseDate,
            purchaseFrequency: purchaseFrequency,
            topCategories: topCategories,
            monthlySpending: monthlySpending
        )
    }
    
    /// Get retailer insights summary
    public func getRetailerInsights() async throws -> RetailerInsights {
        let analytics = try await calculateAllRetailerAnalytics()
        
        guard !analytics.isEmpty else {
            return RetailerInsights()
        }
        
        // Find favorite store (most items)
        let favoriteStore = analytics.max(by: { $0.itemCount < $1.itemCount })?.storeName
        
        // Calculate totals
        let totalSpent = analytics.reduce(Decimal(0)) { $0 + $1.totalSpent }
        let averagePerStore = totalSpent / Decimal(analytics.count)
        
        // Find most expensive store (highest average price)
        let mostExpensiveStore = analytics.max(by: { $0.averageItemPrice < $1.averageItemPrice })?.storeName
        
        // Find most frequent store
        let mostFrequentStore = analytics.min(by: { 
            frequencyScore($0.purchaseFrequency) < frequencyScore($1.purchaseFrequency)
        })?.storeName
        
        // Calculate category leaders
        let categoryLeaders = try await calculateCategoryLeaders()
        
        return RetailerInsights(
            favoriteStore: favoriteStore,
            totalStores: analytics.count,
            totalSpentAllStores: totalSpent,
            averagePerStore: averagePerStore,
            mostExpensiveStore: mostExpensiveStore,
            mostFrequentStore: mostFrequentStore,
            categoryLeaders: categoryLeaders
        )
    }
    
    /// Get store rankings by different metrics
    public func getStoreRankings(metric: RankingMetric) async throws -> [StoreRanking] {
        let analytics = try await calculateAllRetailerAnalytics()
        
        var rankings: [StoreRanking] = []
        
        switch metric {
        case .totalSpent:
            let sorted = analytics.sorted { $0.totalSpent > $1.totalSpent }
            for (index, analytic) in sorted.enumerated() {
                rankings.append(StoreRanking(
                    storeName: analytic.storeName,
                    metric: metric,
                    value: analytic.totalSpent,
                    rank: index + 1
                ))
            }
            
        case .itemCount:
            let sorted = analytics.sorted { $0.itemCount > $1.itemCount }
            for (index, analytic) in sorted.enumerated() {
                rankings.append(StoreRanking(
                    storeName: analytic.storeName,
                    metric: metric,
                    value: Decimal(analytic.itemCount),
                    rank: index + 1
                ))
            }
            
        case .frequency:
            let sorted = analytics.sorted { 
                frequencyScore($0.purchaseFrequency) < frequencyScore($1.purchaseFrequency)
            }
            for (index, analytic) in sorted.enumerated() {
                rankings.append(StoreRanking(
                    storeName: analytic.storeName,
                    metric: metric,
                    value: Decimal(frequencyScore(analytic.purchaseFrequency)),
                    rank: index + 1
                ))
            }
            
        case .averageTransaction:
            let sorted = analytics.sorted { $0.averageItemPrice > $1.averageItemPrice }
            for (index, analytic) in sorted.enumerated() {
                rankings.append(StoreRanking(
                    storeName: analytic.storeName,
                    metric: metric,
                    value: analytic.averageItemPrice,
                    rank: index + 1
                ))
            }
        }
        
        return rankings
    }
    
    /// Get spending comparison between stores
    public func getSpendingComparison(
        stores: [String]? = nil,
        dateRange: DateInterval? = nil
    ) async throws -> [(store: String, amount: Decimal, percentage: Double)] {
        let items = try await itemRepository.fetchAll()
        
        // Filter by date range if provided
        let filteredItems: [Item]
        if let dateRange = dateRange {
            filteredItems = items.filter { item in
                guard let purchaseDate = item.purchaseDate else { return false }
                return dateRange.contains(purchaseDate)
            }
        } else {
            filteredItems = items
        }
        
        // Group by store
        let itemsByStore = Dictionary(grouping: filteredItems.filter { $0.storeName != nil }) { $0.storeName! }
        
        // Filter by specific stores if provided
        let relevantStores: [String: [Item]]
        if let stores = stores {
            relevantStores = itemsByStore.filter { stores.contains($0.key) }
        } else {
            relevantStores = itemsByStore
        }
        
        // Calculate spending per store
        var storeSpending: [(store: String, amount: Decimal)] = []
        for (store, items) in relevantStores {
            let amount = items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            storeSpending.append((store: store, amount: amount))
        }
        
        // Sort by amount
        storeSpending.sort { $0.amount > $1.amount }
        
        // Calculate percentages
        let total = storeSpending.reduce(Decimal(0)) { $0 + $1.amount }
        
        return storeSpending.map { store in
            let percentage = total > 0 ? (NSDecimalNumber(decimal: store.amount).doubleValue / NSDecimalNumber(decimal: total).doubleValue * 100) : 0
            return (store: store.store, amount: store.amount, percentage: percentage)
        }
    }
    
    // MARK: - Private Methods
    
    private func calculatePurchaseFrequency(
        dates: [Date],
        firstDate: Date?,
        lastDate: Date?
    ) -> PurchaseFrequency {
        guard dates.count > 1,
              let firstDate = firstDate,
              let lastDate = lastDate else {
            return .rare
        }
        
        let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        guard daysBetween > 0 else { return .rare }
        
        let averageDaysBetweenPurchases = Double(daysBetween) / Double(dates.count - 1)
        
        switch averageDaysBetweenPurchases {
        case 0...2:
            return .daily
        case 3...10:
            return .weekly
        case 11...45:
            return .monthly
        case 46...180:
            return .occasional
        default:
            return .rare
        }
    }
    
    private func calculateTopCategories(items: [Item], totalSpent: Decimal) -> [CategorySpending] {
        let categoryGroups = Dictionary(grouping: items) { $0.category }
        
        var categorySpending: [CategorySpending] = []
        
        for (category, categoryItems) in categoryGroups {
            let categoryTotal = categoryItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let percentage = totalSpent > 0 ? (NSDecimalNumber(decimal: categoryTotal).doubleValue / NSDecimalNumber(decimal: totalSpent).doubleValue * 100) : 0
            
            categorySpending.append(CategorySpending(
                category: category,
                totalSpent: categoryTotal,
                itemCount: categoryItems.count,
                percentage: percentage
            ))
        }
        
        // Return top 5 categories by spending
        return categorySpending
            .sorted { $0.totalSpent > $1.totalSpent }
            .prefix(5)
            .map { $0 }
    }
    
    private func calculateMonthlySpending(items: [Item]) -> [MonthlySpending] {
        let calendar = Calendar.current
        let itemsWithDates = items.filter { $0.purchaseDate != nil }
        
        // Group by month
        let monthGroups = Dictionary(grouping: itemsWithDates) { item -> Date in
            let components = calendar.dateComponents([.year, .month], from: item.purchaseDate!)
            return calendar.date(from: components) ?? Date()
        }
        
        var monthlySpending: [MonthlySpending] = []
        
        for (month, monthItems) in monthGroups {
            let amount = monthItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            monthlySpending.append(MonthlySpending(
                month: month,
                amount: amount,
                itemCount: monthItems.count
            ))
        }
        
        // Sort by month and return last 12 months
        return monthlySpending
            .sorted { $0.month < $1.month }
            .suffix(12)
    }
    
    private func calculateCategoryLeaders() async throws -> [CategoryLeader] {
        let items = try await itemRepository.fetchAll()
        let itemsWithStore = items.filter { $0.storeName != nil }
        
        // Group by category first
        let categoryGroups = Dictionary(grouping: itemsWithStore) { $0.category }
        
        var leaders: [CategoryLeader] = []
        
        for (category, categoryItems) in categoryGroups {
            // Group by store within category
            let storeGroups = Dictionary(grouping: categoryItems.filter { $0.storeName != nil }) { $0.storeName! }
            
            // Find store with most items in this category
            if let bestStore = storeGroups.max(by: { $0.value.count < $1.value.count }) {
                let averagePrice = bestStore.value.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) } / Decimal(bestStore.value.count)
                
                leaders.append(CategoryLeader(
                    category: category,
                    storeName: bestStore.key,
                    itemCount: bestStore.value.count,
                    averagePrice: averagePrice
                ))
            }
        }
        
        return leaders
    }
    
    private func frequencyScore(_ frequency: PurchaseFrequency) -> Int {
        switch frequency {
        case .daily: return 1
        case .weekly: return 2
        case .monthly: return 3
        case .occasional: return 4
        case .rare: return 5
        }
    }
}