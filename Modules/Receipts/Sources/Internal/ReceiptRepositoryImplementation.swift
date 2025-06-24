import Foundation
import Core

/// Mock implementation of ReceiptRepository for development
/// Swift 5.9 - No Swift 6 features
final class ReceiptRepositoryImplementation: ReceiptRepository {
    private var receipts: [Receipt] = []
    private let queue = DispatchQueue(label: "com.homeinventory.receipts", attributes: .concurrent)
    
    init() {
        // Initialize with some preview receipts
        self.receipts = [Receipt.preview]
    }
    
    // MARK: - Repository Protocol
    
    func fetchAll() async throws -> [Receipt] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.receipts)
            }
        }
    }
    
    func fetch(id: UUID) async throws -> Receipt? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let receipt = self.receipts.first { $0.id == id }
                continuation.resume(returning: receipt)
            }
        }
    }
    
    func save(_ entity: Receipt) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.receipts.firstIndex(where: { $0.id == entity.id }) {
                    self.receipts[index] = entity
                } else {
                    self.receipts.append(entity)
                }
                continuation.resume()
            }
        }
    }
    
    func delete(_ entity: Receipt) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.receipts.removeAll { $0.id == entity.id }
                continuation.resume()
            }
        }
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Receipt] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.receipts.filter { receipt in
                    receipt.date >= startDate && receipt.date <= endDate
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    func fetchByStore(_ storeName: String) async throws -> [Receipt] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.receipts.filter { receipt in
                    receipt.storeName.localizedCaseInsensitiveContains(storeName)
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    func fetchByItemId(_ itemId: UUID) async throws -> [Receipt] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.receipts.filter { receipt in
                    receipt.itemIds.contains(itemId)
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    func fetchAboveAmount(_ amount: Decimal) async throws -> [Receipt] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.receipts.filter { receipt in
                    receipt.totalAmount > amount
                }
                continuation.resume(returning: filtered)
            }
        }
    }
}