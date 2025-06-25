import Foundation

public struct EmailMessage: Identifiable {
    public init(id: String, subject: String, from: String, date: Date, snippet: String, body: String, receiptInfo: ReceiptInfo?) {
        self.id = id
        self.subject = subject
        self.from = from
        self.date = date
        self.snippet = snippet
        self.body = body
        self.receiptInfo = receiptInfo
    }
    public let id: String
    public let subject: String
    public let from: String
    public let date: Date
    public let snippet: String
    public let body: String
    public let receiptInfo: ReceiptInfo?
}

public struct ReceiptInfo {
    public init(retailer: String, orderNumber: String?, totalAmount: Double?, items: [ReceiptItem], orderDate: Date?, confidence: Double) {
        self.retailer = retailer
        self.orderNumber = orderNumber
        self.totalAmount = totalAmount
        self.items = items
        self.orderDate = orderDate
        self.confidence = confidence
    }
    public let retailer: String
    public let orderNumber: String?
    public let totalAmount: Double?
    public let items: [ReceiptItem]
    public let orderDate: Date?
    public let confidence: Double
}

public struct ReceiptItem {
    public init(name: String, price: Double?, quantity: Int) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
    public let name: String
    public let price: Double?
    public let quantity: Int
}