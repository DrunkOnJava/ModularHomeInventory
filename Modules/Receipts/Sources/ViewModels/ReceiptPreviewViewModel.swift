import Foundation
import Core

/// View model for receipt preview/edit
/// Swift 5.9 - No Swift 6 features
@MainActor
final class ReceiptPreviewViewModel: ObservableObject {
    @Published var parsedData: ParsedReceiptData
    @Published var isLoading = false
    
    private let receiptRepository: any ReceiptRepository
    private let itemRepository: any ItemRepository
    private let completion: (Receipt) -> Void
    
    init(
        parsedData: ParsedReceiptData,
        receiptRepository: any ReceiptRepository,
        itemRepository: any ItemRepository,
        completion: @escaping (Receipt) -> Void
    ) {
        self.parsedData = parsedData
        self.receiptRepository = receiptRepository
        self.itemRepository = itemRepository
        self.completion = completion
    }
    
    func saveReceipt() async {
        // TODO: Implement saving parsed receipt
    }
}