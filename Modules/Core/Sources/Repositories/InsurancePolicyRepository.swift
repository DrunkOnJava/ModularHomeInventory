import Foundation
import Combine

/// Protocol for managing insurance policies
public protocol InsurancePolicyRepository: AnyObject, Sendable {
    /// Fetch all insurance policies
    func fetchAll() async throws -> [InsurancePolicy]
    
    /// Fetch a specific insurance policy by ID
    func fetch(id: UUID) async throws -> InsurancePolicy?
    
    /// Fetch policies covering a specific item
    func fetchPolicies(covering itemId: UUID) async throws -> [InsurancePolicy]
    
    /// Fetch active policies
    func fetchActivePolicies() async throws -> [InsurancePolicy]
    
    /// Fetch policies by type
    func fetchByType(_ type: InsuranceType) async throws -> [InsurancePolicy]
    
    /// Fetch policies expiring within specified days
    func fetchExpiring(within days: Int) async throws -> [InsurancePolicy]
    
    /// Fetch policies with renewal due
    func fetchRenewalDue() async throws -> [InsurancePolicy]
    
    /// Save an insurance policy
    func save(_ policy: InsurancePolicy) async throws
    
    /// Delete an insurance policy
    func delete(_ policy: InsurancePolicy) async throws
    
    /// Delete an insurance policy by ID
    func delete(id: UUID) async throws
    
    /// Add a claim to a policy
    func addClaim(_ claim: InsuranceClaim, to policyId: UUID) async throws
    
    /// Update a claim
    func updateClaim(_ claim: InsuranceClaim, in policyId: UUID) async throws
    
    /// Search insurance policies
    func search(query: String) async throws -> [InsurancePolicy]
    
    /// Calculate total coverage amount for an item
    func totalCoverage(for itemId: UUID) async throws -> Decimal
    
    /// Calculate total annual premiums
    func totalAnnualPremiums() async throws -> Decimal
    
    /// Publisher for insurance policy changes
    var insurancePoliciesPublisher: AnyPublisher<[InsurancePolicy], Never> { get }
}