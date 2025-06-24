import Foundation
import UIKit

/// Item sharing functionality
/// Swift 5.9 - No Swift 6 features
public struct ItemShare {
    public let item: Item
    public let locations: [Location]
    
    public init(item: Item, locations: [Location]) {
        self.item = item
        self.locations = locations
    }
    
    /// Generate shareable text representation
    public func asText() -> String {
        var text = "📦 \(item.name)\n"
        
        if let brand = item.brand {
            text += "Brand: \(brand)\n"
        }
        
        if let model = item.model {
            text += "Model: \(model)\n"
        }
        
        text += "Category: \(item.category.displayName)\n"
        
        if let locationId = item.locationId,
           let location = locations.first(where: { $0.id == locationId }) {
            text += "Location: \(location.name)\n"
        }
        
        if item.quantity > 1 {
            text += "Quantity: \(item.quantity)\n"
        }
        
        if let purchasePrice = item.purchasePrice {
            text += "Purchase Price: \(formatCurrency(purchasePrice))\n"
        }
        
        if let purchaseDate = item.purchaseDate {
            text += "Purchase Date: \(formatDate(purchaseDate))\n"
        }
        
        if let storeName = item.storeName {
            text += "Store: \(storeName)\n"
        }
        
        if !item.tags.isEmpty {
            text += "Tags: \(item.tags.joined(separator: ", "))\n"
        }
        
        if let notes = item.notes, !notes.isEmpty {
            text += "\nNotes: \(notes)\n"
        }
        
        text += "\n---\nShared from Home Inventory"
        
        return text
    }
    
    /// Generate shareable JSON representation
    public func asJSON() -> Data? {
        let shareData = ItemShareData(
            name: item.name,
            brand: item.brand,
            model: item.model,
            category: item.category.displayName,
            location: getLocationName(),
            quantity: item.quantity,
            purchasePrice: item.purchasePrice,
            purchaseDate: item.purchaseDate,
            storeName: item.storeName,
            serialNumber: item.serialNumber,
            barcode: item.barcode,
            condition: item.condition.displayName,
            tags: item.tags,
            notes: item.notes
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(shareData)
    }
    
    /// Generate shareable CSV representation
    public func asCSV() -> String {
        var csv = "Name,Brand,Model,Category,Location,Quantity,Price,Purchase Date,Store,Notes\n"
        
        let values = [
            escapeCSVValue(item.name),
            escapeCSVValue(item.brand ?? ""),
            escapeCSVValue(item.model ?? ""),
            item.category.displayName,
            escapeCSVValue(getLocationName() ?? ""),
            String(item.quantity),
            item.purchasePrice.map { formatCurrency($0) } ?? "",
            item.purchaseDate.map { formatDate($0) } ?? "",
            escapeCSVValue(item.storeName ?? ""),
            escapeCSVValue(item.notes ?? "")
        ]
        
        csv += values.joined(separator: ",")
        return csv
    }
    
    /// Generate shareable URL (deep link)
    public func asURL() -> URL? {
        var components = URLComponents()
        components.scheme = "homeinventory"
        components.host = "item"
        components.path = "/\(item.id.uuidString)"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "name", value: item.name))
        
        if let brand = item.brand {
            queryItems.append(URLQueryItem(name: "brand", value: brand))
        }
        
        components.queryItems = queryItems
        
        return components.url
    }
    
    /// Generate QR code data
    public func asQRCodeData() -> Data? {
        guard let url = asURL() else { return nil }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "H"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = UIScreen.main.scale * 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }
    
    // MARK: - Private Helpers
    
    private func getLocationName() -> String? {
        guard let locationId = item.locationId else { return nil }
        return locations.first(where: { $0.id == locationId })?.name
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$\(value)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func escapeCSVValue(_ value: String) -> String {
        if value.contains("\"") || value.contains(",") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

/// Shareable item data structure
public struct ItemShareData: Codable {
    public let name: String
    public let brand: String?
    public let model: String?
    public let category: String
    public let location: String?
    public let quantity: Int
    public let purchasePrice: Decimal?
    public let purchaseDate: Date?
    public let storeName: String?
    public let serialNumber: String?
    public let barcode: String?
    public let condition: String
    public let tags: [String]
    public let notes: String?
}

/// QR Code generator filter
extension CIFilter {
    static func qrCodeGenerator() -> CIFilter {
        return CIFilter(name: "CIQRCodeGenerator")!
    }
    
    var message: Data? {
        get { return value(forKey: "inputMessage") as? Data }
        set { setValue(newValue, forKey: "inputMessage") }
    }
    
    var correctionLevel: String? {
        get { return value(forKey: "inputCorrectionLevel") as? String }
        set { setValue(newValue, forKey: "inputCorrectionLevel") }
    }
}