//
//  InsuranceReportService.swift
//  Core
//
//  Service for generating professional insurance documentation reports
//

import Foundation
import SwiftUI
import PDFKit
import UIKit

public class InsuranceReportService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isGenerating = false
    @Published public var progress: Double = 0.0
    @Published public var lastGeneratedReport: URL?
    @Published public var error: InsuranceReportError?
    
    // MARK: - Dependencies
    
    private let pdfService = PDFReportService()
    private let currencyService = CurrencyExchangeService.shared
    
    // MARK: - Types
    
    public enum InsuranceReportType {
        case fullInventory(policyNumber: String?)
        case claimDocumentation(items: [Item], claimNumber: String?)
        case highValueItems(threshold: Decimal)
        case categoryBreakdown
        case annualReview
        case newPurchases(since: Date)
        
        var title: String {
            switch self {
            case .fullInventory:
                return "Home Inventory Insurance Documentation"
            case .claimDocumentation:
                return "Insurance Claim Documentation"
            case .highValueItems:
                return "High Value Items Report"
            case .categoryBreakdown:
                return "Inventory Category Breakdown"
            case .annualReview:
                return "Annual Insurance Review Report"
            case .newPurchases:
                return "New Purchases Report"
            }
        }
    }
    
    public struct InsuranceReportOptions {
        public var includePhotos: Bool = true
        public var includeReceipts: Bool = true
        public var includeSerialNumbers: Bool = true
        public var includePurchaseInfo: Bool = true
        public var includeReplacementCosts: Bool = true
        public var groupByCategory: Bool = true
        public var includeDepreciation: Bool = false
        public var policyHolderName: String = ""
        public var policyNumber: String = ""
        public var insuranceCompany: String = ""
        public var deductible: Decimal = 0
        public var coverageLimit: Decimal = 0
        
        public init() {}
    }
    
    public enum InsuranceReportError: LocalizedError {
        case generationFailed(String)
        case noItemsToReport
        case invalidConfiguration
        
        public var errorDescription: String? {
            switch self {
            case .generationFailed(let reason):
                return "Failed to generate insurance report: \(reason)"
            case .noItemsToReport:
                return "No items found for the requested report"
            case .invalidConfiguration:
                return "Invalid report configuration"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate a comprehensive insurance report
    public func generateInsuranceReport(
        type: InsuranceReportType,
        items: [Item],
        options: InsuranceReportOptions = InsuranceReportOptions(),
        warranties: [UUID: Core.Warranty] = [:],
        receipts: [UUID: Core.Receipt] = [:]
    ) async throws -> URL {
        
        guard !items.isEmpty else {
            throw InsuranceReportError.noItemsToReport
        }
        
        await MainActor.run {
            isGenerating = true
            progress = 0.0
        }
        
        do {
            // Create PDF document
            let pdfDocument = PDFDocument()
            
            // Add cover page
            progress = 0.1
            let coverPage = createInsuranceCoverPage(type: type, options: options, itemCount: items.count)
            pdfDocument.insert(coverPage, at: 0)
            
            // Add summary page
            progress = 0.2
            let summaryPage = createSummaryPage(items: items, options: options)
            pdfDocument.insert(summaryPage, at: 1)
            
            // Group items by category if requested
            let itemGroups: [(String, [Item])]
            if options.groupByCategory {
                let grouped = Dictionary(grouping: items) { $0.category.rawValue }
                itemGroups = grouped.sorted { $0.key < $1.key }
            } else {
                itemGroups = [("All Items", items.sorted { $0.name < $1.name })]
            }
            
            // Add item pages
            var pageIndex = 2
            let totalGroups = itemGroups.count
            
            for (index, (category, categoryItems)) in itemGroups.enumerated() {
                progress = 0.2 + (0.6 * Double(index) / Double(totalGroups))
                
                // Add category header if grouped
                if options.groupByCategory {
                    let headerPage = createCategoryHeaderPage(category: category, items: categoryItems, options: options)
                    pdfDocument.insert(headerPage, at: pageIndex)
                    pageIndex += 1
                }
                
                // Add item detail pages
                for item in categoryItems {
                    let itemPage = createItemDetailPage(
                        item: item,
                        warranty: warranties[item.warrantyId ?? UUID()],
                        receipt: receipts[item.id],
                        options: options
                    )
                    pdfDocument.insert(itemPage, at: pageIndex)
                    pageIndex += 1
                }
            }
            
            // Add appendices
            progress = 0.8
            
            // Add receipts appendix if requested
            if options.includeReceipts && !receipts.isEmpty {
                let receiptsPage = createReceiptsAppendix(receipts: Array(receipts.values))
                pdfDocument.insert(receiptsPage, at: pageIndex)
                pageIndex += 1
            }
            
            // Add valuation methodology page
            let valuationPage = createValuationMethodologyPage()
            pdfDocument.insert(valuationPage, at: pageIndex)
            
            // Add page numbers
            addPageNumbers(to: pdfDocument)
            
            // Save PDF
            progress = 0.9
            let fileName = generateFileName(for: type)
            let url = try savePDF(pdfDocument, fileName: fileName)
            
            await MainActor.run {
                progress = 1.0
                lastGeneratedReport = url
                isGenerating = false
            }
            
            return url
            
        } catch {
            await MainActor.run {
                isGenerating = false
                self.error = error as? InsuranceReportError ?? .generationFailed(error.localizedDescription)
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func createInsuranceCoverPage(type: InsuranceReportType, options: InsuranceReportOptions, itemCount: Int) -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792) // Letter size
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 100
            
            // Report title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            
            let title = type.title
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 60
            
            // Policy information if provided
            if !options.policyNumber.isEmpty || !options.policyHolderName.isEmpty {
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
                
                if !options.policyHolderName.isEmpty {
                    "Policy Holder: \(options.policyHolderName)".draw(
                        at: CGPoint(x: 50, y: yPosition),
                        withAttributes: infoAttributes
                    )
                    yPosition += 25
                }
                
                if !options.policyNumber.isEmpty {
                    "Policy Number: \(options.policyNumber)".draw(
                        at: CGPoint(x: 50, y: yPosition),
                        withAttributes: infoAttributes
                    )
                    yPosition += 25
                }
                
                if !options.insuranceCompany.isEmpty {
                    "Insurance Company: \(options.insuranceCompany)".draw(
                        at: CGPoint(x: 50, y: yPosition),
                        withAttributes: infoAttributes
                    )
                    yPosition += 25
                }
            }
            
            // Report date
            yPosition += 20
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Report Date: \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ])
            
            // Item count
            yPosition += 25
            "Total Items: \(itemCount)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ])
            
            // Important notice
            yPosition = pageSize.height - 200
            let noticeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let notice = """
            IMPORTANT: This report is provided for insurance documentation purposes only.
            All valuations are estimates based on available information and should be
            verified by qualified appraisers for official insurance claims.
            """
            
            let noticeRect = CGRect(x: 50, y: yPosition, width: pageSize.width - 100, height: 100)
            notice.draw(in: noticeRect, withAttributes: noticeAttributes)
        }
        
        // Create PDF page from image
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func createSummaryPage(items: [Item], options: InsuranceReportOptions) -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 50
            
            // Page title
            "Executive Summary".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 50
            
            // Calculate totals
            let totalValue = items.compactMap { $0.value }.reduce(0, +)
            let totalPurchasePrice = items.compactMap { $0.purchasePrice }.reduce(0, +)
            let categoryCounts = Dictionary(grouping: items) { $0.category }.mapValues { $0.count }
            
            // Summary statistics
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]
            
            // Total inventory value
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            
            "Total Inventory Value: \(formatter.string(from: totalValue as NSNumber) ?? "$0")".draw(
                at: CGPoint(x: 50, y: yPosition),
                withAttributes: statsAttributes
            )
            yPosition += 30
            
            "Total Purchase Price: \(formatter.string(from: totalPurchasePrice as NSNumber) ?? "$0")".draw(
                at: CGPoint(x: 50, y: yPosition),
                withAttributes: statsAttributes
            )
            yPosition += 30
            
            "Number of Items: \(items.count)".draw(
                at: CGPoint(x: 50, y: yPosition),
                withAttributes: statsAttributes
            )
            yPosition += 30
            
            if options.coverageLimit > 0 {
                "Coverage Limit: \(formatter.string(from: options.coverageLimit as NSNumber) ?? "$0")".draw(
                    at: CGPoint(x: 50, y: yPosition),
                    withAttributes: statsAttributes
                )
                yPosition += 30
                
                let coverageStatus = totalValue <= options.coverageLimit ? "Within Limit" : "EXCEEDS LIMIT"
                let statusColor = totalValue <= options.coverageLimit ? UIColor.systemGreen : UIColor.systemRed
                
                "Coverage Status: \(coverageStatus)".draw(
                    at: CGPoint(x: 50, y: yPosition),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                        .foregroundColor: statusColor
                    ]
                )
                yPosition += 30
            }
            
            // Category breakdown
            yPosition += 20
            "Category Breakdown:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 30
            
            for (category, count) in categoryCounts.sorted(by: { $0.value > $1.value }) {
                let categoryItems = items.filter { $0.category == category }
                let categoryValue = categoryItems.compactMap { $0.value }.reduce(0, +)
                
                "\(category.rawValue): \(count) items - \(formatter.string(from: categoryValue as NSNumber) ?? "$0")".draw(
                    at: CGPoint(x: 70, y: yPosition),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.label
                    ]
                )
                yPosition += 25
            }
            
            // High value items summary
            let highValueItems = items.filter { ($0.value ?? 0) > 1000 }.sorted { ($0.value ?? 0) > ($1.value ?? 0) }
            if !highValueItems.isEmpty {
                yPosition += 30
                "High Value Items (>$1,000):".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.label
                ])
                yPosition += 30
                
                for item in highValueItems.prefix(5) {
                    let itemText = "\(item.name) - \(formatter.string(from: (item.value ?? 0) as NSNumber) ?? "$0")"
                    itemText.draw(
                        at: CGPoint(x: 70, y: yPosition),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.label
                        ]
                    )
                    yPosition += 25
                }
            }
        }
        
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func createCategoryHeaderPage(category: String, items: [Item], options: InsuranceReportOptions) -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 100
            
            // Category title
            category.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 50
            
            // Category statistics
            let totalValue = items.compactMap { $0.value }.reduce(0, +)
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            
            "Items in Category: \(items.count)".draw(
                at: CGPoint(x: 50, y: yPosition),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
            )
            yPosition += 30
            
            "Total Category Value: \(formatter.string(from: totalValue as NSNumber) ?? "$0")".draw(
                at: CGPoint(x: 50, y: yPosition),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
            )
        }
        
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func createItemDetailPage(
        item: Item,
        warranty: Core.Warranty?,
        receipt: Core.Receipt?,
        options: InsuranceReportOptions
    ) -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 50
            
            // Item name
            item.name.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 40
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            
            // Two-column layout for item details
            let leftColumn: CGFloat = 50
            let rightColumn: CGFloat = 320
            let lineHeight: CGFloat = 25
            
            // Left column details
            var leftY = yPosition
            
            if let brand = item.brand {
                "Brand: \(brand)".draw(at: CGPoint(x: leftColumn, y: leftY), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                leftY += lineHeight
            }
            
            if let model = item.model {
                "Model: \(model)".draw(at: CGPoint(x: leftColumn, y: leftY), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                leftY += lineHeight
            }
            
            if options.includeSerialNumbers, let serial = item.serialNumber {
                "Serial Number: \(serial)".draw(at: CGPoint(x: leftColumn, y: leftY), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                leftY += lineHeight
            }
            
            "Condition: \(item.condition.rawValue)".draw(at: CGPoint(x: leftColumn, y: leftY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ])
            leftY += lineHeight
            
            "Quantity: \(item.quantity)".draw(at: CGPoint(x: leftColumn, y: leftY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ])
            
            // Right column details
            var rightY = yPosition
            
            if let value = item.value {
                "Current Value: \(formatter.string(from: value as NSNumber) ?? "$0")".draw(
                    at: CGPoint(x: rightColumn, y: rightY),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: UIColor.label
                    ]
                )
                rightY += lineHeight
            }
            
            if options.includePurchaseInfo {
                if let purchasePrice = item.purchasePrice {
                    "Purchase Price: \(formatter.string(from: purchasePrice as NSNumber) ?? "$0")".draw(
                        at: CGPoint(x: rightColumn, y: rightY),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.label
                        ]
                    )
                    rightY += lineHeight
                }
                
                if let purchaseDate = item.purchaseDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    "Purchase Date: \(dateFormatter.string(from: purchaseDate))".draw(
                        at: CGPoint(x: rightColumn, y: rightY),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.label
                        ]
                    )
                    rightY += lineHeight
                }
                
                if let store = item.storeName {
                    "Purchased From: \(store)".draw(
                        at: CGPoint(x: rightColumn, y: rightY),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.label
                        ]
                    )
                    rightY += lineHeight
                }
            }
            
            yPosition = max(leftY, rightY) + 30
            
            // Warranty information
            if let warranty = warranty {
                "Warranty Information:".draw(at: CGPoint(x: leftColumn, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ])
                yPosition += lineHeight
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                "Provider: \(warranty.provider)".draw(at: CGPoint(x: leftColumn + 20, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                yPosition += lineHeight
                
                "Expires: \(dateFormatter.string(from: warranty.endDate))".draw(
                    at: CGPoint(x: leftColumn + 20, y: yPosition),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.label
                    ]
                )
                yPosition += lineHeight * 2
            }
            
            // Notes
            if let notes = item.notes, !notes.isEmpty {
                "Notes:".draw(at: CGPoint(x: leftColumn, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ])
                yPosition += lineHeight
                
                let notesRect = CGRect(x: leftColumn + 20, y: yPosition, width: pageSize.width - 120, height: 100)
                notes.draw(in: notesRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                yPosition += min(100, notes.boundingRect(
                    with: CGSize(width: pageSize.width - 120, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 12)],
                    context: nil
                ).height) + 20
            }
            
            // Receipt reference
            if options.includeReceipts && receipt != nil {
                "Receipt documentation included in appendix".draw(
                    at: CGPoint(x: leftColumn, y: yPosition),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                )
            }
        }
        
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func createReceiptsAppendix(receipts: [Core.Receipt]) -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 50
            
            "Receipt Documentation".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 50
            
            let info = """
            The following receipts are included as supporting documentation.
            Original receipt images are stored digitally and can be provided upon request.
            """
            
            let infoRect = CGRect(x: 50, y: yPosition, width: pageSize.width - 100, height: 60)
            info.draw(in: infoRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ])
            yPosition += 80
            
            // List receipts
            for receipt in receipts.sorted(by: { $0.date > $1.date }).prefix(20) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                
                let receiptText = "\(receipt.storeName) - \(dateFormatter.string(from: receipt.date)) - \(formatter.string(from: receipt.totalAmount as NSNumber) ?? "$0")"
                
                receiptText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ])
                yPosition += 25
                
                if yPosition > pageSize.height - 100 {
                    break
                }
            }
        }
        
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func createValuationMethodologyPage() -> PDFPage {
        let page = PDFPage()
        let pageSize = CGSize(width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var yPosition: CGFloat = 50
            
            "Valuation Methodology".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ])
            yPosition += 50
            
            let methodology = """
            This report uses the following valuation methods:
            
            1. Replacement Cost Value (RCV): The cost to replace the item with a new one of similar kind and quality at current market prices.
            
            2. Actual Cash Value (ACV): The replacement cost minus depreciation based on the item's age and condition.
            
            3. Market Value: The price the item would sell for in the current market, based on comparable sales.
            
            Important Notes:
            • Values are estimates based on available information
            • Professional appraisal may be required for high-value items
            • Depreciation rates vary by item category and condition
            • Market conditions can affect replacement costs
            • Some items may appreciate in value (collectibles, antiques)
            
            Disclaimer:
            This valuation is provided for insurance documentation purposes only and should not be considered a professional appraisal. Please consult with qualified appraisers and your insurance provider for official valuations.
            """
            
            let methodologyRect = CGRect(x: 50, y: yPosition, width: pageSize.width - 100, height: pageSize.height - yPosition - 100)
            methodology.draw(in: methodologyRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ])
        }
        
        if let pdfPage = PDFPage(image: image) {
            return pdfPage
        }
        
        return page
    }
    
    private func addPageNumbers(to document: PDFDocument) {
        let pageCount = document.pageCount
        
        for i in 0..<pageCount {
            guard let page = document.page(at: i) else { continue }
            
            let pageNumber = i + 1
            let text = "Page \(pageNumber) of \(pageCount)"
            
            // Get page bounds
            let pageBounds = page.bounds(for: .mediaBox)
            
            // Create annotation for page number
            let textBounds = CGRect(
                x: pageBounds.width - 100,
                y: 20,
                width: 80,
                height: 20
            )
            
            let annotation = PDFAnnotation(bounds: textBounds, forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = UIFont.systemFont(ofSize: 10)
            annotation.fontColor = .secondaryLabel
            annotation.backgroundColor = .clear
            annotation.border = PDFBorder()
            annotation.border?.lineWidth = 0
            
            page.addAnnotation(annotation)
        }
    }
    
    private func generateFileName(for type: InsuranceReportType) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let baseFileName: String
        switch type {
        case .fullInventory:
            baseFileName = "Insurance_Full_Inventory"
        case .claimDocumentation:
            baseFileName = "Insurance_Claim_Documentation"
        case .highValueItems:
            baseFileName = "Insurance_High_Value_Items"
        case .categoryBreakdown:
            baseFileName = "Insurance_Category_Breakdown"
        case .annualReview:
            baseFileName = "Insurance_Annual_Review"
        case .newPurchases:
            baseFileName = "Insurance_New_Purchases"
        }
        
        return "\(baseFileName)_\(dateString).pdf"
    }
    
    private func savePDF(_ document: PDFDocument, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(fileName)
        
        guard document.write(to: url) else {
            throw InsuranceReportError.generationFailed("Failed to save PDF document")
        }
        
        return url
    }
    
    // MARK: - Singleton
    
    public static let shared = InsuranceReportService()
    
    private init() {}
}