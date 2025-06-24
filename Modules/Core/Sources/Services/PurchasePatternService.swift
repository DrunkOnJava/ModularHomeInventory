import Foundation

/// Service for analyzing purchase patterns and buying habits
/// Swift 5.9 - No Swift 6 features
public final class PurchasePatternService {
    private let itemRepository: any ItemRepository
    private let calendar = Calendar.current
    
    public init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    /// Analyze purchase patterns for a given time period
    public func analyzePurchasePatterns(
        startDate: Date? = nil,
        endDate: Date = Date()
    ) async throws -> PurchasePattern {
        let items = try await itemRepository.fetchAll()
        
        // Default to 1 year of data if no start date
        let analysisStartDate = startDate ?? calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        let periodAnalyzed = DateInterval(start: analysisStartDate, end: endDate)
        
        // Filter items within the period
        let relevantItems = items.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            return periodAnalyzed.contains(purchaseDate)
        }
        
        var patterns: [PatternType] = []
        
        // Analyze different pattern types
        patterns.append(contentsOf: analyzeRecurringPatterns(items: relevantItems))
        patterns.append(contentsOf: analyzeSeasonalPatterns(items: relevantItems))
        patterns.append(contentsOf: analyzeCategoryPreferences(items: relevantItems))
        patterns.append(contentsOf: analyzeBrandLoyalty(items: relevantItems))
        patterns.append(contentsOf: analyzePriceRanges(items: relevantItems))
        patterns.append(contentsOf: analyzeShoppingTimes(items: relevantItems))
        patterns.append(contentsOf: analyzeRetailerPreferences(items: relevantItems))
        patterns.append(contentsOf: analyzeBulkBuying(items: relevantItems))
        
        // Generate insights from patterns
        let insights = generateInsights(from: patterns, items: relevantItems)
        
        // Generate recommendations
        let recommendations = generateRecommendations(from: patterns, insights: insights)
        
