import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Service for sharing items
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ItemSharingService: ObservableObject {
    private let locationRepository: any LocationRepository
    
    public init(locationRepository: any LocationRepository) {
        self.locationRepository = locationRepository
    }
    
    /// Share formats
    public enum ShareFormat: String, CaseIterable {
        case text = "Text"
        case json = "JSON"
        case csv = "CSV"
        case qrCode = "QR Code"
        
        public var icon: String {
            switch self {
            case .text: return "doc.text"
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            case .qrCode: return "qrcode"
            }
        }
        
        public var description: String {
            switch self {
            case .text: return "Simple text format"
            case .json: return "Structured data format"
            case .csv: return "Spreadsheet format"
            case .qrCode: return "Scannable QR code"
            }
        }
    }
    
    /// Generate shareable content for an item
    public func generateShareContent(
        for item: Item,
        format: ShareFormat
    ) async throws -> Any {
        let locations = try await locationRepository.fetchAll()
        let itemShare = ItemShare(item: item, locations: locations)
        
        switch format {
        case .text:
            return itemShare.asText()
            
        case .json:
            guard let jsonData = itemShare.asJSON(),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ShareError.formatGenerationFailed
            }
            return jsonString
            
        case .csv:
            return itemShare.asCSV()
            
        case .qrCode:
            guard let qrData = itemShare.asQRCodeData(),
                  let image = UIImage(data: qrData) else {
                throw ShareError.qrCodeGenerationFailed
            }
            return image
        }
    }
    
    /// Generate multiple share items for activity controller
    public func generateShareItems(
        for item: Item,
        includeFormats: [ShareFormat] = [.text]
    ) async throws -> [Any] {
        var shareItems: [Any] = []
        
        for format in includeFormats {
            if let content = try? await generateShareContent(for: item, format: format) {
                shareItems.append(content)
            }
        }
        
        // Add metadata
        let metadata = ItemActivityItemSource(item: item)
        shareItems.append(metadata)
        
        return shareItems
    }
    
    /// Create a shareable file
    public func createShareFile(
        for item: Item,
        format: ShareFormat
    ) async throws -> URL {
        let content = try await generateShareContent(for: item, format: format)
        
        let fileName: String
        let data: Data
        
        switch format {
        case .text:
            fileName = "\(sanitizeFileName(item.name)).txt"
            guard let textData = (content as? String)?.data(using: .utf8) else {
                throw ShareError.dataConversionFailed
            }
            data = textData
            
        case .json:
            fileName = "\(sanitizeFileName(item.name)).json"
            guard let jsonData = (content as? String)?.data(using: .utf8) else {
                throw ShareError.dataConversionFailed
            }
            data = jsonData
            
        case .csv:
            fileName = "\(sanitizeFileName(item.name)).csv"
            guard let csvData = (content as? String)?.data(using: .utf8) else {
                throw ShareError.dataConversionFailed
            }
            data = csvData
            
        case .qrCode:
            fileName = "\(sanitizeFileName(item.name))_qr.png"
            guard let image = content as? UIImage,
                  let imageData = image.pngData() else {
                throw ShareError.dataConversionFailed
            }
            data = imageData
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        
        return tempURL
    }
    
    // MARK: - Private Helpers
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

/// Share errors
public enum ShareError: LocalizedError {
    case formatGenerationFailed
    case qrCodeGenerationFailed
    case dataConversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .formatGenerationFailed:
            return "Failed to generate share format"
        case .qrCodeGenerationFailed:
            return "Failed to generate QR code"
        case .dataConversionFailed:
            return "Failed to convert data"
        }
    }
}

/// Activity item source for rich sharing
public final class ItemActivityItemSource: NSObject, UIActivityItemSource {
    private let item: Item
    
    public init(item: Item) {
        self.item = item
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item.name
    }
    
    public func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return item.name
    }
    
    public func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return "Item: \(item.name)"
    }
    
    public func activityViewController(
        _ activityViewController: UIActivityViewController,
        thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
        suggestedSize size: CGSize
    ) -> UIImage? {
        // Could return item image thumbnail if available
        return nil
    }
    
    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = item.name
        
        if let brand = item.brand {
            metadata.originalURL = URL(string: "https://homeinventory.app/item/\(item.id)")
            metadata.url = metadata.originalURL
            metadata.imageProvider = NSItemProvider(object: UIImage(systemName: item.category.icon)!)
        }
        
        return metadata
    }
}

import LinkPresentation