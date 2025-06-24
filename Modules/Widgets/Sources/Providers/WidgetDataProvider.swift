import Foundation
import Core
import WidgetKit

/// Service to provide data for widgets
/// Swift 5.9 - No Swift 6 features
public final class WidgetDataProvider {
    private let itemRepository: any ItemRepository
    private let receiptRepository: any ReceiptRepository
    private let warrantyRepository: any WarrantyRepository
    private let budgetRepository: (any BudgetRepository)?
    
    public init(
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        warrantyRepository: any WarrantyRepository,
        budgetRepository: (any BudgetRepository)?
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.warrantyRepository = warrantyRepository
        self.budgetRepository = budgetRepository
    }
    
    // MARK: - Inventory Stats
    
    public func getInventoryStats() async throws -> InventoryStatsEntry {
        let items = try await itemRepository.fetchAll()
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        // Calculate stats
        let totalItems = items.count
        let totalValue = items.reduce(Decimal.zero) { $0 + ($1.value ?? 0) }
        let favoriteItems = items.filter { $0.isFavorite }.count
        let recentlyAdded = items.filter { $0.createdAt > sevenDaysAgo }.count
        
        // Get top categories
        let categoryGroups = Dictionary(grouping: items) { $0.category }
        let topCategories = categoryGroups
            .map { (name: $0.key.rawValue, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(3)
        
        return InventoryStatsEntry(
            date: now,
            totalItems: totalItems,
            totalValue: totalValue,
            favoriteItems: favoriteItems,
            recentlyAdded: recentlyAdded,
            categories: Array(topCategories)
        )
    }
    
    // MARK: - Spending Summary
    
    public func getSpendingSummary() async throws -> SpendingSummaryEntry {
        let receipts = try await receiptRepository.fetchAll()
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate date ranges
        let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        
        // Calculate spending
        let monthlyReceipts = receipts.filter { $0.date >= startOfMonth }
        let weeklyReceipts = receipts.filter { $0.date >= startOfWeek }
        let lastMonthReceipts = receipts.filter { 
            $0.date >= startOfLastMonth && $0.date < startOfMonth 
        }
        
        let monthlySpending = monthlyReceipts.reduce(Decimal.zero) { $0 + $1.total }
        let weeklySpending = weeklyReceipts.reduce(Decimal.zero) { $0 + $1.total }
        let lastMonthSpending = lastMonthReceipts.reduce(Decimal.zero) { $0 + $1.total }
        
        // Calculate trend
        let trend: SpendingSummaryEntry.SpendingTrend
        if lastMonthSpending == 0 {
            trend = .stable
        } else {
            let percentage = ((monthlySpending - lastMonthSpending) / lastMonthSpending) * 100
            if abs(percentage) < 5 {
                trend = .stable
            } else if percentage > 0 {
                trend = .up(percentage: Double(truncating: percentage as NSNumber))
            } else {
                trend = .down(percentage: abs(Double(truncating: percentage as NSNumber)))
            }
        }
        
        // Get top category (from items with receipts)
        let items = try await itemRepository.fetchAll()
        let itemsWithReceipts = items.filter { item in
            receipts.contains { $0.itemIds.contains(item.id) }
        }
        
        let categorySpending = Dictionary(grouping: itemsWithReceipts) { $0.category }
            .mapValues { items in
                items.reduce(Decimal.zero) { $0 + ($1.purchasePrice ?? 0) }
            }
        
        let topCategory = categorySpending
            .max { $0.value < $1.value }
            .map { (name: $0.key.rawValue, amount: $0.value) }
        
        // Get recent purchases
        let recentPurchases = items
            .filter { $0.purchaseDate != nil }
            .sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
            .prefix(5)
            .compactMap { item -> (name: String, price: Decimal, date: Date)? in
                guard let price = item.purchasePrice,
                      let date = item.purchaseDate else { return nil }
                return (name: item.name, price: price, date: date)
            }
        
        return SpendingSummaryEntry(
            date: now,
            monthlySpending: monthlySpending,
            weeklySpending: weeklySpending,
            topCategory: topCategory,
            recentPurchases: Array(recentPurchases),
            spendingTrend: trend
        )
    }
    
    // MARK: - Warranty Expiration
    
    public func getWarrantyExpirations() async throws -> WarrantyExpirationEntry {
        let warranties = try await warrantyRepository.fetchAll()
        let items = try await itemRepository.fetchAll()
        let now = Date()
        
        // Create lookup for items
        let itemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        
        // Filter and sort warranties
        let activeWarranties = warranties.filter { warranty in
            warranty.status == .active || warranty.status == .expiringSoon
        }
        
        let expiringWarranties = activeWarranties
            .compactMap { warranty -> WarrantyExpirationEntry.ExpiringWarranty? in
                guard let item = warranty.itemId.flatMap({ itemsById[$0] }) else { return nil }
                
                let daysRemaining = Calendar.current.dateComponents(
                    [.day],
                    from: now,
                    to: warranty.endDate
                ).day ?? 0
                
                return WarrantyExpirationEntry.ExpiringWarranty(
                    itemName: item.name,
                    provider: warranty.provider,
                    expirationDate: warranty.endDate,
                    daysRemaining: daysRemaining,
                    status: warranty.status
                )
            }
            .sorted { $0.daysRemaining < $1.daysRemaining }
            .prefix(5)
        
        let expiredCount = warranties.filter { $0.status == .expired }.count
        let activeCount = warranties.filter { $0.status == .active }.count
        
        return WarrantyExpirationEntry(
            date: now,
            expiringWarranties: Array(expiringWarranties),
            expiredCount: expiredCount,
            activeCount: activeCount
        )
    }
    
    // MARK: - Recent Items
    
    public func getRecentItems() async throws -> RecentItemsEntry {
        let items = try await itemRepository.fetchAll()
        let now = Date()
        let calendar = Calendar.current
        
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        
        // Get recent items
        let recentItems = items
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { item in
                RecentItemsEntry.RecentItem(
                    name: item.name,
                    category: item.category,
                    price: item.purchasePrice,
                    imageData: nil, // Would load from photo repository in real app
                    addedDate: item.createdAt,
                    location: nil // Would load from location repository
                )
            }
        
        // Calculate stats
        let totalAddedToday = items.filter { $0.createdAt >= todayStart }.count
        let totalAddedThisWeek = items.filter { $0.createdAt >= weekStart }.count
        
        return RecentItemsEntry(
            date: now,
            items: Array(recentItems),
            totalAddedToday: totalAddedToday,
            totalAddedThisWeek: totalAddedThisWeek
        )
    }
}