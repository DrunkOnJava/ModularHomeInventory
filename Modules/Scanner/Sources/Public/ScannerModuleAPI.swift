import SwiftUI
import Core
#if canImport(UIKit)
import UIKit
#endif

/// Public API for the Scanner module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol ScannerModuleAPI: AnyObject {
    /// Creates the main scanner view
    func makeScannerView() -> AnyView
    
    /// Creates a barcode scanner view with completion handler
    func makeBarcodeScannerView(completion: @escaping (String) -> Void) -> AnyView
    
    /// Creates a batch scanner view for scanning multiple items
    func makeBatchScannerView(completion: @escaping ([Item]) -> Void) -> AnyView
    
    /// Creates a document scanner view
    func makeDocumentScannerView(completion: @escaping (UIImage) -> Void) -> AnyView
    
    /// Creates the scan history view
    func makeScanHistoryView() -> AnyView
    
    /// Creates the offline scan queue view
    func makeOfflineScanQueueView() -> AnyView
    
    /// Get the offline scan service for monitoring queue status
    var offlineScanService: OfflineScanService { get }
}

/// Scanner result types
public enum ScanResult {
    case barcode(String)
    case document(UIImage)
    case error(Error)
}

/// Dependencies required by the Scanner module
public struct ScannerModuleDependencies {
    public let itemRepository: any ItemRepository
    public let itemTemplateRepository: any ItemTemplateRepository
    public let settingsStorage: SettingsStorageProtocol
    public let scanHistoryRepository: any ScanHistoryRepository
    public let offlineScanQueueRepository: any OfflineScanQueueRepository
    public let barcodeLookupService: BarcodeLookupService
    public let networkMonitor: NetworkMonitor
    
    public init(
        itemRepository: any ItemRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        settingsStorage: SettingsStorageProtocol,
        scanHistoryRepository: any ScanHistoryRepository,
        offlineScanQueueRepository: any OfflineScanQueueRepository,
        barcodeLookupService: BarcodeLookupService,
        networkMonitor: NetworkMonitor
    ) {
        self.itemRepository = itemRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.settingsStorage = settingsStorage
        self.scanHistoryRepository = scanHistoryRepository
        self.offlineScanQueueRepository = offlineScanQueueRepository
        self.barcodeLookupService = barcodeLookupService
        self.networkMonitor = networkMonitor
    }
}