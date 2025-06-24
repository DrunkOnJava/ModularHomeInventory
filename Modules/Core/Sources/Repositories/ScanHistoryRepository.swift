import Foundation

/// Protocol for scan history repository operations
/// Swift 5.9 - No Swift 6 features
public protocol ScanHistoryRepository: Sendable {
    func fetchAll() async throws -> [ScanHistoryEntry]
    func fetchRecent(limit: Int) async throws -> [ScanHistoryEntry]
    func fetch(id: UUID) async throws -> ScanHistoryEntry?
    func save(_ entry: ScanHistoryEntry) async throws
    func delete(_ entry: ScanHistoryEntry) async throws
    func deleteAll() async throws
    func fetchByBarcode(_ barcode: String) async throws -> [ScanHistoryEntry]
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [ScanHistoryEntry]
}

/// Default implementation of scan history repository
public actor DefaultScanHistoryRepository: ScanHistoryRepository {
    private var entries: [ScanHistoryEntry] = []
    
    public init() {}
    
    public func fetchAll() async throws -> [ScanHistoryEntry] {
        // Return entries sorted by scan date (newest first)
        entries.sorted { $0.scanDate > $1.scanDate }
    }
    
    public func fetchRecent(limit: Int) async throws -> [ScanHistoryEntry] {
        let sorted = entries.sorted { $0.scanDate > $1.scanDate }
        return Array(sorted.prefix(limit))
    }
    
    public func fetch(id: UUID) async throws -> ScanHistoryEntry? {
        entries.first { $0.id == id }
    }
    
    public func save(_ entry: ScanHistoryEntry) async throws {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        
        // Keep only the last 100 entries to prevent unbounded growth
        if entries.count > 100 {
            entries = entries.sorted { $0.scanDate > $1.scanDate }
            entries = Array(entries.prefix(100))
        }
    }
    
    public func delete(_ entry: ScanHistoryEntry) async throws {
        entries.removeAll { $0.id == entry.id }
    }
    
    public func deleteAll() async throws {
        entries.removeAll()
    }
    
    public func fetchByBarcode(_ barcode: String) async throws -> [ScanHistoryEntry] {
        entries.filter { $0.barcode == barcode }
            .sorted { $0.scanDate > $1.scanDate }
    }
    
    public func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [ScanHistoryEntry] {
        entries.filter { entry in
            entry.scanDate >= startDate && entry.scanDate <= endDate
        }.sorted { $0.scanDate > $1.scanDate }
    }
}