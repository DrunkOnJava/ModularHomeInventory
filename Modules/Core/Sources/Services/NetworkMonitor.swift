import Foundation
import Network
import Combine

/// Network connectivity monitoring service
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class NetworkMonitor: ObservableObject {
    
    // Singleton instance
    public static let shared = NetworkMonitor()
    
    // Published properties
    @Published public private(set) var isConnected = true
    @Published public private(set) var isExpensive = false
    @Published public private(set) var connectionType: ConnectionType = .unknown
    
    // Network path monitor
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.homeinventory.networkmonitor")
    
    public enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
        
        public var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wired: return "Wired"
            case .unknown: return "Unknown"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline Queue Manager

/// Manages operations that need to be performed when network becomes available
@MainActor
public final class OfflineQueueManager: ObservableObject {
    
    // Singleton instance
    public static let shared = OfflineQueueManager()
    
    // Published properties for UI
    @Published public var isSyncing = false
    @Published public var syncProgress: Double = 0.0
    @Published public var pendingOperations: [QueuedOperation] = []
    
    // Queue storage
    private var queuedOperations: [QueuedOperation] = [] {
        didSet {
            pendingOperations = queuedOperations
        }
    }
    private let queue = DispatchQueue(label: "com.homeinventory.offlinequeue", attributes: .concurrent)
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    // Persistence
    private var queueFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("offline_queue.json")
    }
    
    private init() {
        loadQueue()
        Task {
            await setupNetworkMonitoring()
        }
    }
    
    @MainActor
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .removeDuplicates()
            .filter { $0 } // Only when connected
            .sink { [weak self] _ in
                Task {
                    await self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Add an operation to the offline queue
    public func enqueue(_ operation: QueuedOperation) async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) { [weak self] in
                self?.queuedOperations.append(operation)
                self?.saveQueue()
                continuation.resume()
            }
        }
    }
    
    /// Process all queued operations
    public func processQueue() async {
        guard NetworkMonitor.shared.isConnected else { return }
        
        isSyncing = true
        syncProgress = 0.0
        
        let operations = queue.sync { queuedOperations }
        let total = Double(operations.count)
        var completed = 0.0
        
        for operation in operations {
            do {
                try await operation.execute()
                removeOperation(operation.id)
                completed += 1
                syncProgress = completed / total
            } catch {
                print("Failed to execute queued operation: \(error)")
                // Keep in queue for retry
            }
        }
        
        isSyncing = false
        syncProgress = 1.0
    }
    
    /// Sync pending operations (called from UI)
    public func syncPendingOperations() async {
        await processQueue()
    }
    
    /// Clear all pending operations
    public func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.queuedOperations.removeAll()
            self?.saveQueue()
        }
    }
    
    /// Remove a completed operation
    private func removeOperation(_ id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            self?.queuedOperations.removeAll { $0.id == id }
            self?.saveQueue()
        }
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(queuedOperations)
            try data.write(to: queueFileURL)
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    private func loadQueue() {
        guard fileManager.fileExists(atPath: queueFileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: queueFileURL)
            let decoder = JSONDecoder()
            queuedOperations = try decoder.decode([QueuedOperation].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
        }
    }
}

// MARK: - Queued Operation

/// Represents an operation that can be queued for offline execution
public struct QueuedOperation: Codable, Identifiable {
    public let id = UUID()
    public let type: OperationType
    public let timestamp: Date
    public let data: Data
    
    public enum OperationType: String, Codable {
        case createItem
        case updateItem
        case deleteItem
        case uploadPhoto
        case createReceipt
        case syncData
    }
    
    public init(type: OperationType, data: Encodable) throws {
        self.type = type
        self.timestamp = Date()
        let encoder = JSONEncoder()
        self.data = try encoder.encode(data)
    }
    
    /// Execute the queued operation
    public func execute() async throws {
        // This would be implemented by specific operation handlers
        print("Executing queued operation: \(type)")
    }
}

// MARK: - Offline Storage Manager

/// Manages local storage for offline data
public final class OfflineStorageManager {
    
    // Singleton instance
    public static let shared = OfflineStorageManager()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var offlineDataDirectory: URL {
        documentsDirectory.appendingPathComponent("offline_data")
    }
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: offlineDataDirectory.path) {
            try? fileManager.createDirectory(at: offlineDataDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// Save data for offline access
    public func save<T: Codable>(_ data: T, key: String) throws {
        let url = offlineDataDirectory.appendingPathComponent("\(key).json")
        let encoded = try encoder.encode(data)
        try encoded.write(to: url)
    }
    
    /// Load offline data
    public func load<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        let url = offlineDataDirectory.appendingPathComponent("\(key).json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    /// Delete offline data
    public func delete(key: String) throws {
        let url = offlineDataDirectory.appendingPathComponent("\(key).json")
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    /// Get size of offline data
    public func getOfflineDataSize() -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: offlineDataDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
    
    /// Clear all offline data
    public func clearAllOfflineData() throws {
        if fileManager.fileExists(atPath: offlineDataDirectory.path) {
            try fileManager.removeItem(at: offlineDataDirectory)
            createDirectoryIfNeeded()
        }
    }
}