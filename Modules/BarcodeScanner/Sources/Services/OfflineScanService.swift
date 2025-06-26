//
//  OfflineScanService.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: BarcodeScanner
//  Dependencies: Foundation, Core, Combine
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/OfflineScanServiceTests.swift
//
//  Description: Service for managing offline scan queue, handling scans when network
//               is unavailable and processing them when connection is restored
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

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