//
//  PDFReportService.swift
//  Core
//
//  Service for generating professional PDF reports of inventory
//

import Foundation
import SwiftUI
import PDFKit
import UIKit

public class PDFReportService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isGenerating = false
    @Published public var progress: Double = 0.0
    @Published public var lastGeneratedReport: URL?
    @Published public var error: PDFReportError?
    
    // MARK: - Types
    
    public enum ReportType {
        case fullInventory
        case category(ItemCategory)
        case location(UUID)
        case insurance
        case warranty
        case highValue(threshold: Decimal)
        case custom(items: [Item])
        
        var title: String {
            switch self {
            case .fullInventory:
                return "Complete Inventory Report"
            case .category(let category):
                return "\(category.rawValue) Inventory Report"
            case .location:
                return "Location Inventory Report"
            case .insurance:
                return "Insurance Documentation Report"
            case .warranty:
                return "Warranty Status Report"
            case .highValue(let threshold):
                return "High Value Items Report (>\(threshold))"
            case .custom:
                return "Custom Inventory Report"
            }
        }
    }
    
    public struct ReportOptions {
        public var includePhotos: Bool = true
        public var includeReceipts: Bool = true
        public var includeWarrantyInfo: Bool = true
        public var includePurchaseInfo: Bool = true
        public var includeQRCodes: Bool = false
        public var includeSerialNumbers: Bool = true
        public var includeTotalValue: Bool = true
        public var groupByCategory: Bool = true
        public var sortBy: SortOption = .name
        public var pageSize: CGSize = CGSize(width: 612, height: 792) // US Letter
        public var margins: UIEdgeInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
        public var fontSize: CGFloat = 10
        public var photoSize: CGSize = CGSize(width: 150, height: 150)
        
        public enum SortOption {
            case name
            case value
            case purchaseDate
            case category
        }
        
        public init() {}
    }
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Generate a PDF report
    public func generateReport(
        type: ReportType,
        items: [Item],
        options: ReportOptions = ReportOptions(),
        locations: [UUID: Core.Location] = [:],
        warranties: [UUID: Core.Warranty] = [:]
    ) async throws -> URL {
        
        isGenerating = true
        progress = 0.0
        error = nil
        
        do {
            // Filter items based on report type
            let filteredItems = try filterItems(items, for: type)
            
            // Sort items
            let sortedItems = sortItems(filteredItems, by: options.sortBy)
            
            // Create PDF document
            let pdfDocument = PDFDocument()
            
            // Add cover page
            progress = 0.1
            let coverPage = createCoverPage(type: type, itemCount: sortedItems.count, options: options)
            pdfDocument.insert(coverPage, at: 0)
            
            // Add summary page if insurance report
            if case .insurance = type {
                progress = 0.2
                let summaryPage = createInsuranceSummaryPage(items: sortedItems, options: options)
                pdfDocument.insert(summaryPage, at: 1)
            }
            
            // Group items if needed
            let groupedItems: [(String, [Item])]
            if options.groupByCategory {
                let grouped = Dictionary(grouping: sortedItems) { $0.category }
                groupedItems = grouped.sorted { $0.key.rawValue < $1.key.rawValue }
                    .map { ($0.key.rawValue, $0.value) }
            } else {
                groupedItems = [("All Items", sortedItems)]
            }
            
            // Add item pages
            var currentPageIndex = pdfDocument.pageCount
            let totalItems = sortedItems.count
            var processedItems = 0
            
            for (groupName, groupItems) in groupedItems {
                // Add section header if grouping
                if options.groupByCategory && groupedItems.count > 1 {
                    let headerPage = createSectionHeaderPage(title: groupName, itemCount: groupItems.count, options: options)
                    pdfDocument.insert(headerPage, at: currentPageIndex)
                    currentPageIndex += 1
                }
                
                // Add items
                var itemsForCurrentPage: [Item] = []
                let itemsPerPage = calculateItemsPerPage(options: options)
                
                for item in groupItems {
                    itemsForCurrentPage.append(item)
                    
                    if itemsForCurrentPage.count >= itemsPerPage {
                        let itemPage = createItemPage(
                            items: itemsForCurrentPage,
                            locations: locations,
                            warranties: warranties,
                            options: options,
                            pageNumber: currentPageIndex + 1
                        )
                        pdfDocument.insert(itemPage, at: currentPageIndex)
                        currentPageIndex += 1
                        itemsForCurrentPage.removeAll()
                    }
                    
                    processedItems += 1
                    progress = 0.2 + (0.6 * Double(processedItems) / Double(totalItems))
                }
                
                // Add remaining items
                if !itemsForCurrentPage.isEmpty {
                    let itemPage = createItemPage(
                        items: itemsForCurrentPage,
                        locations: locations,
                        warranties: warranties,
                        options: options,
                        pageNumber: currentPageIndex + 1
                    )
                    pdfDocument.insert(itemPage, at: currentPageIndex)
                    currentPageIndex += 1
                }
            }
            
            // Add appendix pages
            progress = 0.8
            
            if options.includeWarrantyInfo, case .warranty = type {
                let warrantyPage = createWarrantyAppendixPage(items: sortedItems, warranties: warranties, options: options)
                pdfDocument.insert(warrantyPage, at: currentPageIndex)
                currentPageIndex += 1
            }
            
            // Add footer to all pages
            addFootersToAllPages(pdfDocument: pdfDocument)
            
            // Save PDF
            progress = 0.9
            let url = try savePDF(pdfDocument, type: type)
            
            progress = 1.0
            lastGeneratedReport = url
            isGenerating = false
            
            return url
            
        } catch {
            isGenerating = false
            self.error = error as? PDFReportError ?? .unknown(error.localizedDescription)
            throw error
        }
    }
    
    /// Generate a quick summary report
    public func generateQuickSummary(items: [Item]) async throws -> URL {
        let summaryItems = items.sorted { ($0.value ?? 0) > ($1.value ?? 0) }.prefix(20)
        return try await generateReport(
            type: .custom(items: Array(summaryItems)),
            items: Array(summaryItems),
            options: {
                var opts = ReportOptions()
                opts.includePhotos = false
                opts.includeReceipts = false
                return opts
            }()
        )
    }
    
    // MARK: - Private Methods
    
    private func filterItems(_ items: [Item], for type: ReportType) throws -> [Item] {
        switch type {
        case .fullInventory:
            return items
        case .category(let category):
            return items.filter { $0.category == category }
        case .location(let locationId):
            return items.filter { $0.locationId == locationId }
        case .insurance:
            return items.filter { ($0.value ?? 0) > 0 }
        case .warranty:
            return items.filter { $0.warrantyId != nil }
        case .highValue(let threshold):
            return items.filter { ($0.value ?? 0) >= threshold }
        case .custom(let customItems):
            return customItems
        }
    }
    
    private func sortItems(_ items: [Item], by option: ReportOptions.SortOption) -> [Item] {
        switch option {
        case .name:
            return items.sorted { $0.name < $1.name }
        case .value:
            return items.sorted { ($0.value ?? 0) > ($1.value ?? 0) }
        case .purchaseDate:
            return items.sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
        case .category:
            return items.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }
    
    private func calculateItemsPerPage(options: ReportOptions) -> Int {
        let availableHeight = options.pageSize.height - options.margins.top - options.margins.bottom - 100 // Header/footer space
        let itemHeight: CGFloat = options.includePhotos ? 200 : 100
        return max(1, Int(availableHeight / itemHeight))
    }
    
    // MARK: - Page Creation Methods
    
    private func createCoverPage(type: ReportType, itemCount: Int, options: ReportOptions) -> PDFPage {
        let page = PDFPage()
        
        let renderer = UIGraphicsImageRenderer(size: options.pageSize)
        let image = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: options.pageSize))
            
            // Logo/App Name
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            
            let title = "Home Inventory"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (options.pageSize.width - titleSize.width) / 2,
                y: options.margins.top,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Report Type
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let subtitle = type.title
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            let subtitleRect = CGRect(
                x: (options.pageSize.width - subtitleSize.width) / 2,
                y: titleRect.maxY + 20,
                width: subtitleSize.width,
                height: subtitleSize.height
            )
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            
            // Date
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            
            let dateString = "Generated on \(dateFormatter.string(from: Date()))"
            let dateSize = dateString.size(withAttributes: dateAttributes)
            let dateRect = CGRect(
                x: (options.pageSize.width - dateSize.width) / 2,
                y: subtitleRect.maxY + 10,
                width: dateSize.width,
                height: dateSize.height
            )
            dateString.draw(in: dateRect, withAttributes: dateAttributes)
            
            // Summary Box
            let boxY = options.pageSize.height / 2
            let boxWidth = options.pageSize.width - options.margins.left - options.margins.right
            let boxHeight: CGFloat = 120
            let boxRect = CGRect(x: options.margins.left, y: boxY, width: boxWidth, height: boxHeight)
            
            UIColor.systemGray5.setFill()
            UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()
            
            // Summary Content
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]
            
            let summaryText = """
            Total Items: \(itemCount)
            Report Type: \(type.title)
            """
            
            let summaryRect = boxRect.insetBy(dx: 20, dy: 20)
            summaryText.draw(in: summaryRect, withAttributes: summaryAttributes)
        }
        
        // Convert to PDF page
        if let data = image.pngData(),
           let provider = CGDataProvider(data: data as CFData),
           let cgImage = CGImage(
               pngDataProviderSource: provider,
               decode: nil,
               shouldInterpolate: true,
               intent: .defaultIntent
           ) {
            page.setBounds(CGRect(origin: .zero, size: options.pageSize), for: .mediaBox)
            // Note: In a real implementation, you'd draw directly to the PDF context
        }
        
        return page
    }
    
    private func createInsuranceSummaryPage(items: [Item], options: ReportOptions) -> PDFPage {
        let page = PDFPage()
        
        // Calculate totals
        let totalValue = items.reduce(Decimal(0)) { $0 + ($1.value ?? 0) }
        let categorySummary = Dictionary(grouping: items) { $0.category }
            .mapValues { items in
                items.reduce(Decimal(0)) { $0 + ($1.value ?? 0) }
            }
            .sorted { $0.value > $1.value }
        
        // In a real implementation, would draw summary tables and charts
        page.setBounds(CGRect(origin: .zero, size: options.pageSize), for: .mediaBox)
        
        return page
    }
    
    private func createSectionHeaderPage(title: String, itemCount: Int, options: ReportOptions) -> PDFPage {
        let page = PDFPage()
        page.setBounds(CGRect(origin: .zero, size: options.pageSize), for: .mediaBox)
        return page
    }
    
    private func createItemPage(
        items: [Item],
        locations: [UUID: Core.Location],
        warranties: [UUID: Core.Warranty],
        options: ReportOptions,
        pageNumber: Int
    ) -> PDFPage {
        let page = PDFPage()
        
        // In a real implementation, would create detailed item listings
        // with photos, details, warranties, etc.
        
        page.setBounds(CGRect(origin: .zero, size: options.pageSize), for: .mediaBox)
        return page
    }
    
    private func createWarrantyAppendixPage(
        items: [Item],
        warranties: [UUID: Core.Warranty],
        options: ReportOptions
    ) -> PDFPage {
        let page = PDFPage()
        page.setBounds(CGRect(origin: .zero, size: options.pageSize), for: .mediaBox)
        return page
    }
    
    private func addFootersToAllPages(pdfDocument: PDFDocument) {
        for i in 0..<pdfDocument.pageCount {
            // Add page numbers and timestamp to each page
        }
    }
    
    private func savePDF(_ document: PDFDocument, type: ReportType) throws -> URL {
        let fileName = "HomeInventory_\(type.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pdf"
        let url = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        
        guard document.write(to: url) else {
            throw PDFReportError.saveFailed
        }
        
        return url
    }
    
    /// Delete old report files
    public func cleanupOldReports(keepLast: Int = 5) {
        do {
            let tempDir = fileManager.temporaryDirectory
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey])
            
            let reportFiles = files
                .filter { $0.lastPathComponent.hasPrefix("HomeInventory_") && $0.pathExtension == "pdf" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
            
            // Delete old files
            for (index, file) in reportFiles.enumerated() where index >= keepLast {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to cleanup old reports: \(error)")
        }
    }
}

// MARK: - Errors

public enum PDFReportError: LocalizedError {
    case noItems
    case saveFailed
    case invalidReportType
    case photoLoadFailed
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .noItems:
            return "No items found for the selected report type"
        case .saveFailed:
            return "Failed to save PDF report"
        case .invalidReportType:
            return "Invalid report type selected"
        case .photoLoadFailed:
            return "Failed to load item photos"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Supporting Types

public typealias PDFLocation = Core.Location
public typealias PDFWarranty = Core.Warranty