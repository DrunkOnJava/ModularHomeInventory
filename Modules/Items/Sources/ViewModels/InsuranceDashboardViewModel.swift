import Foundation
import SwiftUI
import Core
import Combine

@MainActor
final class InsuranceDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var policies: [InsurancePolicy] = []
    @Published var items: [Item] = []
    @Published var coverageAnalysis = CoverageAnalysis(
        totalItemValue: 0,
        coveredValue: 0,
        uncoveredValue: 0,
        coveragePercentage: 0,
        totalItems: 0,
        coveredItems: 0,
        uncoveredItems: 0,
        totalCoverageLimit: 0,
        categoryBreakdown: [:],
        recommendations: [],
        highValueUncoveredItems: []
    )
    @Published var premiumAnalysis = PremiumAnalysis(
        totalAnnualPremium: 0,
        monthlyAverage: 0,
        premiumByType: [:],
        activePolicyCount: 0
    )
    @Published var claimAnalysis = ClaimAnalysis(
        totalClaims: 0,
        totalClaimAmount: 0,
        totalPaidAmount: 0,
        totalDeductibles: 0,
        averageClaimAmount: 0,
        claimsByStatus: [:],
        approvalRate: 0
    )
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Properties
    let itemRepository: any ItemRepository
    let insuranceRepository: InsurancePolicyRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var activePolicies: [InsurancePolicy] {
        policies.filter { $0.status == .active || $0.status == .renewalDue }
    }
    
    var expiredPolicies: [InsurancePolicy] {
        policies.filter { $0.status == .expired }
    }
    
    var recommendations: [CoverageRecommendation] {
        coverageAnalysis.recommendations
    }
    
    var categoryBreakdown: [(category: ItemCategory, coveredValue: Decimal, uncoveredValue: Decimal)] {
        coverageAnalysis.categoryBreakdown.map { category, coverage in
            (category: category, coveredValue: coverage.coveredValue, uncoveredValue: coverage.uncoveredValue)
        }.sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    // MARK: - Initialization
    init(
        itemRepository: any ItemRepository,
        insuranceRepository: InsurancePolicyRepository
    ) {
        self.itemRepository = itemRepository
        self.insuranceRepository = insuranceRepository
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Subscribe to policy changes
        insuranceRepository.insurancePoliciesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] policies in
                self?.policies = policies
                Task {
                    await self?.analyzeData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load items and policies in parallel
            async let itemsTask = itemRepository.fetchAll()
            async let policiesTask = insuranceRepository.fetchAll()
            
            let (loadedItems, loadedPolicies) = try await (itemsTask, policiesTask)
            
            items = loadedItems
            policies = loadedPolicies
            
            await analyzeData()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Analysis
    private func analyzeData() async {
        // Perform coverage analysis
        coverageAnalysis = InsuranceCoverageCalculator.analyzeCoverage(
            items: items,
            policies: policies
        )
        
        // Perform premium analysis
        premiumAnalysis = InsuranceCoverageCalculator.calculateAnnualPremiums(
            policies: policies
        )
        
        // Perform claim analysis
        claimAnalysis = InsuranceCoverageCalculator.analyzeClaimsHistory(
            policies: policies
        )
    }
    
    // MARK: - Actions
    func addPolicy(_ policy: InsurancePolicy) async {
        do {
            try await insuranceRepository.save(policy)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    func updatePolicy(_ policy: InsurancePolicy) async {
        do {
            var updatedPolicy = policy
            updatedPolicy.updatedAt = Date()
            try await insuranceRepository.save(updatedPolicy)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    func deletePolicy(_ policy: InsurancePolicy) async {
        do {
            try await insuranceRepository.delete(policy)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    func addClaim(_ claim: InsuranceClaim, to policy: InsurancePolicy) async {
        do {
            try await insuranceRepository.addClaim(claim, to: policy.id)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Statistics
    func policiesByType() -> [(InsuranceType, Int)] {
        let grouped = Dictionary(grouping: activePolicies) { $0.type }
        return InsuranceType.allCases.compactMap { type in
            let count = grouped[type]?.count ?? 0
            return count > 0 ? (type, count) : nil
        }
    }
    
    func upcomingRenewals(within days: Int = 30) -> [InsurancePolicy] {
        let cutoffDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        return policies.filter { policy in
            policy.status == .renewalDue ||
            (policy.premium.nextDueDate != nil && policy.premium.nextDueDate! <= cutoffDate)
        }.sorted { ($0.premium.nextDueDate ?? $0.endDate) < ($1.premium.nextDueDate ?? $1.endDate) }
    }
    
    func itemsCoveredByPolicy(_ policy: InsurancePolicy) -> [Item] {
        items.filter { policy.itemIds.contains($0.id) }
    }
    
    func policiesCoveringItem(_ item: Item) -> [InsurancePolicy] {
        policies.filter { $0.itemIds.contains(item.id) }
    }
}