import Foundation
import Combine

/// Protocol for managing service records
public protocol ServiceRecordRepository: AnyObject, Sendable {
    /// Fetch all service records
    func fetchAll() async throws -> [ServiceRecord]
    
    /// Fetch a specific service record by ID
    func fetch(id: UUID) async throws -> ServiceRecord?
    
    /// Fetch service records for a specific item
    func fetchRecords(for itemId: UUID) async throws -> [ServiceRecord]
    
    /// Fetch service records by type
    func fetchByType(_ type: ServiceType) async throws -> [ServiceRecord]
    
    /// Fetch service records within a date range
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [ServiceRecord]
    
    /// Fetch upcoming service records
    func fetchUpcoming(within days: Int) async throws -> [ServiceRecord]
    
    /// Save a service record
    func save(_ record: ServiceRecord) async throws
    
    /// Delete a service record
    func delete(_ record: ServiceRecord) async throws
    
    /// Delete a service record by ID
    func delete(id: UUID) async throws
    
    /// Search service records
    func search(query: String) async throws -> [ServiceRecord]
    
    /// Publisher for service record changes
    var serviceRecordsPublisher: AnyPublisher<[ServiceRecord], Never> { get }
}