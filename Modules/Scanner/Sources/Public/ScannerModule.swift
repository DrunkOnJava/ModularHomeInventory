import SwiftUI
import Core
import Settings

/// Main implementation of the Scanner module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ScannerModule: ScannerModuleAPI {
    private let dependencies: ScannerModuleDependencies
    private let soundService: SoundFeedbackService
    public let offlineScanService: OfflineScanService
    
    public init(dependencies: ScannerModuleDependencies) {
        self.dependencies = dependencies
        self.soundService = SoundFeedbackService(settingsStorage: dependencies.settingsStorage)
        self.offlineScanService = OfflineScanService(
            offlineScanQueueRepository: dependencies.offlineScanQueueRepository,
            barcodeLookupService: dependencies.barcodeLookupService,
            itemRepository: dependencies.itemRepository,
            networkMonitor: dependencies.networkMonitor
        )
    }
    
    public func makeScannerView() -> AnyView {
        AnyView(ScannerTabView(
            scanHistoryRepository: dependencies.scanHistoryRepository,
            itemRepository: dependencies.itemRepository,
            offlineScanService: offlineScanService
        ))
    }
    
    public func makeBarcodeScannerView(completion: @escaping (String) -> Void) -> AnyView {
        let viewModel = BarcodeScannerViewModel(
            soundService: soundService,
            settingsStorage: dependencies.settingsStorage,
            scanHistoryRepository: dependencies.scanHistoryRepository,
            completion: completion
        )
        return AnyView(BarcodeScannerView(viewModel: viewModel))
    }
    
    public func makeBatchScannerView(completion: @escaping ([Item]) -> Void) -> AnyView {
        let viewModel = BatchScannerViewModel(
            itemRepository: dependencies.itemRepository,
            itemTemplateRepository: dependencies.itemTemplateRepository,
            createItemView: nil, // Will be provided by Items module
            soundService: soundService,
            settingsStorage: dependencies.settingsStorage,
            scanHistoryRepository: dependencies.scanHistoryRepository,
            completion: completion
        )
        return AnyView(BatchScannerView(viewModel: viewModel))
    }
    
    public func makeDocumentScannerView(completion: @escaping (UIImage) -> Void) -> AnyView {
        let viewModel = DocumentScannerViewModel(completion: completion)
        return AnyView(DocumentScannerView(viewModel: viewModel))
    }
    
    public func makeScanHistoryView() -> AnyView {
        return AnyView(ScanHistoryView(
            scanHistoryRepository: dependencies.scanHistoryRepository,
            itemRepository: dependencies.itemRepository
        ))
    }
    
    public func makeOfflineScanQueueView() -> AnyView {
        return AnyView(OfflineScanQueueView(
            offlineScanService: offlineScanService
        ))
    }
}