import Foundation
import Core
import Combine

/// Service for managing offline scan queue
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class OfflineScanService: ObservableObject {
    @Published public private(set) var pendingScans: [OfflineScanQueueEntry] = []
    @Published public private(set) var isProcessing: Bool = false
    
    private let offlineScanQueueRepository: any OfflineScanQueueRepository
    private let barcodeLookupService: BarcodeLookupService
    private let itemRepository: any ItemRepository
    private let networkMonitor: NetworkMonitor
    
    private var cancellables = Set<AnyCancellable>()
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 30 // 30 seconds between retries
    
    public init(
        offlineScanQueueRepository: any OfflineScanQueueRepository,
        barcodeLookupService: BarcodeLookupService,
        itemRepository: any ItemRepository,
        networkMonitor: NetworkMonitor
    ) {
        self.offlineScanQueueRepository = offlineScanQueueRepository
        self.barcodeLookupService = barcodeLookupService
        self.itemRepository = itemRepository
        self.networkMonitor = networkMonitor
        
        setupNetworkMonitoring()
        Task {
            await loadPendingScans()
        }
    }
    
    // MARK: - Public Methods
    
    /// Queue a scan for offline processing
    public func queueScan(barcode: String) async throws {
        let entry = OfflineScanQueueEntry(barcode: barcode)
        try await offlineScanQueueRepository.save(entry)
        await loadPendingScans()
        
        // Try to process immediately if online
        if networkMonitor.isConnected {
            await processQueue()
        }
    }
    
    /// Manually trigger queue processing
    public func processQueue() async {
        guard !isProcessing && networkMonitor.isConnected else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let pendingEntries = (try? await offlineScanQueueRepository.fetchPending()) ?? []
        
        for entry in pendingEntries {
            await processEntry(entry)
        }
        
        await loadPendingScans()
    }
    
    /// Clear completed scans from the queue
    public func clearCompleted() async throws {
        try await offlineScanQueueRepository.clearCompleted()
        await loadPendingScans()
    }
    
    /// Get the number of pending scans
    public var pendingCount: Int {
        pendingScans.count
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .filter { $0 } // Only when becoming connected
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadPendingScans() async {
        pendingScans = (try? await offlineScanQueueRepository.fetchPending()) ?? []
    }
    
    private func processEntry(_ entry: OfflineScanQueueEntry) async {
        // Check if we've exceeded max retries
        if entry.retryCount >= maxRetries {
            var failedEntry = entry
            failedEntry.status = .failed
            failedEntry.errorMessage = "Maximum retries exceeded"
            try? await offlineScanQueueRepository.save(failedEntry)
            return
        }
        
        // Check if we should wait before retrying
        if let lastRetry = entry.lastRetryDate,
           Date().timeIntervalSince(lastRetry) < retryDelay {
            return
        }
        
        // Update status to processing
        try? await offlineScanQueueRepository.updateStatus(id: entry.id, status: .processing)
        
        do {
            // Attempt barcode lookup
            if let productInfo = try await barcodeLookupService.lookupProduct(barcode: entry.barcode) {
                // Create item from product info
                let item = Item(
                    name: productInfo.name,
                    brand: productInfo.brand,
                    category: .other, // Default category, could be mapped from productInfo.category
                    barcode: entry.barcode
                )
                
                // Save the item
                try await itemRepository.save(item)
                
                // Mark as completed
                try await offlineScanQueueRepository.updateStatus(id: entry.id, status: .completed)
            } else {
                // No product found, but lookup succeeded - mark as completed
                var completedEntry = entry
                completedEntry.status = .completed
                completedEntry.errorMessage = "No product information found"
                try await offlineScanQueueRepository.save(completedEntry)
            }
        } catch {
            // Increment retry count
            try? await offlineScanQueueRepository.incrementRetryCount(id: entry.id)
            
            // Update error message
            var updatedEntry = entry
            updatedEntry.status = .pending
            updatedEntry.errorMessage = error.localizedDescription
            try? await offlineScanQueueRepository.save(updatedEntry)
        }
    }
    
    /// Retry a specific failed scan
    public func retryScan(id: UUID) async {
        guard let entry = try? await offlineScanQueueRepository.fetch(id: id) else { return }
        
        var updatedEntry = entry
        updatedEntry.status = .pending
        updatedEntry.retryCount = 0
        updatedEntry.errorMessage = nil
        
        try? await offlineScanQueueRepository.save(updatedEntry)
        await processQueue()
    }
}