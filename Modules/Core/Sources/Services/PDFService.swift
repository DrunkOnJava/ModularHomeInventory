import Foundation
import PDFKit
import UIKit

/// Service for handling PDF operations including multi-page support
/// Swift 5.9 - No Swift 6 features
public final class PDFService {
    public init() {}
    
    /// Extract page count from PDF data
    public func getPageCount(from data: Data) -> Int? {
        guard let document = PDFDocument(data: data) else { return nil }
        return document.pageCount
    }
    
    /// Extract page count from PDF URL
    public func getPageCount(from url: URL) -> Int? {
        guard let document = PDFDocument(url: url) else { return nil }
        return document.pageCount
    }
    
    /// Generate thumbnail for PDF page
    public func generateThumbnail(
        from data: Data,
        pageIndex: Int = 0,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage? {
        guard let document = PDFDocument(data: data),
              pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else { return nil }
        
        let bounds = page.bounds(for: .mediaBox)
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        let scaledSize = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: scaledSize))
            
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
    
    /// Generate thumbnails for all pages
    public func generateAllThumbnails(
        from data: Data,
        size: CGSize = CGSize(width: 200, height: 200)
    ) async -> [UIImage] {
        guard let document = PDFDocument(data: data) else { return [] }
        
        var thumbnails: [UIImage] = []
        for i in 0..<document.pageCount {
            if let thumbnail = generateThumbnail(from: data, pageIndex: i, size: size) {
                thumbnails.append(thumbnail)
            }
        }
        return thumbnails
    }
    
    /// Extract text from PDF for searching
    public func extractText(from data: Data) async -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.isEmpty ? nil : fullText
    }
    
    /// Split PDF into individual pages
    public func splitPages(from data: Data) async -> [(pageNumber: Int, data: Data)] {
        guard let document = PDFDocument(data: data) else { return [] }
        
        var pages: [(pageNumber: Int, data: Data)] = []
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                let newDocument = PDFDocument()
                newDocument.insert(page, at: 0)
                
                if let pageData = newDocument.dataRepresentation() {
                    pages.append((pageNumber: i + 1, data: pageData))
                }
            }
        }
        
        return pages
    }
    
    /// Merge multiple PDFs into one
    public func mergePDFs(_ pdfDataArray: [Data]) async -> Data? {
        let mergedDocument = PDFDocument()
        var pageIndex = 0
        
        for pdfData in pdfDataArray {
            if let document = PDFDocument(data: pdfData) {
                for i in 0..<document.pageCount {
                    if let page = document.page(at: i) {
                        mergedDocument.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            }
        }
        
        return mergedDocument.pageCount > 0 ? mergedDocument.dataRepresentation() : nil
    }
    
    /// Extract specific page range
    public func extractPages(
        from data: Data,
        startPage: Int,
        endPage: Int
    ) async -> Data? {
        guard let document = PDFDocument(data: data) else { return nil }
        
        let extractedDocument = PDFDocument()
        var insertIndex = 0
        
        for i in startPage...endPage {
            if i < document.pageCount,
               let page = document.page(at: i) {
                extractedDocument.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }
        
        return extractedDocument.pageCount > 0 ? extractedDocument.dataRepresentation() : nil
    }
    
    /// Get metadata from PDF
    public func getMetadata(from data: Data) -> PDFMetadata? {
        guard let document = PDFDocument(data: data) else { return nil }
        
        let attributes = document.documentAttributes ?? [:]
        
        return PDFMetadata(
            title: attributes[PDFDocumentAttribute.titleAttribute] as? String,
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String,
            subject: attributes[PDFDocumentAttribute.subjectAttribute] as? String,
            keywords: attributes[PDFDocumentAttribute.keywordsAttribute] as? [String],
            creator: attributes[PDFDocumentAttribute.creatorAttribute] as? String,
            producer: attributes[PDFDocumentAttribute.producerAttribute] as? String,
            creationDate: attributes[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date,
            pageCount: document.pageCount
        )
    }
}

/// PDF metadata structure
public struct PDFMetadata {
    public let title: String?
    public let author: String?
    public let subject: String?
    public let keywords: [String]?
    public let creator: String?
    public let producer: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let pageCount: Int
}