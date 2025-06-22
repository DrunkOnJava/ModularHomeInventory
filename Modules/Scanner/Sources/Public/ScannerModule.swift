import SwiftUI
import Core

/// Main implementation of the Scanner module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ScannerModule: ScannerModuleAPI {
    private let dependencies: ScannerModuleDependencies
    
    public init(dependencies: ScannerModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeScannerView() -> AnyView {
        AnyView(ScannerTabView())
    }
    
    public func makeBarcodeScannerView(completion: @escaping (String) -> Void) -> AnyView {
        let viewModel = BarcodeScannerViewModel(completion: completion)
        return AnyView(BarcodeScannerView(viewModel: viewModel))
    }
    
    public func makeBatchScannerView(completion: @escaping ([Item]) -> Void) -> AnyView {
        let viewModel = BatchScannerViewModel(
            itemRepository: dependencies.itemRepository,
            itemTemplateRepository: dependencies.itemTemplateRepository,
            createItemView: nil, // Will be provided by Items module
            completion: completion
        )
        return AnyView(BatchScannerView(viewModel: viewModel))
    }
    
    public func makeDocumentScannerView(completion: @escaping (UIImage) -> Void) -> AnyView {
        let viewModel = DocumentScannerViewModel(completion: completion)
        return AnyView(DocumentScannerView(viewModel: viewModel))
    }
}