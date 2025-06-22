import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Protocol for OCR (Optical Character Recognition) service
/// Swift 5.9 - No Swift 6 features
public protocol OCRServiceProtocol {
    #if canImport(UIKit)
    /// Extract text from an image
    func extractText(from image: UIImage) async throws -> OCRResult
    
    /// Extract structured receipt data from an image
    func extractReceiptData(from image: UIImage) async throws -> OCRReceiptData?
    #endif
}

/// OCR extraction result
public struct OCRResult {
    public let text: String
    public let confidence: Double
    public let language: String?
    public let regions: [OCRTextRegion]
    
    public init(
        text: String,
        confidence: Double,
        language: String? = nil,
        regions: [OCRTextRegion] = []
    ) {
        self.text = text
        self.confidence = confidence
        self.language = language
        self.regions = regions
    }
}

/// Text region identified by OCR
public struct OCRTextRegion {
    public let text: String
    public let confidence: Double
    #if canImport(UIKit)
    public let boundingBox: CGRect
    
    public init(text: String, confidence: Double, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
    #else
    public init(text: String, confidence: Double) {
        self.text = text
        self.confidence = confidence
    }
    #endif
}

/// Structured receipt data from OCR
public struct OCRReceiptData {
    public let storeName: String?
    public let date: Date?
    public let totalAmount: Decimal?
    public let items: [OCRReceiptItem]
    public let confidence: Double
    public let rawText: String
    
    public init(
        storeName: String? = nil,
        date: Date? = nil,
        totalAmount: Decimal? = nil,
        items: [OCRReceiptItem] = [],
        confidence: Double,
        rawText: String
    ) {
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.items = items
        self.confidence = confidence
        self.rawText = rawText
    }
}

/// Individual item from OCR receipt
public struct OCRReceiptItem {
    public let name: String
    public let price: Decimal?
    public let quantity: Int?
    
    public init(name: String, price: Decimal? = nil, quantity: Int? = nil) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}