        return PurchasePattern(
            periodAnalyzed: periodAnalyzed,
            patterns: patterns,
            insights: insights,
            recommendations: recommendations
        )
    }
    
    // MARK: - Pattern Analysis Methods
    
    private func analyzeRecurringPatterns(items: [Item]) -> [PatternType] {
        // Group items by name to find recurring purchases
        let itemGroups = Dictionary(grouping: items.filter { $0.purchaseDate != nil }) { $0.name.lowercased() }
        
        var patterns: [PatternType] = []
        
        for (itemName, groupedItems) in itemGroups where groupedItems.count >= 2 {
            let sortedItems = groupedItems.sorted { ($0.purchaseDate ?? Date()) < ($1.purchaseDate ?? Date()) }
            
            // Calculate intervals between purchases
            var intervals: [TimeInterval] = []
            for i in 1..<sortedItems.count {
                if let prevDate = sortedItems[i-1].purchaseDate,
                   let currDate = sortedItems[i].purchaseDate {
                    intervals.append(currDate.timeIntervalSince(prevDate))
                }
            }
            
            guard !intervals.isEmpty else { continue }
            
            // Calculate average interval and standard deviation
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let averageDays = averageInterval / 86400 // Convert to days
            
            // Determine frequency
            let frequency = determineFrequency(days: averageDays)
            
            // Calculate confidence based on consistency
            let variance = intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
            let standardDeviation = sqrt(variance)
            let confidence = max(0, 1 - (standardDeviation / averageInterval))
            
            if confidence > 0.5 { // Only include patterns with reasonable confidence
                let lastPurchaseDate = sortedItems.last?.purchaseDate ?? Date()
                let nextExpectedDate = Date(timeInterval: averageInterval, since: lastPurchaseDate)
                
                let pattern = RecurringPattern(
                    itemName: groupedItems.first?.name ?? itemName,
                    category: groupedItems.first?.category ?? .other,
                    averageInterval: averageDays,
                    frequency: frequency,
                    lastPurchaseDate: lastPurchaseDate,
                    nextExpectedDate: nextExpectedDate,
                    confidence: confidence
                )
                
                patterns.append(.recurring(pattern))
            }
        }
        
        return patterns
    }
    
    private func analyzeSeasonalPatterns(items: [Item]) -> [PatternType] {
        var seasonalPatterns: [PatternType] = []
        
        for season in Season.allCases {
            let seasonItems = items.filter { item in
                guard let date = item.purchaseDate else { return false }
                let month = calendar.component(.month, from: date)
                return season.months.contains(month)
            }
            
            guard !seasonItems.isEmpty else { continue }
            
            let totalSpending = seasonItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let categories = Dictionary(grouping: seasonItems) { $0.category }
                .sorted { $0.value.count > $1.value.count }
                .prefix(3)
                .map { $0.key }
            
            // Find peak month
            let monthGroups = Dictionary(grouping: seasonItems) { item -> Int in
                calendar.component(.month, from: item.purchaseDate!)
            }
            let peakMonth = monthGroups.max { $0.value.count < $1.value.count }?.key ?? season.months.first!
            let monthName = DateFormatter().monthSymbols[peakMonth - 1]
            
            let pattern = SeasonalBuyingPattern(
                season: season,
                categories: Array(categories),
                averageSpending: totalSpending / Decimal(seasonItems.count),
                peakMonth: monthName,
                itemCount: seasonItems.count
            )
            
            seasonalPatterns.append(.seasonal(pattern))
        }
        
        return seasonalPatterns
    }
    
    private func analyzeCategoryPreferences(items: [Item]) -> [PatternType] {
        let categoryGroups = Dictionary(grouping: items) { $0.category }
        let totalItems = items.count
        let totalSpent = items.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
        
        var patterns: [PatternType] = []
        
        for (category, categoryItems) in categoryGroups {
            let categorySpent = categoryItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let averagePrice = categoryItems.isEmpty ? 0 : categorySpent / Decimal(categoryItems.count)
            let percentage = totalSpent > 0 ? 
                NSDecimalNumber(decimal: categorySpent).doubleValue / NSDecimalNumber(decimal: totalSpent).doubleValue * 100 : 0
            
            // Determine trend (simplified - in real app would compare to previous period)
            let trend: TrendDirection = .stable
            
            let preference = CategoryPreference(
                category: category,
                purchaseCount: categoryItems.count,
                totalSpent: categorySpent,
                averagePrice: averagePrice,
                percentageOfTotal: percentage,
                trend: trend
            )
            
            patterns.append(.categoryPreference(preference))
        }
        
        return patterns.sorted { 
            if case .categoryPreference(let p1) = $0,
               case .categoryPreference(let p2) = $1 {
                return p1.totalSpent > p2.totalSpent
            }
            return false
        }
    }
    
    private func analyzeBrandLoyalty(items: [Item]) -> [PatternType] {
        let itemsWithBrand = items.filter { $0.brand != nil }
        let brandGroups = Dictionary(grouping: itemsWithBrand) { item in
            "\(item.brand ?? "")_\(item.category.rawValue)"
        }
        
        var patterns: [PatternType] = []
        
        for (brandCategory, brandItems) in brandGroups where brandItems.count >= 2 {
            guard let firstItem = brandItems.first,
                  let brand = firstItem.brand else { continue }
            
            let totalSpent = brandItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            
            // Calculate loyalty score based on repeat purchases
            let categoryItemCount = items.filter { $0.category == firstItem.category }.count
            let loyaltyScore = Double(brandItems.count) / Double(max(categoryItemCount, 1))
            
            let loyalty = BrandLoyalty(
                brand: brand,
                category: firstItem.category,
                purchaseCount: brandItems.count,
                loyaltyScore: min(loyaltyScore, 1.0),
                totalSpent: totalSpent
            )
            
            patterns.append(.brandLoyalty(loyalty))
        }
        
        return patterns.sorted {
            if case .brandLoyalty(let l1) = $0,
               case .brandLoyalty(let l2) = $1 {
                return l1.loyaltyScore > l2.loyaltyScore
            }
            return false
        }.prefix(10).map { $0 } // Top 10 brand loyalties
    }
    
    private func analyzePriceRanges(items: [Item]) -> [PatternType] {
        let categoryGroups = Dictionary(grouping: items.filter { $0.purchasePrice != nil }) { $0.category }
        
        var patterns: [PatternType] = []
        
        for (category, categoryItems) in categoryGroups where categoryItems.count >= 3 {
            let prices = categoryItems.compactMap { $0.purchasePrice }
            guard !prices.isEmpty else { continue }
            
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 0
            let averagePrice = prices.reduce(0, +) / Decimal(prices.count)
            
            // Find sweet spot (mode or median)
            let sortedPrices = prices.sorted()
            let sweetSpot = sortedPrices[sortedPrices.count / 2]
            
            // Create price distribution
            var priceDistribution: [PriceRange: Int] = [:]
            for price in prices {
                let range = determinePriceRange(price: price)
                priceDistribution[range, default: 0] += 1
            }
            
            let pattern = PriceRangePattern(
                category: category,
                minPrice: minPrice,
                maxPrice: maxPrice,
                averagePrice: averagePrice,
                sweetSpot: sweetSpot,
                priceDistribution: priceDistribution
            )
            
            patterns.append(.priceRange(pattern))
        }
        
        return patterns
    }
    
    private func analyzeShoppingTimes(items: [Item]) -> [PatternType] {
        let itemsWithDates = items.filter { $0.purchaseDate != nil }
        guard !itemsWithDates.isEmpty else { return [] }
        
        // Analyze day of week
        let dayGroups = Dictionary(grouping: itemsWithDates) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: item.purchaseDate!)
        }
        let preferredDay = dayGroups.max { $0.value.count < $1.value.count }?.key ?? "Unknown"
        
        // Analyze time of day
        let timeGroups = Dictionary(grouping: itemsWithDates) { item -> TimeOfDay in
            let hour = calendar.component(.hour, from: item.purchaseDate!)
            switch hour {
            case 6..<9: return .earlyMorning
            case 9..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            default: return .night
            }
        }
        let preferredTime = timeGroups.max { $0.value.count < $1.value.count }?.key ?? .afternoon
        
        // Weekend vs weekday
        let weekendCount = itemsWithDates.filter { item in
            let weekday = calendar.component(.weekday, from: item.purchaseDate!)
            return weekday == 1 || weekday == 7
        }.count
        let weekdayCount = itemsWithDates.count - weekendCount
        
        let weekdayPreference: WeekdayPreference
        if Double(weekendCount) > Double(weekdayCount) * 1.5 {
            weekdayPreference = .weekend
        } else if Double(weekdayCount) > Double(weekendCount) * 1.5 {
            weekdayPreference = .weekday
        } else {
            weekdayPreference = .mixed
        }
        
        // Monthly distribution
        let monthlyDistribution = Dictionary(grouping: itemsWithDates) { item -> Int in
            calendar.component(.day, from: item.purchaseDate!)
        }.mapValues { $0.count }
        
        let pattern = ShoppingTimePattern(
            preferredDayOfWeek: preferredDay,
            preferredTimeOfDay: preferredTime,
            weekendVsWeekday: weekdayPreference,
            monthlyDistribution: monthlyDistribution
        )
        
        return [.shoppingTime(pattern)]
    }
    
    private func analyzeRetailerPreferences(items: [Item]) -> [PatternType] {
        let itemsWithStore = items.filter { $0.storeName != nil }
        let storeGroups = Dictionary(grouping: itemsWithStore) { $0.storeName! }
        
        var patterns: [PatternType] = []
        
        let sortedStores = storeGroups.sorted { $0.value.count > $1.value.count }
        
        for (index, (store, storeItems)) in sortedStores.enumerated() {
            let totalSpent = storeItems.reduce(Decimal(0)) { $0 + ($1.purchasePrice ?? 0) }
            let averageBasket = storeItems.isEmpty ? 0 : totalSpent / Decimal(storeItems.count)
            
            let categories = Dictionary(grouping: storeItems) { $0.category }
                .sorted { $0.value.count > $1.value.count }
                .prefix(3)
                .map { $0.key }
            
            let preference = RetailerPreference(
                retailer: store,
                visitCount: storeItems.count,
                totalSpent: totalSpent,
                averageBasketSize: averageBasket,
                categories: Array(categories),
                loyaltyRank: index + 1
            )
            
            patterns.append(.retailerPreference(preference))
        }
        
        return patterns.prefix(10).map { $0 } // Top 10 retailers
    }
    
    private func analyzeBulkBuying(items: [Item]) -> [PatternType] {
        let multiQuantityItems = items.filter { $0.quantity > 1 }
        let itemGroups = Dictionary(grouping: multiQuantityItems) { $0.name.lowercased() }
        
        var patterns: [PatternType] = []
        
        for (itemName, bulkItems) in itemGroups where bulkItems.count >= 2 {
            let averageQuantity = bulkItems.reduce(0) { $0 + $1.quantity } / bulkItems.count
            let category = bulkItems.first?.category ?? .other
            
            // Estimate bulk savings (simplified)
            let bulkPrices = bulkItems.compactMap { item -> Decimal? in
                guard let price = item.purchasePrice else { return nil }
                return price / Decimal(item.quantity)
            }
            
            let estimatedSavings = !bulkPrices.isEmpty ? 
                (bulkPrices.max() ?? 0) - (bulkPrices.min() ?? 0) : 0
            
            let pattern = BulkBuyingPattern(
                itemType: bulkItems.first?.name ?? itemName,
                category: category,
                averageQuantity: averageQuantity,
                bulkSavings: estimatedSavings * Decimal(averageQuantity),
                frequency: determineFrequency(days: 30) // Simplified
            )
            
            patterns.append(.bulkBuying(pattern))
        }
        
        return patterns
    }
    
    // MARK: - Helper Methods
    
    private func determineFrequency(days: Double) -> PurchaseFrequency {
        switch days {
        case 0..<2: return .daily
        case 2..<10: return .weekly
        case 10..<20: return .biweekly
        case 20..<45: return .monthly
        case 45..<120: return .quarterly
        case 120..<500: return .annually
        default: return .irregular
        }
    }
    
    private func determinePriceRange(price: Decimal) -> PriceRange {
        let amount = NSDecimalNumber(decimal: price).doubleValue
        switch amount {
        case 0..<10: return .under10
        case 10..<25: return .range10to25
        case 25..<50: return .range25to50
        case 50..<100: return .range50to100
        case 100..<250: return .range100to250
        case 250..<500: return .range250to500
        case 500..<1000: return .range500to1000
        default: return .over1000
        }
    }
    
    // MARK: - Insights Generation
    
    private func generateInsights(from patterns: [PatternType], items: [Item]) -> [PatternInsight] {
        var insights: [PatternInsight] = []
        
        // Recurring purchase insights
        let recurringPatterns = patterns.compactMap { pattern -> RecurringPattern? in
            if case .recurring(let p) = pattern { return p }
            return nil
        }
        
        if recurringPatterns.count >= 3 {
            insights.append(PatternInsight(
                type: .spending,
                title: "Regular Shopping Habits",
                description: "You have \(recurringPatterns.count) items you buy regularly. Consider setting up subscriptions or bulk buying.",
                impact: .medium
            ))
        }
        
        // Category spending insights
        let categoryPatterns = patterns.compactMap { pattern -> CategoryPreference? in
            if case .categoryPreference(let p) = pattern { return p }
            return nil
        }.sorted { $0.percentageOfTotal > $1.percentageOfTotal }
        
        if let topCategory = categoryPatterns.first, topCategory.percentageOfTotal > 40 {
            insights.append(PatternInsight(
                type: .category,
                title: "Dominant Category",
                description: "\(topCategory.category.rawValue) accounts for \(Int(topCategory.percentageOfTotal))% of your spending",
                impact: .high
            ))
        }
        
        // Brand loyalty insights
        let brandPatterns = patterns.compactMap { pattern -> BrandLoyalty? in
            if case .brandLoyalty(let p) = pattern { return p }
            return nil
        }
        
        if let topBrand = brandPatterns.first, topBrand.loyaltyScore > 0.7 {
            insights.append(PatternInsight(
                type: .spending,
                title: "Strong Brand Loyalty",
                description: "You consistently buy \(topBrand.brand) for \(topBrand.category.rawValue)",
                impact: .low,
                actionable: false
            ))
        }
        
        return insights
    }
    
    // MARK: - Recommendations Generation
    
    private func generateRecommendations(
        from patterns: [PatternType],
        insights: [PatternInsight]
    ) -> [PatternRecommendation] {
        var recommendations: [PatternRecommendation] = []
        
        // Bulk buying recommendations
        let bulkPatterns = patterns.compactMap { pattern -> BulkBuyingPattern? in
            if case .bulkBuying(let p) = pattern { return p }
            return nil
        }
        
        for bulkPattern in bulkPatterns where bulkPattern.bulkSavings > 10 {
            recommendations.append(PatternRecommendation(
                type: .bulkBuy,
                title: "Bulk Buy \(bulkPattern.itemType)",
                description: "You could save approximately $\(bulkPattern.bulkSavings.formatted()) by buying in bulk",
                potentialSavings: bulkPattern.bulkSavings,
                priority: .high
            ))
        }
        
        // Recurring purchase recommendations
        let recurringPatterns = patterns.compactMap { pattern -> RecurringPattern? in
            if case .recurring(let p) = pattern { return p }
            return nil
        }
        
        for recurring in recurringPatterns where recurring.confidence > 0.8 {
            let daysUntilNext = recurring.nextExpectedDate.timeIntervalSinceNow / 86400
            if daysUntilNext < 7 && daysUntilNext > 0 {
                recommendations.append(PatternRecommendation(
                    type: .recurring,
                    title: "Time to restock \(recurring.itemName)",
                    description: "Based on your purchase history, you typically buy this every \(Int(recurring.averageInterval)) days",
                    priority: .medium
                ))
            }
        }
        
        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
}