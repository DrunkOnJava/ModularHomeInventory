import Foundation
import Core
import UIKit

/// Builder for creating test data
public struct TestDataBuilder {
    
    // MARK: - Items
    
    public static func createItem(
        name: String? = nil,
        value: Double? = nil,
        category: Category? = nil,
        serialNumber: String? = nil,
        notes: String? = nil,
        images: [UIImage] = []
    ) -> Item {
        return Item(
            id: UUID(),
            name: name ?? "Test Item \(UUID().uuidString.prefix(8))",
            value: value ?? Double.random(in: 10...1000),
            category: category ?? Category.allCases.randomElement()!,
            serialNumber: serialNumber,
            notes: notes,
            images: images.compactMap { $0.pngData() },
            createdAt: Date(),
            modifiedAt: Date()
        )
    }
    
    public static func createItems(count: Int) -> [Item] {
        return (0..<count).map { i in
            createItem(
                name: "Item \(i)",
                value: Double(i * 10),
                category: Category.allCases[i % Category.allCases.count]
            )
        }
    }
    
    // MARK: - Users
    
    public static func createUser(
        email: String? = nil,
        name: String? = nil,
        isPremium: Bool = false
    ) -> User {
        return User(
            id: UUID(),
            email: email ?? "user\(Int.random(in: 1000...9999))@example.com",
            name: name ?? "Test User",
            isPremium: isPremium,
            createdAt: Date()
        )
    }
    
    // MARK: - Receipts
    
    public static func createReceipt(
        storeName: String? = nil,
        date: Date? = nil,
        total: Double? = nil,
        items: [ReceiptItem] = []
    ) -> Receipt {
        return Receipt(
            id: UUID(),
            storeName: storeName ?? "Test Store",
            date: date ?? Date(),
            total: total ?? items.reduce(0) { $0 + $1.price },
            items: items.isEmpty ? createReceiptItems(count: 3) : items,
            imageData: nil
        )
    }
    
    public static func createReceiptItems(count: Int) -> [ReceiptItem] {
        return (0..<count).map { i in
            ReceiptItem(
                name: "Receipt Item \(i)",
                price: Double(i + 1) * 10,
                quantity: 1
            )
        }
    }
    
    // MARK: - Warranties
    
    public static func createWarranty(
        itemId: UUID? = nil,
        expiryDate: Date? = nil,
        provider: String? = nil
    ) -> Warranty {
        return Warranty(
            id: UUID(),
            itemId: itemId ?? UUID(),
            startDate: Date(),
            expiryDate: expiryDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60),
            provider: provider ?? "Test Warranty Provider",
            terms: "Standard warranty terms",
            reminderEnabled: true
        )
    }
    
    // MARK: - Collections
    
    public static func createCollection(
        name: String? = nil,
        items: [Item] = []
    ) -> ItemCollection {
        return ItemCollection(
            id: UUID(),
            name: name ?? "Test Collection",
            description: "A test collection",
            itemIds: items.map { $0.id },
            iconName: "folder",
            color: "#007AFF",
            createdAt: Date(),
            modifiedAt: Date()
        )
    }
    
    // MARK: - Test Images
    
    public static func createTestImage(
        size: CGSize = CGSize(width: 100, height: 100),
        color: UIColor = .systemBlue
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some text to make images unique
            let text = UUID().uuidString.prefix(8)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            String(text).draw(in: textRect, withAttributes: attributes)
        }
    }
    
    public static func createLargeTestImage(sizeMB: Int) -> UIImage {
        let pixelCount = sizeMB * 1024 * 1024 / 4 // 4 bytes per pixel
        let dimension = Int(sqrt(Double(pixelCount)))
        let size = CGSize(width: dimension, height: dimension)
        
        return createTestImage(size: size)
    }
    
    // MARK: - CSV Data
    
    public static func createCSVData(itemCount: Int) -> Data {
        var csv = "Name,Category,Value,Serial Number,Purchase Date,Notes\n"
        
        for i in 0..<itemCount {
            let item = createItem(name: "CSV Item \(i)")
            csv += "\"\(item.name)\",\"\(item.category?.rawValue ?? "")\",\(item.value ?? 0),"
            csv += "\"\(item.serialNumber ?? "")\",\"\(ISO8601DateFormatter().string(from: item.createdAt))\","
            csv += "\"\(item.notes ?? "")\"\n"
        }
        
        return csv.data(using: .utf8)!
    }
    
    // MARK: - Email Messages
    
    public static func createEmailMessage(
        subject: String? = nil,
        from: String? = nil,
        hasAttachment: Bool = false
    ) -> EmailMessage {
        return EmailMessage(
            id: UUID().uuidString,
            subject: subject ?? "Test Email",
            from: from ?? "sender@example.com",
            to: "user@example.com",
            date: Date(),
            snippet: "This is a test email message...",
            body: "Full email body content here.",
            attachments: hasAttachment ? [
                EmailAttachment(
                    filename: "receipt.pdf",
                    mimeType: "application/pdf",
                    size: 1024 * 100, // 100KB
                    data: Data()
                )
            ] : []
        )
    }
    
    // MARK: - Random Data
    
    public static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    public static func randomDate(
        daysBack: Int = 365,
        daysForward: Int = 365
    ) -> Date {
        let timeInterval = TimeInterval.random(
            in: -Double(daysBack * 24 * 60 * 60)...Double(daysForward * 24 * 60 * 60)
        )
        return Date().addingTimeInterval(timeInterval)
    }
}

// MARK: - Test Fixtures

public struct TestFixtures {
    
    public static let sampleReceiptPDF: Data = {
        // Create a simple PDF
        let pdfMetaData = [
            kCGPDFContextCreator: "Home Inventory Test",
            kCGPDFContextAuthor: "Test Suite"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 612, height: 792),
            format: format
        )
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24)
            ]
            
            "Test Receipt".draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
    }()
    
    public static let sampleBarcode = "1234567890123"
    
    public static let sampleSerialNumbers = [
        "SN123456789",
        "ABCD-1234-EFGH-5678",
        "2023-001-XYZ-999"
    ]
    
    public static let sampleCategories = Category.allCases
}

// MARK: - Email Message Model

public struct EmailMessage {
    public let id: String
    public let subject: String
    public let from: String
    public let to: String
    public let date: Date
    public let snippet: String
    public let body: String
    public let attachments: [EmailAttachment]
}

public struct EmailAttachment {
    public let filename: String
    public let mimeType: String
    public let size: Int
    public let data: Data
}