import Foundation

/// Protocol for receipt data operations
/// Swift 5.9 - No Swift 6 features
public protocol ReceiptRepository: Repository where Entity == Receipt {
    /// Fetch receipts by date range
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Receipt]
    
    /// Fetch receipts by store name
    func fetchByStore(_ storeName: String) async throws -> [Receipt]
    
    /// Fetch receipts containing specific item
    func fetchByItemId(_ itemId: UUID) async throws -> [Receipt]
    
    /// Fetch receipts above certain amount
    func fetchAboveAmount(_ amount: Decimal) async throws -> [Receipt]
}