import Foundation

/// Service for calculating insurance coverage and recommendations
public final class InsuranceCoverageCalculator {
    
    // MARK: - Coverage Analysis
    
    /// Analyze coverage for all items
    public static func analyzeCoverage(
        items: [Item],
        policies: [InsurancePolicy]
    ) -> CoverageAnalysis {
        let totalItemValue = items.reduce(Decimal.zero) { sum, item in
            sum + (item.value ?? 0) * Decimal(item.quantity)
        }
        
        let coveredItems = Set(policies.flatMap { $0.itemIds })
        let coveredItemsArray = items.filter { coveredItems.contains($0.id) }
        let uncoveredItems = items.filter { !coveredItems.contains($0.id) }
        
        let coveredValue = coveredItemsArray.reduce(Decimal.zero) { sum, item in
            sum + (item.value ?? 0) * Decimal(item.quantity)
        }
        
        let uncoveredValue = totalItemValue - coveredValue
        
        // Calculate coverage by category
        var categoryAnalysis: [ItemCategory: CategoryCoverage] = [:]
        for category in ItemCategory.allCases {
            let categoryItems = items.filter { $0.category == category }
            let categoryValue = categoryItems.reduce(Decimal.zero) { sum, item in
                sum + (item.value ?? 0) * Decimal(item.quantity)
            }
            
            let categoryCoveredItems = categoryItems.filter { coveredItems.contains($0.id) }
            let categoryCoveredValue = categoryCoveredItems.reduce(Decimal.zero) { sum, item in
                sum + (item.value ?? 0) * Decimal(item.quantity)
            }
            
            if categoryValue > 0 {
                categoryAnalysis[category] = CategoryCoverage(
                    category: category,
                    totalValue: categoryValue,
                    coveredValue: categoryCoveredValue,
                    itemCount: categoryItems.count,
                    coveredItemCount: categoryCoveredItems.count
                )
            }
        }
        
        // Calculate total coverage limits
        let totalCoverageLimit = policies.reduce(Decimal.zero) { $0 + $1.coverageAmount }
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            items: items,
            policies: policies,
            coveredItems: coveredItems,
            uncoveredItems: uncoveredItems
        )
        
