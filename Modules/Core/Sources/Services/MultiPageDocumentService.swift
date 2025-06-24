import Foundation
import UIKit
import Vision
import VisionKit

/// Service for handling multi-page document operations including scanning
/// Swift 5.9 - No Swift 6 features
@available(iOS 16.0, *)
public final class MultiPageDocumentService: NSObject {
    private let pdfService = PDFService()
    
    public override init() {
        super.init()
    }
    
    /// Scan multiple pages using document scanner
    @MainActor
    public func scanMultiPageDocument(from viewController: UIViewController) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = self
            viewController.present(scannerViewController, animated: true)
            
            // Store continuation for later use
            self.scanContinuation = continuation
        }
    }
    
    /// Process scanned pages into a single PDF
    public func processScannedPages(_ scan: VNDocumentCameraScan) async -> Data? {
        var pageImages: [UIImage] = []
        
        for pageIndex in 0..<scan.pageCount {
            let scannedImage = scan.imageOfPage(at: pageIndex)
            pageImages.append(scannedImage)
        }
        
        return await createPDFFromImages(pageImages)
    }
    
    /// Create PDF from array of images
    public func createPDFFromImages(_ images: [UIImage]) async -> Data? {
        let pdfDocument = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfDocument, .zero, nil)
        
        for image in images {
            let bounds = CGRect(origin: .zero, size: image.size)
            UIGraphicsBeginPDFPageWithInfo(bounds, nil)
            
            image.draw(in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        return pdfDocument as Data
    }
    
    /// Split a long receipt/document into multiple logical sections
    public func splitDocumentIntoSections(
        data: Data,
        maxPagesPerSection: Int = 10
    ) async -> [(sectionNumber: Int, data: Data, pageRange: Range<Int>)] {
        let pageDataArray = await pdfService.splitPages(from: data)
        
        var sections: [(sectionNumber: Int, data: Data, pageRange: Range<Int>)] = []
        var currentSection = 1
        
        for i in stride(from: 0, to: pageDataArray.count, by: maxPagesPerSection) {
            let endIndex = min(i + maxPagesPerSection, pageDataArray.count)
            let sectionPages = Array(pageDataArray[i..<endIndex])
            
            if let mergedData = await pdfService.mergePDFs(sectionPages.map { $0.data }) {
                sections.append((
                    sectionNumber: currentSection,
                    data: mergedData,
                    pageRange: i..<endIndex
                ))
                currentSection += 1
            }
        }
        
        return sections
    }
    
    /// Extract receipt items from multi-page receipt
    public func extractReceiptItems(from data: Data) async -> [ExtractedReceiptItem] {
        guard let text = await pdfService.extractText(from: data) else {
            return []
        }
        
        // Parse receipt text to extract items
        return parseReceiptText(text)
    }
    
    private func parseReceiptText(_ text: String) -> [ExtractedReceiptItem] {
        var items: [ExtractedReceiptItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            // Simple pattern matching for receipt items
            // Format: Item Name ... Price
            let pricePattern = #"(\d+\.\d{2})"#
            if let priceMatch = line.range(of: pricePattern, options: .regularExpression) {
                let price = String(line[priceMatch])
                let itemName = line.replacingOccurrences(of: price, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                
                if !itemName.isEmpty, let priceValue = Double(price) {
                    items.append(ExtractedReceiptItem(
                        name: itemName,
                        price: priceValue,
                        quantity: 1
                    ))
                }
            }
        }
        
        return items
    }
    
    // Store continuation for async delegate callbacks
    private var scanContinuation: CheckedContinuation<Data?, Error>?
}

// MARK: - Document Scanner Delegate
@available(iOS 16.0, *)
extension MultiPageDocumentService: VNDocumentCameraViewControllerDelegate {
    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true) { [weak self] in
            Task {
                let pdfData = await self?.processScannedPages(scan)
                self?.scanContinuation?.resume(returning: pdfData)
                self?.scanContinuation = nil
            }
        }
    }
    
    public func documentCameraViewControllerDidCancel(
        _ controller: VNDocumentCameraViewController
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.scanContinuation?.resume(returning: nil)
            self?.scanContinuation = nil
        }
    }
    
    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.scanContinuation?.resume(throwing: error)
            self?.scanContinuation = nil
        }
    }
}

/// Extracted receipt item from multi-page receipt
public struct ExtractedReceiptItem {
    public let name: String
    public let price: Double
    public let quantity: Int
    
    public init(name: String, price: Double, quantity: Int) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}