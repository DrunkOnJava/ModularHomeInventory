import Foundation

/// Model for queued offline scans
/// Swift 5.9 - No Swift 6 features
public struct OfflineScanQueueEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let barcode: String
    public let scanDate: Date
    public var retryCount: Int
    public var lastRetryDate: Date?
    public var status: QueueStatus
    public var errorMessage: String?
    
    public enum QueueStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
    
    public init(
        id: UUID = UUID(),
        barcode: String,
        scanDate: Date = Date(),
        retryCount: Int = 0,
        lastRetryDate: Date? = nil,
        status: QueueStatus = .pending,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.scanDate = scanDate
        self.retryCount = retryCount
        self.lastRetryDate = lastRetryDate
        self.status = status
        self.errorMessage = errorMessage
    }
}

// MARK: - Offline Scan Queue Repository Protocol
public protocol OfflineScanQueueRepository: Repository where Entity == OfflineScanQueueEntry {
    func fetchPending() async throws -> [OfflineScanQueueEntry]
    func fetchByStatus(_ status: OfflineScanQueueEntry.QueueStatus) async throws -> [OfflineScanQueueEntry]
    func updateStatus(id: UUID, status: OfflineScanQueueEntry.QueueStatus) async throws
    func incrementRetryCount(id: UUID) async throws
    func clearCompleted() async throws
}