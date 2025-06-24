import Foundation
import Combine

public final class MockServiceRecordRepository: ServiceRecordRepository {
    private var serviceRecords: [ServiceRecord] = []
    private let serviceRecordsSubject = CurrentValueSubject<[ServiceRecord], Never>([])
    
    public var serviceRecordsPublisher: AnyPublisher<[ServiceRecord], Never> {
        serviceRecordsSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Use comprehensive mock data from factory
        self.serviceRecords = MockDataService.generateServiceRecords()
        serviceRecordsSubject.send(serviceRecords)
    }
    
    public func fetchAll() async throws -> [ServiceRecord] {
        return serviceRecords
    }
    
    public func fetch(id: UUID) async throws -> ServiceRecord? {
        return serviceRecords.first { $0.id == id }
    }
    
    public func fetchRecords(for itemId: UUID) async throws -> [ServiceRecord] {
        return serviceRecords.filter { $0.itemId == itemId }
    }
    
    public func fetchByType(_ type: ServiceType) async throws -> [ServiceRecord] {
        return serviceRecords.filter { $0.type == type }
    }
    
    public func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [ServiceRecord] {
        return serviceRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }
    
    public func fetchUpcoming(within days: Int) async throws -> [ServiceRecord] {
        let cutoffDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        return serviceRecords.filter { record in
            if let nextServiceDate = record.nextServiceDate {
                return nextServiceDate <= cutoffDate && nextServiceDate >= Date()
            }
            return false
        }
    }
    
    public func save(_ record: ServiceRecord) async throws {
        if let index = serviceRecords.firstIndex(where: { $0.id == record.id }) {
            serviceRecords[index] = record
        } else {
            serviceRecords.append(record)
        }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    public func delete(_ record: ServiceRecord) async throws {
        serviceRecords.removeAll { $0.id == record.id }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    public func delete(id: UUID) async throws {
        serviceRecords.removeAll { $0.id == id }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    public func search(query: String) async throws -> [ServiceRecord] {
        let lowercasedQuery = query.lowercased()
        return serviceRecords.filter { record in
            record.provider.lowercased().contains(lowercasedQuery) ||
            record.description.lowercased().contains(lowercasedQuery) ||
            (record.technicianName?.lowercased().contains(lowercasedQuery) ?? false) ||
            (record.serviceOrderNumber?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
}