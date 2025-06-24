import Foundation
import Combine

public final class MockInsurancePolicyRepository: InsurancePolicyRepository {
    private var policies: [InsurancePolicy] = []
    private let policiesSubject = CurrentValueSubject<[InsurancePolicy], Never>([])
    
    public var insurancePoliciesPublisher: AnyPublisher<[InsurancePolicy], Never> {
        policiesSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Use comprehensive mock data from factory
        self.policies = MockDataService.generateInsurancePolicies()
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

