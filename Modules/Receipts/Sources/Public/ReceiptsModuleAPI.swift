import SwiftUI
import Core

/// Public API for the Receipts module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol ReceiptsModuleAPI: AnyObject {
    /// Creates the main receipts list view
    func makeReceiptsListView() -> AnyView
    
    /// Creates a receipt detail view
    func makeReceiptDetailView(receipt: Receipt) -> AnyView
    
    /// Creates a receipt import view
    func makeReceiptImportView(completion: @escaping (Receipt) -> Void) -> AnyView
    
    /// Creates a receipt preview/edit view
    func makeReceiptPreviewView(parsedData: ParsedReceiptData, completion: @escaping (Receipt) -> Void) -> AnyView
}

/// Dependencies required by the Receipts module
public struct ReceiptsModuleDependencies {
    public let receiptRepository: any ReceiptRepository
    public let itemRepository: any ItemRepository
    public let emailService: any EmailServiceProtocol
    public let ocrService: any OCRServiceProtocol
    
    public init(
        receiptRepository: any ReceiptRepository,
        itemRepository: any ItemRepository,
        emailService: any EmailServiceProtocol,
        ocrService: any OCRServiceProtocol
    ) {
        self.receiptRepository = receiptRepository
        self.itemRepository = itemRepository
        self.emailService = emailService
        self.ocrService = ocrService
    }
}

/// Parsed receipt data before creating a Receipt entity
public struct ParsedReceiptData {
    public var storeName: String
    public var date: Date
    public var totalAmount: Decimal
    public var items: [ParsedReceiptItem]
    public var confidence: Double
    public var rawText: String?
    public var imageData: Data?
    
    public init(
        storeName: String,
        date: Date,
        totalAmount: Decimal,
        items: [ParsedReceiptItem] = [],
        confidence: Double = 0.0,
        rawText: String? = nil,
        imageData: Data? = nil
    ) {
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.items = items
        self.confidence = confidence
        self.rawText = rawText
        self.imageData = imageData
    }
}

/// Individual item parsed from a receipt
public struct ParsedReceiptItem {
    public var name: String
    public var quantity: Int
    public var price: Decimal
    public var category: ItemCategory?
    
    public init(
        name: String,
        quantity: Int = 1,
        price: Decimal,
        category: ItemCategory? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
    }
}