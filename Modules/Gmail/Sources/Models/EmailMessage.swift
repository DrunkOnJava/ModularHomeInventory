import Foundation

struct EmailMessage: Identifiable {
    let id: String
    let subject: String
    let from: String
    let date: Date
    let snippet: String
    let body: String
    let receiptInfo: ReceiptInfo?
}

struct ReceiptInfo {
    let retailer: String
    let orderNumber: String?
    let totalAmount: Double?
    let items: [ReceiptItem]
    let orderDate: Date?
    let confidence: Double
}

struct ReceiptItem {
    let name: String
    let price: Double?
    let quantity: Int
}