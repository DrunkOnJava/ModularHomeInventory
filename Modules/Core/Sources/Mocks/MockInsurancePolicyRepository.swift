import Foundation

public class MockInsurancePolicyRepository: InsurancePolicyRepository {
    private var policies: [InsurancePolicy] = []
    
    public init() {
        // Add some preview data
        self.policies = [
            InsurancePolicy(
                provider: "AllState",
                policyNumber: "POL-12345",
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
                status: .active,
                itemIds: [],
                contactInfo: ContactInfo(
                    phone: "1-800-ALLSTATE",
                    email: "claims@allstate.com",
                    claimsPhone: "1-800-CLAIMS",
                    claimsEmail: "claims@allstate.com"
                )
            )
        ]
    }
    
    public func fetchAll() async throws -> [InsurancePolicy] {
        return policies
    }
    
    public func fetch(by id: UUID) async throws -> InsurancePolicy? {
        return policies.first { $0.id == id }
    }
    
    public func save(_ policy: InsurancePolicy) async throws {
        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            policies[index] = policy
        } else {
            policies.append(policy)
        }
    }
    
    public func delete(_ policy: InsurancePolicy) async throws {
        policies.removeAll { $0.id == policy.id }
    }
    
    public func fetchByStatus(_ status: PolicyStatus) async throws -> [InsurancePolicy] {
        return policies.filter { $0.status == status }
    }
    
    public func fetchByItem(_ itemId: UUID) async throws -> [InsurancePolicy] {
        return policies.filter { $0.itemIds.contains(itemId) }
    }
    
    public func fetchExpiringPolicies(within days: Int) async throws -> [InsurancePolicy] {
        let cutoffDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        return policies.filter { policy in
            policy.status == .active && policy.endDate <= cutoffDate
        }
    }
    
    public func fetchActivePolicies() async throws -> [InsurancePolicy] {
        return policies.filter { $0.status == .active }
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
    
    public func deleteClaim(_ claimId: UUID, from policyId: UUID) async throws {
        guard let policyIndex = policies.firstIndex(where: { $0.id == policyId }) else {
            throw RepositoryError.notFound
        }
        policies[policyIndex].claims.removeAll { $0.id == claimId }
    }
}

enum RepositoryError: Error {
    case notFound
}