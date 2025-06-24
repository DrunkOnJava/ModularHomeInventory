import Foundation
import Combine

/// Protocol for managing repair records
public protocol RepairRecordRepository: AnyObject, Sendable {
    /// Fetch all repair records
    func fetchAll() async throws -> [RepairRecord]
    
    /// Fetch a specific repair record by ID
    func fetch(id: UUID) async throws -> RepairRecord?
    
    /// Fetch repair records for a specific item
    func fetchRecords(for itemId: UUID) async throws -> [RepairRecord]
    
    /// Fetch repair records by status
    func fetchByStatus(_ status: RepairStatus) async throws -> [RepairRecord]
    
    /// Fetch active repairs (in progress or awaiting parts)
    func fetchActiveRepairs() async throws -> [RepairRecord]
    
    /// Fetch repairs within a date range
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [RepairRecord]
    
    /// Fetch repairs by provider
    func fetchByProvider(_ provider: String) async throws -> [RepairRecord]
    
    /// Save a repair record
    func save(_ record: RepairRecord) async throws
    
    /// Delete a repair record
    func delete(_ record: RepairRecord) async throws
    
    /// Delete a repair record by ID
    func delete(id: UUID) async throws
    
    /// Search repair records
    func search(query: String) async throws -> [RepairRecord]
    
    /// Calculate total repair costs for an item
    func totalRepairCosts(for itemId: UUID) async throws -> Decimal
    
    /// Publisher for repair record changes
    var repairRecordsPublisher: AnyPublisher<[RepairRecord], Never> { get }
}