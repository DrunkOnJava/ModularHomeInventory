import Foundation

/// Service for calculating asset depreciation
/// Swift 5.9 - No Swift 6 features
public final class DepreciationService {
    private let itemRepository: any ItemRepository
    private let calendar = Calendar.current
    
    public init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    /// Generate depreciation report for all items
    public func generateDepreciationReport(
        method: DepreciationMethod = .categoryBased,
        includeCategories: [ItemCategory]? = nil,
        asOfDate: Date = Date()
    ) async throws -> DepreciationReport {
        let items = try await itemRepository.fetchAll()
        
        // Filter items that have purchase price and date
        let depreciableItems = items.filter { item in
            guard item.purchasePrice != nil && item.purchaseDate != nil else { return false }
            
            // Filter by categories if specified
            if let includeCategories = includeCategories {
                return includeCategories.contains(item.category)
            }
            
            return true
        }
        
        // Calculate depreciation for each item
        let depreciatingItems = depreciableItems.compactMap { item in
            calculateItemDepreciation(item: item, method: method, asOfDate: asOfDate)
        }
        
        // Calculate totals
        let totalOriginalValue = depreciatingItems.reduce(Decimal(0)) { $0 + $1.purchasePrice }
        let totalCurrentValue = depreciatingItems.reduce(Decimal(0)) { $0 + $1.currentValue }
        let totalDepreciation = totalOriginalValue - totalCurrentValue
        let depreciationPercentage = totalOriginalValue > 0 ? 
            NSDecimalNumber(decimal: totalDepreciation).doubleValue / NSDecimalNumber(decimal: totalOriginalValue).doubleValue * 100 : 0
        
        return DepreciationReport(
            generatedDate: asOfDate,
            items: depreciatingItems,
            totalOriginalValue: totalOriginalValue,
            totalCurrentValue: totalCurrentValue,
            totalDepreciation: totalDepreciation,
            depreciationPercentage: depreciationPercentage
        )
    }
    
    /// Calculate depreciation schedule for an item
    public func calculateDepreciationSchedule(
        item: Item,
        method: DepreciationMethod = .categoryBased,
        customLifespan: Int? = nil,
        customSalvageValue: Decimal? = nil
    ) -> DepreciationSchedule? {
        guard let purchasePrice = item.purchasePrice,
              let purchaseDate = item.purchaseDate else { return nil }
        
        let (lifespan, salvageValue) = getDepreciationParameters(
            for: item,
            method: method,
            customLifespan: customLifespan,
            customSalvageValue: customSalvageValue
        )
        
        // Items with 0 lifespan don't depreciate
        guard lifespan > 0 else {
            return DepreciationSchedule(
                itemId: item.id,
                method: method,
                purchasePrice: purchasePrice,
                salvageValue: purchasePrice,
                usefulLife: 0,
                annualDepreciation: []
            )
        }
        
        let annualDepreciation = calculateAnnualDepreciation(
            purchasePrice: purchasePrice,
            salvageValue: salvageValue,
            usefulLife: lifespan,
            method: method
        )
        
        return DepreciationSchedule(
            itemId: item.id,
            method: method,
            purchasePrice: purchasePrice,
            salvageValue: salvageValue,
            usefulLife: lifespan,
            annualDepreciation: annualDepreciation
        )
    }
    
    /// Calculate depreciation for items by category
    public func calculateDepreciationByCategory() async throws -> [ItemCategory: CategoryDepreciationSummary] {
        let report = try await generateDepreciationReport()
        
        var summaries: [ItemCategory: CategoryDepreciationSummary] = [:]
        
        for item in report.items {
            var summary = summaries[item.category] ?? CategoryDepreciationSummary(
                category: item.category,
                itemCount: 0,
                totalOriginalValue: 0,
                totalCurrentValue: 0,
                totalDepreciation: 0,
                averageDepreciationPercentage: 0
            )
            
            summary.itemCount += 1
            summary.totalOriginalValue += item.purchasePrice
            summary.totalCurrentValue += item.currentValue
            summary.totalDepreciation += item.depreciationAmount
            
            summaries[item.category] = summary
        }
        
        // Calculate average percentages
        for (category, var summary) in summaries {
            if summary.totalOriginalValue > 0 {
                summary.averageDepreciationPercentage = 
                    NSDecimalNumber(decimal: summary.totalDepreciation).doubleValue / 
                    NSDecimalNumber(decimal: summary.totalOriginalValue).doubleValue * 100
            }
            summaries[category] = summary
        }
        
        return summaries
    }
    
    // MARK: - Private Methods
    
    private func calculateItemDepreciation(
        item: Item,
        method: DepreciationMethod,
        asOfDate: Date
    ) -> DepreciatingItem? {
        guard let purchasePrice = item.purchasePrice,
              let purchaseDate = item.purchaseDate else { return nil }
        
        let ageInYears = calculateAge(from: purchaseDate, to: asOfDate)
        let (lifespan, salvageValue) = getDepreciationParameters(for: item, method: method)
        
        // Calculate current value
        let currentValue: Decimal
        let depreciationAmount: Decimal
        
        if lifespan == 0 || method == .custom {
            // No depreciation for certain categories
            currentValue = purchasePrice
            depreciationAmount = 0
        } else {
            let depreciationRate = calculateDepreciationRate(
                method: method,
                usefulLife: lifespan,
                currentAge: ageInYears
            )
            
            depreciationAmount = min(
                purchasePrice * Decimal(depreciationRate),
                purchasePrice - salvageValue
            )
            currentValue = max(purchasePrice - depreciationAmount, salvageValue)
        }
        
        let depreciationPercentage = purchasePrice > 0 ?
            NSDecimalNumber(decimal: depreciationAmount).doubleValue / 
            NSDecimalNumber(decimal: purchasePrice).doubleValue * 100 : 0
        
        return DepreciatingItem(
            itemId: item.id,
            itemName: item.name,
            category: item.category,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            currentValue: currentValue,
            depreciationAmount: depreciationAmount,
            depreciationPercentage: depreciationPercentage,
            ageInYears: ageInYears,
            depreciationMethod: method,
            estimatedLifespan: lifespan,
            salvageValue: salvageValue
        )
    }
    
