import Foundation
import Combine

public final class MockInsurancePolicyRepository: InsurancePolicyRepository {
    private var policies: [InsurancePolicy] = []
    private let policiesSubject = CurrentValueSubject<[InsurancePolicy], Never>([])
    
    public var insurancePoliciesPublisher: AnyPublisher<[InsurancePolicy], Never> {
        policiesSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Add some preview data
        self.policies = [
            InsurancePolicy(
                policyNumber: "POL-12345",
                provider: "AllState",
                type: .homeowners,
                coverageAmount: 500000,
                deductible: 1000,
                premium: PremiumDetails(
                    amount: 1200,
                    frequency: .annual,
                    nextDueDate: Date().addingTimeInterval(60 * 24 * 60 * 60) // 60 days from now
                ),
                startDate: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
                endDate: Date().addingTimeInterval(365 * 24 * 60 * 60), // 1 year from now
                coverageDetails: "Comprehensive home insurance coverage",
                contactInfo: InsuranceContact(
                    claimsPhone: "1-800-CLAIMS",
                    claimsEmail: "claims@allstate.com"
                )
            ),
            InsurancePolicy(
                policyNumber: "ELE-98765",
                provider: "Geico",
                type: .electronics,
                coverageAmount: 10000,
                deductible: 250,
                premium: PremiumDetails(
                    amount: 35,
                    frequency: .monthly,
                    nextDueDate: Date().addingTimeInterval(15 * 24 * 60 * 60) // 15 days from now
                ),
                startDate: Date().addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
                endDate: Date().addingTimeInterval(185 * 24 * 60 * 60), // 6 months from now
                coverageDetails: "Electronics protection plan",
                contactInfo: InsuranceContact(
                    claimsPhone: "1-800-GEICO",
                    claimsEmail: "claims@geico.com"
                ),
                claims: [
                    InsuranceClaim(
                        claimNumber: "CLM-001",
                        dateOfLoss: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                        description: "MacBook Pro water damage",
                        claimAmount: 2500,
                        paidAmount: 2250
                    )
                ]
            ),
            InsurancePolicy(
                policyNumber: "VAL-55555",
                provider: "Chubb",
                type: .valuable,
                coverageAmount: 75000,
                deductible: 500,
                premium: PremiumDetails(
                    amount: 600,
                    frequency: .quarterly,
                    nextDueDate: Date().addingTimeInterval(45 * 24 * 60 * 60) // 45 days from now
                ),
                startDate: Date().addingTimeInterval(-90 * 24 * 60 * 60), // 3 months ago
                endDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // Expiring in 30 days
                coverageDetails: "High-value items coverage",
                contactInfo: InsuranceContact(
                    agentName: "John Doe",
                    agentPhone: "(555) 123-4567",
                    claimsPhone: "1-800-CHUBB"
                )
            )
        ]
        policiesSubject.send(policies)
    }
    
    public func fetchAll() async throws -> [InsurancePolicy] {
        return policies
    }
    
    public func fetch(id: UUID) async throws -> InsurancePolicy? {
        return policies.first { $0.id == id }
    }
    
    public func save(_ policy: InsurancePolicy) async throws {
        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            policies[index] = policy
        } else {
            policies.append(policy)
        }
        policiesSubject.send(policies)
    }
    
    public func delete(_ policy: InsurancePolicy) async throws {
        policies.removeAll { $0.id == policy.id }
        policiesSubject.send(policies)
    }
    
    public func delete(id: UUID) async throws {
        policies.removeAll { $0.id == id }
        policiesSubject.send(policies)
    }
    
    public func fetchPolicies(covering itemId: UUID) async throws -> [InsurancePolicy] {
        return policies.filter { $0.itemIds.contains(itemId) }
    }
    
    public func fetchByType(_ type: InsuranceType) async throws -> [InsurancePolicy] {
        return policies.filter { $0.type == type }
    }
    
    public func fetchExpiring(within days: Int) async throws -> [InsurancePolicy] {
        let cutoffDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        return policies.filter { policy in
            policy.isActive && policy.endDate <= cutoffDate
        }
    }
    
    public func fetchRenewalDue() async throws -> [InsurancePolicy] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return policies.filter { policy in
            policy.isActive && policy.endDate <= thirtyDaysFromNow
        }
    }
    
    public func fetchActivePolicies() async throws -> [InsurancePolicy] {
        return policies.filter { $0.isActive }
    }
    
    public func addClaim(_ claim: InsuranceClaim, to policyId: UUID) async throws {
        guard let index = policies.firstIndex(where: { $0.id == policyId }) else {
            throw RepositoryError.notFound
        }
        policies[index].claims.append(claim)
    }
    
    public func updateClaim(_ claim: InsuranceClaim, in policyId: UUID) async throws {
        guard let policyIndex = policies.firstIndex(where: { $0.id == policyId }),
              let claimIndex = policies[policyIndex].claims.firstIndex(where: { $0.id == claim.id }) else {
            throw RepositoryError.notFound
        }
        policies[policyIndex].claims[claimIndex] = claim
    }
    
    public func search(query: String) async throws -> [InsurancePolicy] {
        let lowercasedQuery = query.lowercased()
        return policies.filter { policy in
            policy.provider.lowercased().contains(lowercasedQuery) ||
            policy.policyNumber.lowercased().contains(lowercasedQuery) ||
            policy.type.displayName.lowercased().contains(lowercasedQuery)
        }
    }
    
    public func totalCoverage(for itemId: UUID) async throws -> Decimal {
        return policies
            .filter { $0.itemIds.contains(itemId) && $0.isActive }
            .reduce(0) { $0 + $1.coverageAmount }
    }
    
    public func totalAnnualPremiums() async throws -> Decimal {
        return policies
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.premium.annualAmount }
    }
}

