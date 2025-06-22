import Foundation
import SwiftUI
import Core
import Combine

/// View model for receipts list
/// Swift 5.9 - No Swift 6 features
@MainActor
final class ReceiptsListViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let receiptRepository: any ReceiptRepository
    private let itemRepository: any ItemRepository
    private let ocrService: any OCRServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(receiptRepository: any ReceiptRepository, itemRepository: any ItemRepository, ocrService: any OCRServiceProtocol) {
        self.receiptRepository = receiptRepository
        self.itemRepository = itemRepository
        self.ocrService = ocrService
    }
    
    /// Group receipts by month for display
    var groupedReceipts: [(key: String, value: [Receipt])] {
        let grouped = Dictionary(grouping: receipts) { receipt in
            formatMonth(receipt.date)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (key: $0.key, value: $0.value.sorted { $0.date > $1.date }) }
    }
    
    func loadReceipts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            receipts = try await receiptRepository.fetchAll()
        } catch {
            errorMessage = "Failed to load receipts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteReceipt(_ receipt: Receipt) async {
        do {
            try await receiptRepository.delete(receipt)
            receipts.removeAll { $0.id == receipt.id }
        } catch {
            errorMessage = "Failed to delete receipt: \(error.localizedDescription)"
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func makeAddReceiptView() -> AnyView? {
        let viewModel = AddReceiptViewModel(
            receiptRepository: receiptRepository,
            itemRepository: itemRepository,
            ocrService: ocrService,
            completion: { [weak self] receipt in
                Task { @MainActor in
                    await self?.loadReceipts()
                }
            }
        )
        return AnyView(AddReceiptView(viewModel: viewModel))
    }
    
    func makeReceiptDetailView(for receipt: Receipt) -> AnyView? {
        let viewModel = ReceiptDetailViewModel(
            receipt: receipt,
            receiptRepository: receiptRepository,
            itemRepository: itemRepository
        )
        return AnyView(ReceiptDetailView(viewModel: viewModel))
    }
}