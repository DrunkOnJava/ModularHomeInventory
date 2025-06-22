import Foundation
import Core

/// View model for receipt detail view
/// Swift 5.9 - No Swift 6 features
@MainActor
final class ReceiptDetailViewModel: ObservableObject {
    @Published var receipt: Receipt
    @Published var linkedItems: [Item] = []
    @Published var isLoadingItems = false
    @Published var showingEditView = false
    @Published var showingDeleteConfirmation = false
    
    private let receiptRepository: any ReceiptRepository
    private let itemRepository: any ItemRepository
    
    init(receipt: Receipt, receiptRepository: any ReceiptRepository, itemRepository: any ItemRepository) {
        self.receipt = receipt
        self.receiptRepository = receiptRepository
        self.itemRepository = itemRepository
    }
    
    func loadLinkedItems() async {
        guard !receipt.itemIds.isEmpty else { return }
        
        isLoadingItems = true
        var items: [Item] = []
        
        // Load each linked item
        for itemId in receipt.itemIds {
            do {
                if let item = try await itemRepository.fetch(id: itemId) {
                    items.append(item)
                }
            } catch {
                print("Failed to load item \(itemId): \(error)")
            }
        }
        
        linkedItems = items
        isLoadingItems = false
    }
    
    func deleteReceipt() async {
        do {
            try await receiptRepository.delete(receipt)
        } catch {
            print("Failed to delete receipt: \(error)")
        }
    }
}