    private func getDepreciationParameters(
        for item: Item,
        method: DepreciationMethod,
        customLifespan: Int? = nil,
        customSalvageValue: Decimal? = nil
    ) -> (lifespan: Int, salvageValue: Decimal) {
        guard let purchasePrice = item.purchasePrice else { return (0, 0) }
        
        if method == .categoryBased {
            if let rule = CategoryDepreciationRule.defaults[item.category] {
                let lifespan = customLifespan ?? rule.defaultLifespan
                let salvageValue = customSalvageValue ?? 
                    (purchasePrice * Decimal(rule.salvagePercentage))
                return (lifespan, salvageValue)
            }
        }
        
        // Default values if no category rule exists
        let defaultLifespan = customLifespan ?? 5
        let defaultSalvageValue = customSalvageValue ?? (purchasePrice * Decimal(0.1))
        return (defaultLifespan, defaultSalvageValue)
    }
    
    private func calculateAge(from purchaseDate: Date, to currentDate: Date) -> Double {
        let components = calendar.dateComponents([.day], from: purchaseDate, to: currentDate)
        return Double(components.day ?? 0) / 365.25
    }
    
    private func calculateDepreciationRate(
        method: DepreciationMethod,
        usefulLife: Int,
        currentAge: Double
    ) -> Double {
        guard usefulLife > 0 else { return 0 }
        
        switch method {
        case .straightLine:
            // Equal depreciation each year
            let annualRate = 1.0 / Double(usefulLife)
            return min(annualRate * currentAge, 1.0)
            
        case .decliningBalance:
            // Accelerated depreciation - 200% declining balance
            let rate = 2.0 / Double(usefulLife)
            var remainingValue = 1.0
            var totalDepreciation = 0.0
            
            for year in 0..<Int(currentAge) {
                let yearDepreciation = remainingValue * rate
                totalDepreciation += yearDepreciation
                remainingValue -= yearDepreciation
            }
            
            // Partial year
            let partialYear = currentAge - Double(Int(currentAge))
            if partialYear > 0 {
                totalDepreciation += remainingValue * rate * partialYear
            }
            
            return min(totalDepreciation, 0.9) // Max 90% depreciation
            
        case .categoryBased, .custom:
            // Use straight line as fallback
            let annualRate = 1.0 / Double(usefulLife)
            return min(annualRate * currentAge, 1.0)
        }
    }
    
    private func calculateAnnualDepreciation(
        purchasePrice: Decimal,
        salvageValue: Decimal,
        usefulLife: Int,
        method: DepreciationMethod
    ) -> [AnnualDepreciation] {
        guard usefulLife > 0 else { return [] }
        
        var annualDepreciation: [AnnualDepreciation] = []
        var bookValue = purchasePrice
        var accumulatedDepreciation = Decimal(0)
        
        for year in 1...usefulLife {
            let depreciationAmount: Decimal
            
            switch method {
            case .straightLine:
                depreciationAmount = (purchasePrice - salvageValue) / Decimal(usefulLife)
                
            case .decliningBalance:
                let rate = Decimal(2.0 / Double(usefulLife))
                depreciationAmount = min(
                    bookValue * rate,
                    bookValue - salvageValue
                )
                
            case .categoryBased, .custom:
                // Use straight line as default
                depreciationAmount = (purchasePrice - salvageValue) / Decimal(usefulLife)
            }
            
            bookValue -= depreciationAmount
            accumulatedDepreciation += depreciationAmount
            
            annualDepreciation.append(AnnualDepreciation(
                year: year,
                depreciationAmount: depreciationAmount,
                accumulatedDepreciation: accumulatedDepreciation,
                bookValue: max(bookValue, salvageValue)
            ))
            
            if bookValue <= salvageValue {
                break
            }
        }
        
        return annualDepreciation
    }
}

/// Summary of depreciation by category
public struct CategoryDepreciationSummary {
    public var category: ItemCategory
    public var itemCount: Int
    public var totalOriginalValue: Decimal
    public var totalCurrentValue: Decimal
    public var totalDepreciation: Decimal
    public var averageDepreciationPercentage: Double
    
    public init(
        category: ItemCategory,
        itemCount: Int,
        totalOriginalValue: Decimal,
        totalCurrentValue: Decimal,
        totalDepreciation: Decimal,
        averageDepreciationPercentage: Double
    ) {
        self.category = category
        self.itemCount = itemCount
        self.totalOriginalValue = totalOriginalValue
        self.totalCurrentValue = totalCurrentValue
        self.totalDepreciation = totalDepreciation
        self.averageDepreciationPercentage = averageDepreciationPercentage
    }
}