import Foundation

/// Service for calculating time-based analytics and trends
/// Swift 5.9 - No Swift 6 features
public final class TimeBasedAnalyticsService {
    private let itemRepository: any ItemRepository
    private let calendar = Calendar.current
    
    public init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    /// Calculate analytics for a specific period
    public func calculateAnalytics(for period: AnalyticsPeriod, startDate: Date? = nil) async throws -> TimeBasedAnalytics {
        let dateRange = getDateRange(for: period, startDate: startDate)
        let items = try await fetchItemsInRange(dateRange)
        
        // Calculate metrics
        let metrics = calculateMetrics(for: items, in: dateRange)
        
        // Generate trend data
        let trends = generateTrendData(for: items, period: period, in: dateRange)
        
        // Compare with previous period
        let comparison = try await calculatePeriodComparison(
            currentRange: dateRange,
            period: period,
            currentMetrics: metrics
        )
        
        // Generate insights
        let insights = generateInsights(
            metrics: metrics,
            trends: trends,
            comparison: comparison,
            period: period
        )
        
        return TimeBasedAnalytics(
            period: period,
            startDate: dateRange.start,
            endDate: dateRange.end,
            metrics: metrics,
            trends: trends,
            comparisons: comparison,
            insights: insights
        )
    }
    
    /// Get monthly trends for the last N months
    public func getMonthlyTrends(months: Int = 12) async throws -> [TrendData] {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -months, to: endDate) ?? endDate
        let dateRange = DateInterval(start: startDate, end: endDate)
        
