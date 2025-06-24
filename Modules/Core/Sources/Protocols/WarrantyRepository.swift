import Foundation
import Combine

/// Repository protocol for managing warranties
/// Swift 5.9 - No Swift 6 features
public protocol WarrantyRepository: Repository {
    /// Fetch all warranties
    func fetchAll() async throws -> [Warranty]
    
    /// Fetch warranty by ID
    func fetch(by id: UUID) async throws -> Warranty?
    
    /// Fetch warranties for a specific item
    func fetchWarranties(for itemId: UUID) async throws -> [Warranty]
    
    /// Fetch expiring warranties within specified days
    func fetchExpiring(within days: Int) async throws -> [Warranty]
    
    /// Fetch expired warranties
    func fetchExpired() async throws -> [Warranty]
    
    /// Save warranty
    func save(_ warranty: Warranty) async throws
    
    /// Delete warranty
    func delete(_ warranty: Warranty) async throws
    
    /// Publisher for warranty changes
    var warrantiesPublisher: AnyPublisher<[Warranty], Never> { get }
}

// MARK: - Default implementations

public extension WarrantyRepository {
    func fetchExpiring(within days: Int) async throws -> [Warranty] {
        let allWarranties = try await fetchAll()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return allWarranties.filter { warranty in
            warranty.endDate > Date() && warranty.endDate <= futureDate
        }
    }
    
    func fetchExpired() async throws -> [Warranty] {
        let allWarranties = try await fetchAll()
        return allWarranties.filter { $0.endDate < Date() }
    }
}