        return CoverageAnalysis(
            totalItemValue: totalItemValue,
            coveredValue: coveredValue,
            uncoveredValue: uncoveredValue,
            coveragePercentage: totalItemValue > 0 ? Double(truncating: (coveredValue / totalItemValue) as NSNumber) : 0,
            totalItems: items.count,
            coveredItems: coveredItems.count,
            uncoveredItems: uncoveredItems.count,
            totalCoverageLimit: totalCoverageLimit,
            categoryBreakdown: categoryAnalysis,
            recommendations: recommendations,
            highValueUncoveredItems: uncoveredItems
                .filter { ($0.value ?? 0) > 1000 }
                .sorted { ($0.value ?? 0) > ($1.value ?? 0) }
                .prefix(10)
                .map { $0 }
        )
    }
    
    // MARK: - Premium Analysis
    
    /// Calculate total annual premiums
    public static func calculateAnnualPremiums(policies: [InsurancePolicy]) -> PremiumAnalysis {
        let activePolicies = policies.filter { $0.isActive }
        
        let totalAnnualPremium = activePolicies.reduce(Decimal.zero) { sum, policy in
            sum + policy.premium.annualAmount
        }
        
        var premiumByType: [InsuranceType: Decimal] = [:]
        for policy in activePolicies {
            premiumByType[policy.type, default: 0] += policy.premium.annualAmount
        }
        
        let monthlyAverage = totalAnnualPremium / 12
        
        return PremiumAnalysis(
            totalAnnualPremium: totalAnnualPremium,
            monthlyAverage: monthlyAverage,
            premiumByType: premiumByType,
            activePolicyCount: activePolicies.count
        )
    }
    
    // MARK: - Claim Analysis
    
    /// Analyze insurance claims
    public static func analyzeClaimsHistory(policies: [InsurancePolicy]) -> ClaimAnalysis {
        let allClaims = policies.flatMap { $0.claims }
        
        let totalClaimAmount = allClaims.reduce(Decimal.zero) { $0 + $1.claimAmount }
        let totalPaidAmount = allClaims.reduce(Decimal.zero) { $0 + ($1.paidAmount ?? 0) }
        let totalDeductibles = allClaims.reduce(Decimal.zero) { $0 + ($1.deductibleApplied ?? 0) }
        
        var claimsByStatus: [ClaimStatus: Int] = [:]
        for claim in allClaims {
            claimsByStatus[claim.status, default: 0] += 1
        }
        
        let approvalRate = allClaims.isEmpty ? 0 : Double(claimsByStatus[.approved, default: 0] + claimsByStatus[.paid, default: 0]) / Double(allClaims.count)
        
        return ClaimAnalysis(
            totalClaims: allClaims.count,
            totalClaimAmount: totalClaimAmount,
            totalPaidAmount: totalPaidAmount,
            totalDeductibles: totalDeductibles,
            averageClaimAmount: allClaims.isEmpty ? 0 : totalClaimAmount / Decimal(allClaims.count),
            claimsByStatus: claimsByStatus,
            approvalRate: approvalRate
        )
    }
    
    // MARK: - Recommendations
    
    private static func generateRecommendations(
        items: [Item],
        policies: [InsurancePolicy],
        coveredItems: Set<UUID>,
        uncoveredItems: [Item]
    ) -> [CoverageRecommendation] {
        var recommendations: [CoverageRecommendation] = []
        
        // Check for high-value uncovered items
        let highValueUncovered = uncoveredItems.filter { ($0.value ?? 0) > 1000 }
        if !highValueUncovered.isEmpty {
            recommendations.append(CoverageRecommendation(
                type: .addCoverage,
                priority: .high,
                title: "High-Value Items Need Coverage",
                description: "\(highValueUncovered.count) items worth over $1,000 are not covered by insurance",
                estimatedSavings: nil,
                affectedItems: Array(highValueUncovered.prefix(5))
            ))
        }
        
        // Check for underinsured categories
        for category in ItemCategory.allCases {
            let categoryItems = items.filter { $0.category == category }
            if categoryItems.isEmpty { continue }
            
            let categoryValue = categoryItems.reduce(Decimal.zero) { sum, item in
                sum + (item.value ?? 0) * Decimal(item.quantity)
            }
            
            let categoryCoveredItems = categoryItems.filter { coveredItems.contains($0.id) }
            let coverageRatio = Double(categoryCoveredItems.count) / Double(categoryItems.count)
            
            if coverageRatio < 0.5 && categoryValue > 500 {
                recommendations.append(CoverageRecommendation(
                    type: .increaseCoverage,
                    priority: .medium,
                    title: "Low Coverage for \(category.displayName)",
                    description: "Only \(Int(coverageRatio * 100))% of \(category.displayName.lowercased()) items are covered",
                    estimatedSavings: nil,
                    affectedItems: Array(categoryItems.prefix(3))
                ))
            }
        }
        
        // Check for duplicate coverage
        var itemCoverageCount: [UUID: Int] = [:]
        for policy in policies {
            for itemId in policy.itemIds {
                itemCoverageCount[itemId, default: 0] += 1
            }
        }
        
        let duplicateCoverageItems = itemCoverageCount.filter { $0.value > 1 }
        if !duplicateCoverageItems.isEmpty {
            let duplicateItems = items.filter { duplicateCoverageItems.keys.contains($0.id) }
            let potentialSavings = policies
                .filter { policy in
                    policy.itemIds.contains { duplicateCoverageItems.keys.contains($0) }
                }
                .reduce(Decimal.zero) { $0 + $1.premium.annualAmount * 0.3 } // Estimate 30% savings
            
            recommendations.append(CoverageRecommendation(
                type: .consolidate,
                priority: .medium,
                title: "Duplicate Coverage Detected",
                description: "\(duplicateCoverageItems.count) items are covered by multiple policies",
                estimatedSavings: potentialSavings,
                affectedItems: Array(duplicateItems.prefix(3))
            ))
        }
        
        // Check for expired policies
        let expiredPolicies = policies.filter { $0.status == .expired }
        if !expiredPolicies.isEmpty {
            let expiredItemIds = Set(expiredPolicies.flatMap { $0.itemIds })
            let expiredItems = items.filter { expiredItemIds.contains($0.id) }
            
            recommendations.append(CoverageRecommendation(
                type: .renew,
                priority: .high,
                title: "Expired Policies",
                description: "\(expiredPolicies.count) policies have expired, leaving \(expiredItems.count) items uncovered",
                estimatedSavings: nil,
                affectedItems: Array(expiredItems.prefix(5))
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Analysis Models

public struct CoverageAnalysis {
    public let totalItemValue: Decimal
    public let coveredValue: Decimal
    public let uncoveredValue: Decimal
    public let coveragePercentage: Double
    public let totalItems: Int
    public let coveredItems: Int
    public let uncoveredItems: Int
    public let totalCoverageLimit: Decimal
    public let categoryBreakdown: [ItemCategory: CategoryCoverage]
    public let recommendations: [CoverageRecommendation]
    public let highValueUncoveredItems: [Item]
}

public struct CategoryCoverage {
    public let category: ItemCategory
    public let totalValue: Decimal
    public let coveredValue: Decimal
    public let itemCount: Int
    public let coveredItemCount: Int
    
    public var coveragePercentage: Double {
        totalValue > 0 ? Double(truncating: (coveredValue / totalValue) as NSNumber) : 0
    }
    
    public var uncoveredValue: Decimal {
        totalValue - coveredValue
    }
}

public struct PremiumAnalysis {
    public let totalAnnualPremium: Decimal
    public let monthlyAverage: Decimal
    public let premiumByType: [InsuranceType: Decimal]
    public let activePolicyCount: Int
}

public struct ClaimAnalysis {
    public let totalClaims: Int
    public let totalClaimAmount: Decimal
    public let totalPaidAmount: Decimal
    public let totalDeductibles: Decimal
    public let averageClaimAmount: Decimal
    public let claimsByStatus: [ClaimStatus: Int]
    public let approvalRate: Double
}

public struct CoverageRecommendation {
    public let type: InsuranceRecommendationType
    public let priority: InsuranceRecommendationPriority
    public let title: String
    public let description: String
    public let estimatedSavings: Decimal?
    public let affectedItems: [Item]
}

public enum InsuranceRecommendationType: String {
    case addCoverage = "add_coverage"
    case increaseCoverage = "increase_coverage"
    case consolidate = "consolidate"
    case renew = "renew"
    case review = "review"
}

public enum InsuranceRecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
}