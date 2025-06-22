import SwiftUI
import Core

/// Main implementation of the Receipts module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ReceiptsModule: ReceiptsModuleAPI {
    private let dependencies: ReceiptsModuleDependencies
    
    public init(dependencies: ReceiptsModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeReceiptsListView() -> AnyView {
        let viewModel = ReceiptsListViewModel(
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository,
            ocrService: dependencies.ocrService
        )
        return AnyView(ReceiptsListView(viewModel: viewModel))
    }
    
    public func makeReceiptDetailView(receipt: Receipt) -> AnyView {
        let viewModel = ReceiptDetailViewModel(
            receipt: receipt,
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository
        )
        return AnyView(ReceiptDetailView(viewModel: viewModel))
    }
    
    public func makeReceiptImportView(completion: @escaping (Receipt) -> Void) -> AnyView {
        let viewModel = ReceiptImportViewModel(
            emailService: dependencies.emailService,
            ocrService: dependencies.ocrService,
            completion: completion
        )
        return AnyView(ReceiptImportView(viewModel: viewModel))
    }
    
    public func makeReceiptPreviewView(parsedData: ParsedReceiptData, completion: @escaping (Receipt) -> Void) -> AnyView {
        let viewModel = ReceiptPreviewViewModel(
            parsedData: parsedData,
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository,
            completion: completion
        )
        return AnyView(ReceiptPreviewView(viewModel: viewModel))
    }
}