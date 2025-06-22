import Foundation

/// Protocol for email parsing service
/// Swift 5.9 - No Swift 6 features
public protocol EmailServiceProtocol {
    /// Fetch emails from a specific sender or matching criteria
    func fetchEmails(from sender: String?, matching criteria: String?) async throws -> [EmailMessage]
    
    /// Parse email content to extract receipt information
    func parseReceiptFromEmail(_ email: EmailMessage) async throws -> ParsedEmailReceipt?
}

/// Email message structure
public struct EmailMessage {
    public let id: String
    public let subject: String
    public let sender: String
    public let recipient: String
    public let date: Date
    public let body: String
    public let attachments: [EmailAttachment]
    
    public init(
        id: String,
        subject: String,
        sender: String,
        recipient: String,
        date: Date,
        body: String,
        attachments: [EmailAttachment] = []
    ) {
        self.id = id
        self.subject = subject
        self.sender = sender
        self.recipient = recipient
        self.date = date
        self.body = body
        self.attachments = attachments
    }
}

/// Email attachment structure
public struct EmailAttachment {
    public let name: String
    public let mimeType: String
    public let data: Data
    
    public init(name: String, mimeType: String, data: Data) {
        self.name = name
        self.mimeType = mimeType
        self.data = data
    }
}

/// Parsed receipt from email
public struct ParsedEmailReceipt {
    public let storeName: String
    public let date: Date
    public let totalAmount: Decimal
    public let confidence: Double
    public let rawData: String
    
    public init(
        storeName: String,
        date: Date,
        totalAmount: Decimal,
        confidence: Double,
        rawData: String
    ) {
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.confidence = confidence
        self.rawData = rawData
    }
}