        let items = try await fetchItemsInRange(dateRange)
        return generateTrendData(for: items, period: .month, in: dateRange)
    }
    
    /// Get yearly trends
    public func getYearlyTrends(years: Int = 5) async throws -> [TrendData] {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -years, to: endDate) ?? endDate
        let dateRange = DateInterval(start: startDate, end: endDate)
        
        let items = try await fetchItemsInRange(dateRange)
        return generateTrendData(for: items, period: .year, in: dateRange)
    }
    
    /// Analyze seasonal patterns
    public func analyzeSeasonalPatterns() async throws -> [SeasonalPattern] {
        let items = try await itemRepository.fetchAll()
        return calculateSeasonalPatterns(from: items)
    }
    
    /// Get spending heatmap data
    public func getSpendingHeatmap(year: Int? = nil) async throws -> [[Double]] {
        let targetYear = year ?? calendar.component(.year, from: Date())
        let items = try await itemRepository.fetchAll()
        
        // Filter items for the target year
        let yearItems = items.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            return calendar.component(.year, from: purchaseDate) == targetYear
        }
        
        // Create 12x31 matrix for months x days
        var heatmap: [[Double]] = Array(repeating: Array(repeating: 0, count: 31), count: 12)
        
        for item in yearItems {
            guard let purchaseDate = item.purchaseDate,
                  let price = item.purchasePrice else { continue }
            
            let month = calendar.component(.month, from: purchaseDate) - 1
            let day = calendar.component(.day, from: purchaseDate) - 1
            
            if month < 12 && day < 31 {
                heatmap[month][day] += NSDecimalNumber(decimal: price).doubleValue
            }
        }
        
        return heatmap
    }
    
    /// Get acquisition rate analysis
    public func getAcquisitionRateAnalysis(period: AnalyticsPeriod = .month) async throws -> AcquisitionAnalysis {
        let items = try await itemRepository.fetchAll()
        let sortedItems = items.sorted { ($0.createdAt) < ($1.createdAt) }
        
        guard let firstItem = sortedItems.first else {
            return AcquisitionAnalysis(
                averageItemsPerPeriod: 0,
                peakPeriod: nil,
                trend: .stable,
                projectedNextPeriod: 0
            )
        }
        
        let dateRange = DateInterval(start: firstItem.createdAt, end: Date())
        let periodCounts = groupItemsByPeriod(sortedItems, period: period, in: dateRange)
        
        let average = periodCounts.isEmpty ? 0 : periodCounts.reduce(0, +) / Double(periodCounts.count)
        let peakIndex = periodCounts.enumerated().max(by: { $0.element < $1.element })?.offset
        
        // Calculate trend
        let recentAverage = periodCounts.suffix(3).reduce(0, +) / Double(min(3, periodCounts.count))
        let trend: TrendDirection = recentAverage > average * 1.1 ? .up : 
                                   recentAverage < average * 0.9 ? .down : .stable
        
        return AcquisitionAnalysis(
            averageItemsPerPeriod: average,
            peakPeriod: peakIndex.map { getPeriodDate(index: $0, from: firstItem.createdAt, period: period) },
            trend: trend,
            projectedNextPeriod: Int(recentAverage)
        )
    }
    
    // MARK: - Private Methods
    
    private func getDateRange(for period: AnalyticsPeriod, startDate: Date?) -> DateInterval {
        let now = Date()
        let start: Date
        
        switch period {
        case .day:
            start = startDate ?? calendar.startOfDay(for: now)
        case .week:
            start = startDate ?? calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            start = startDate ?? calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            start = startDate ?? calendar.dateInterval(of: .quarter, for: now)?.start ?? now
        case .year:
            start = startDate ?? calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .custom:
            start = startDate ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }
        
        let end: Date
        if let startDate = startDate {
            end = calendar.date(byAdding: period.calendarComponent, value: 1, to: startDate) ?? now
        } else {
            end = now
        }
        
        return DateInterval(start: start, end: min(end, now))
    }
    
    private func fetchItemsInRange(_ range: DateInterval) async throws -> [Item] {
        let allItems = try await itemRepository.fetchAll()
        return allItems.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            return range.contains(purchaseDate)
        }
    }
    
    private func calculateMetrics(for items: [Item], in range: DateInterval) -> TimeMetrics {
        let totalSpent = items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
        let itemsAdded = items.count
        let averageValue = itemsAdded > 0 ? totalSpent / Decimal(itemsAdded) : 0
        
        let mostExpensive = items.max { ($0.purchasePrice ?? 0) < ($1.purchasePrice ?? 0) }
        
        // Find most active day
        let dayGroups = Dictionary(grouping: items) { item -> Date? in
            guard let date = item.purchaseDate else { return nil }
            return calendar.startOfDay(for: date)
        }
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }?.key
        
        // Category breakdown
        let categoryBreakdown = calculateCategoryBreakdown(items: items, totalSpent: totalSpent)
        
        // Store breakdown
        let storeBreakdown = calculateStoreBreakdown(items: items, totalSpent: totalSpent)
        
        return TimeMetrics(
            totalSpent: totalSpent,
            itemsAdded: itemsAdded,
            averageItemValue: averageValue,
            mostExpensiveItem: mostExpensive,
            mostActiveDay: mostActiveDay,
            categoryBreakdown: categoryBreakdown,
            storeBreakdown: storeBreakdown
        )
    }
    
    private func calculateCategoryBreakdown(items: [Item], totalSpent: Decimal) -> [CategoryTimeMetric] {
        let categoryGroups = Dictionary(grouping: items) { $0.category }
        
        return categoryGroups.compactMap { category, items in
            let categoryTotal = items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let percentage = totalSpent > 0 ? 
                NSDecimalNumber(decimal: categoryTotal).doubleValue / NSDecimalNumber(decimal: totalSpent).doubleValue * 100 : 0
            
            return CategoryTimeMetric(
                category: category,
                totalSpent: categoryTotal,
                itemCount: items.count,
                percentageOfTotal: percentage
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func calculateStoreBreakdown(items: [Item], totalSpent: Decimal) -> [StoreTimeMetric] {
        let storeItems = items.filter { $0.storeName != nil }
        let storeGroups = Dictionary(grouping: storeItems) { $0.storeName! }
        
        return storeGroups.compactMap { store, items in
            let storeTotal = items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let percentage = totalSpent > 0 ? 
                NSDecimalNumber(decimal: storeTotal).doubleValue / NSDecimalNumber(decimal: totalSpent).doubleValue * 100 : 0
            
            return StoreTimeMetric(
                storeName: store,
                totalSpent: storeTotal,
                itemCount: items.count,
                percentageOfTotal: percentage
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func generateTrendData(for items: [Item], period: AnalyticsPeriod, in range: DateInterval) -> [TrendData] {
        var trends: [TrendData] = []
        var currentDate = range.start
        
        while currentDate < range.end {
            let periodEnd = calendar.date(byAdding: period.calendarComponent, value: 1, to: currentDate) ?? currentDate
            let periodRange = DateInterval(start: currentDate, end: min(periodEnd, range.end))
            
            let periodItems = items.filter { item in
                guard let purchaseDate = item.purchaseDate else { return false }
                return periodRange.contains(purchaseDate)
            }
            
            let periodSpending = periodItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let label = formatPeriodLabel(date: currentDate, period: period)
            
            trends.append(TrendData(
                date: currentDate,
                value: periodSpending,
                itemCount: periodItems.count,
                label: label
            ))
            
            currentDate = periodEnd
        }
        
        return trends
    }
    
    private func formatPeriodLabel(date: Date, period: AnalyticsPeriod) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .day:
            formatter.dateFormat = "MMM d"
        case .week:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMM yyyy"
        case .quarter:
            let quarter = calendar.component(.quarter, from: date)
            let year = calendar.component(.year, from: date)
            return "Q\(quarter) \(year)"
        case .year:
            formatter.dateFormat = "yyyy"
        case .custom:
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func calculatePeriodComparison(
        currentRange: DateInterval,
        period: AnalyticsPeriod,
        currentMetrics: TimeMetrics
    ) async throws -> PeriodComparison? {
        // Calculate previous period range
        guard let previousStart = calendar.date(
            byAdding: period.calendarComponent,
            value: -1,
            to: currentRange.start
        ) else { return nil }
        
        let previousEnd = currentRange.start
        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        
        // Get previous period items
        let previousItems = try await fetchItemsInRange(previousRange)
        let previousMetrics = calculateMetrics(for: previousItems, in: previousRange)
        
        // Calculate changes
        let spendingChange = currentMetrics.totalSpent - previousMetrics.totalSpent
        let spendingChangePercentage = previousMetrics.totalSpent > 0 ?
            NSDecimalNumber(decimal: spendingChange).doubleValue / NSDecimalNumber(decimal: previousMetrics.totalSpent).doubleValue * 100 : 0
        
        let itemCountChange = currentMetrics.itemsAdded - previousMetrics.itemsAdded
        let itemCountChangePercentage = previousMetrics.itemsAdded > 0 ?
            Double(itemCountChange) / Double(previousMetrics.itemsAdded) * 100 : 0
        
        let trend: TrendDirection = spendingChange > 0 ? .up : spendingChange < 0 ? .down : .stable
        
        return PeriodComparison(
            previousPeriod: previousMetrics,
            spendingChange: spendingChange,
            spendingChangePercentage: spendingChangePercentage,
            itemCountChange: itemCountChange,
            itemCountChangePercentage: itemCountChangePercentage,
            trend: trend
        )
    }
    
    private func generateInsights(
        metrics: TimeMetrics,
        trends: [TrendData],
        comparison: PeriodComparison?,
        period: AnalyticsPeriod
    ) -> [TimeInsight] {
        var insights: [TimeInsight] = []
        
        // Spending insights
        if let comparison = comparison {
            if abs(comparison.spendingChangePercentage) > 20 {
                let direction = comparison.trend == .up ? "increased" : "decreased"
                insights.append(TimeInsight(
                    type: .spending,
                    title: "Significant Spending Change",
                    description: "Your spending \(direction) by \(Int(abs(comparison.spendingChangePercentage)))% compared to last \(period.rawValue.lowercased())",
                    impact: abs(comparison.spendingChangePercentage) > 50 ? .high : .medium
                ))
            }
        }
        
        // Category insights
        if let topCategory = metrics.categoryBreakdown.first, topCategory.percentageOfTotal > 40 {
            insights.append(TimeInsight(
                type: .category,
                title: "Dominant Category",
                description: "\(topCategory.category.rawValue) accounts for \(Int(topCategory.percentageOfTotal))% of your spending",
                impact: topCategory.percentageOfTotal > 60 ? .high : .medium
            ))
        }
        
        // Acquisition insights
        if metrics.itemsAdded > 20 {
            insights.append(TimeInsight(
                type: .acquisition,
                title: "High Acquisition Rate",
                description: "You added \(metrics.itemsAdded) items this \(period.rawValue.lowercased())",
                impact: metrics.itemsAdded > 50 ? .high : .medium
            ))
        }
        
        // Trend insights
        if trends.count > 3 {
            let recentTrend = trends.suffix(3).map { NSDecimalNumber(decimal: $0.value).doubleValue }
            let average = recentTrend.reduce(0, +) / Double(recentTrend.count)
            let firstValue = NSDecimalNumber(decimal: trends.first?.value ?? 0).doubleValue
            
            if average > firstValue * 1.5 {
                insights.append(TimeInsight(
                    type: .anomaly,
                    title: "Upward Trend Detected",
                    description: "Your spending has been consistently increasing",
                    impact: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func calculateSeasonalPatterns(from items: [Item]) -> [SeasonalPattern] {
        let itemsWithDates = items.filter { $0.purchaseDate != nil }
        
        return Season.allCases.map { season in
            let seasonItems = itemsWithDates.filter { item in
                let month = calendar.component(.month, from: item.purchaseDate!)
                return season.months.contains(month)
            }
            
            let totalSpending = seasonItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let averageSpending = seasonItems.isEmpty ? 0 : totalSpending / Decimal(seasonItems.count)
            
            // Find most common categories
            let categoryGroups = Dictionary(grouping: seasonItems) { $0.category }
            let topCategories = categoryGroups.sorted { $0.value.count > $1.value.count }
                .prefix(3)
                .map { $0.key }
            
            // Find peak month
            let monthGroups = Dictionary(grouping: seasonItems) { item -> Int in
                calendar.component(.month, from: item.purchaseDate!)
            }
            let peakMonth = monthGroups.max { $0.value.count < $1.value.count }?.key ?? season.months.first!
            let monthName = DateFormatter().monthSymbols[peakMonth - 1]
            
            return SeasonalPattern(
                season: season,
                averageSpending: averageSpending,
                typicalCategories: Array(topCategories),
                peakMonth: monthName
            )
        }
    }
    
    private func groupItemsByPeriod(_ items: [Item], period: AnalyticsPeriod, in range: DateInterval) -> [Double] {
        var counts: [Double] = []
        var currentDate = range.start
        
        while currentDate < range.end {
            let periodEnd = calendar.date(byAdding: period.calendarComponent, value: 1, to: currentDate) ?? currentDate
            let periodRange = DateInterval(start: currentDate, end: min(periodEnd, range.end))
            
            let periodCount = items.filter { item in
                periodRange.contains(item.createdAt)
            }.count
            
            counts.append(Double(periodCount))
            currentDate = periodEnd
        }
        
        return counts
    }
    
    private func getPeriodDate(index: Int, from startDate: Date, period: AnalyticsPeriod) -> Date {
        calendar.date(byAdding: period.calendarComponent, value: index, to: startDate) ?? startDate
    }
}

/// Acquisition rate analysis
public struct AcquisitionAnalysis {
    public let averageItemsPerPeriod: Double
    public let peakPeriod: Date?
    public let trend: TrendDirection
    public let projectedNextPeriod: Int
}