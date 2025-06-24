import Foundation
import Core
import Combine

/// View model for portfolio value tracking
/// Swift 5.9 - No Swift 6 features
@MainActor
final class PortfolioValueViewModel: ObservableObject {
    // Dependencies
    private let itemRepository: any ItemRepository
    
    // Published properties
    @Published var currentValue: Decimal = 0
    @Published var valueChange: Decimal = 0
    @Published var valueChangePercent: Double = 0
    @Published var totalItems: Int = 0
    @Published var averageValue: Decimal = 0
    @Published var totalCost: Decimal = 0
    @Published var valueHistory: [PortfolioDataPoint] = []
    @Published var categoryValues: [CategoryValueData] = []
    @Published var mostValuableItems: [Item] = []
    @Published var peakValue: Decimal = 0
    @Published var peakValueDate: Date?
    @Published var averageGrowthRate: Double = 0
    @Published var totalDepreciation: Decimal = 0
    @Published var isLoading = false
    
    let currency = "USD"
    
    init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    func loadData(for timeRange: PortfolioValueView.TimeRange) async {
        isLoading = true
        
        do {
            // Load all items
            let allItems = try await itemRepository.fetchAll()
            
            // Calculate current portfolio value
            calculateCurrentValue(from: allItems)
            
            // Generate value history
            generateValueHistory(from: allItems, timeRange: timeRange)
            
            // Calculate category breakdown
            calculateCategoryBreakdown(from: allItems)
            
            // Find most valuable items
            updateMostValuableItems(from: allItems)
            
            // Calculate statistics
            calculateStatistics()
            
        } catch {
            print("Error loading portfolio data: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func calculateCurrentValue(from items: [Item]) {
        totalItems = items.count
        
        // Calculate total current value
        currentValue = items.reduce(0) { sum, item in
            sum + (item.value ?? item.purchasePrice ?? 0) * Decimal(item.quantity)
        }
        
        // Calculate total cost (purchase prices)
        totalCost = items.reduce(0) { sum, item in
            sum + (item.purchasePrice ?? 0) * Decimal(item.quantity)
        }
        
        // Calculate average value
        averageValue = totalItems > 0 ? currentValue / Decimal(totalItems) : 0
        
        // Calculate value change
        valueChange = currentValue - totalCost
        valueChangePercent = totalCost > 0 ? Double(truncating: (valueChange / totalCost * 100) as NSNumber) : 0
        
        // Calculate depreciation
        totalDepreciation = valueChange < 0 ? abs(valueChange) : 0
    }
    
    private func generateValueHistory(from items: [Item], timeRange: PortfolioValueView.TimeRange) {
        let calendar = Calendar.current
        let now = Date()
        
        // Determine date range
        let startDate: Date
        switch timeRange {
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .halfYear:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            // Find earliest purchase date
            let earliestDate = items.compactMap { $0.purchaseDate }.min() ?? now
            startDate = calendar.date(byAdding: .month, value: -1, to: earliestDate) ?? earliestDate
        }
        
        // Generate data points
        var dataPoints: [PortfolioDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= now {
            // Calculate portfolio value at this date
            let value = calculateValueAtDate(currentDate, items: items)
            dataPoints.append(PortfolioDataPoint(date: currentDate, value: value))
            
            // Move to next data point
            switch timeRange {
            case .month:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .quarter, .halfYear:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .year, .all:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Always include current value as last point
        if let lastPoint = dataPoints.last, lastPoint.date < now {
            dataPoints.append(PortfolioDataPoint(date: now, value: currentValue))
        }
        
        valueHistory = dataPoints
    }
    
    private func calculateValueAtDate(_ date: Date, items: [Item]) -> Decimal {
        // Filter items that existed at this date
        let existingItems = items.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            return purchaseDate <= date
        }
        
        // Calculate total value with simple depreciation model
        return existingItems.reduce(0) { sum, item in
            let purchasePrice = item.purchasePrice ?? 0
            let currentValue = item.value ?? purchasePrice
            
            // Simple linear depreciation calculation
            if let purchaseDate = item.purchaseDate {
                let monthsSincePurchase = Calendar.current.dateComponents([.month], from: purchaseDate, to: date).month ?? 0
                let depreciationRate: Decimal = 0.01 // 1% per month
                let depreciation = purchasePrice * depreciationRate * Decimal(monthsSincePurchase)
                let valueAtDate = max(currentValue - depreciation, purchasePrice * 0.2) // Minimum 20% of purchase price
                return sum + valueAtDate * Decimal(item.quantity)
            }
            
            return sum + currentValue * Decimal(item.quantity)
        }
    }
    
    private func calculateCategoryBreakdown(from items: [Item]) {
        var categoryData: [ItemCategory: (count: Int, value: Decimal, cost: Decimal)] = [:]
        
        for item in items {
            let value = (item.value ?? item.purchasePrice ?? 0) * Decimal(item.quantity)
            let cost = (item.purchasePrice ?? 0) * Decimal(item.quantity)
            let current = categoryData[item.category, default: (0, 0, 0)]
            categoryData[item.category] = (current.0 + 1, current.1 + value, current.2 + cost)
        }
        
        categoryValues = categoryData.map { category, data in
            let percentage = currentValue > 0 ? Double(truncating: (data.1 / currentValue * 100) as NSNumber) : 0
            return CategoryValueData(
                id: UUID(),
                category: category,
                itemCount: data.0,
                value: data.1,
                percentage: String(format: "%.1f%%", percentage),
                valueChange: data.1 - data.2
            )
        }
        .sorted { $0.value > $1.value }
    }
    
    private func updateMostValuableItems(from items: [Item]) {
        mostValuableItems = items
            .filter { item in
                (item.value ?? item.purchasePrice ?? 0) > 0
            }
            .sorted { item1, item2 in
                let value1 = (item1.value ?? item1.purchasePrice ?? 0) * Decimal(item1.quantity)
                let value2 = (item2.value ?? item2.purchasePrice ?? 0) * Decimal(item2.quantity)
                return value1 > value2
            }
    }
    
    private func calculateStatistics() {
        // Find peak value
        if let peak = valueHistory.max(by: { $0.value < $1.value }) {
            peakValue = peak.value
            peakValueDate = peak.date
        }
        
        // Calculate average growth rate (simplified)
        if valueHistory.count > 1,
           let firstValue = valueHistory.first?.value,
           let lastValue = valueHistory.last?.value,
           firstValue > 0 {
            let totalGrowth = Double(truncating: ((lastValue - firstValue) / firstValue * 100) as NSNumber)
            let months = max(1, valueHistory.count / 30) // Approximate months
            averageGrowthRate = totalGrowth / Double(months)
        }
    }
}

// MARK: - Data Models

struct PortfolioDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Decimal
}

struct CategoryValueData: Identifiable {
    let id: UUID
    let category: ItemCategory
    let itemCount: Int
    let value: Decimal
    let percentage: String
    let valueChange: Decimal
}