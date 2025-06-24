import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Service for exporting analytics data to various formats
/// Swift 5.9 - No Swift 6 features
public final class AnalyticsExportService {
    
    // MARK: - Singleton
    public static let shared = AnalyticsExportService()
    private init() {}
    
    // MARK: - Export Types
    public enum ExportFormat {
        case csv
        case json
        case pdf
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .pdf: return "pdf"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            case .pdf: return "application/pdf"
            }
        }
    }
    
    // MARK: - Time-Based Analytics Export
    
    public func exportTimeBasedAnalytics(
        _ analytics: TimeBasedAnalytics,
        format: ExportFormat = .csv
    ) async throws -> Data {
        switch format {
        case .csv:
            return try exportTimeBasedAnalyticsToCSV(analytics)
        case .json:
            return try exportTimeBasedAnalyticsToJSON(analytics)
        case .pdf:
            // PDF export would require additional dependencies
            throw ExportError.formatNotSupported
        }
    }
    
    private func exportTimeBasedAnalyticsToCSV(_ analytics: TimeBasedAnalytics) throws -> Data {
        var csv = "Time-Based Analytics Report\n"
        csv += "Period: \(analytics.period.rawValue)\n"
        csv += "Generated: \(Date().formatted())\n\n"
        
        // Summary Metrics
        csv += "Summary Metrics\n"
        csv += "Total Spent,Items Added,Average Value\n"
        csv += "\(analytics.metrics.totalSpent),\(analytics.metrics.itemsAdded),\(analytics.metrics.averageItemValue)\n\n"
        
        // Trends
        csv += "Spending Trends\n"
        csv += "Date,Amount,Label\n"
        for trend in analytics.trends {
            csv += "\(trend.date.formatted()),\(trend.value),\(trend.label)\n"
        }
        csv += "\n"
        
        // Category Breakdown
        csv += "Category Breakdown\n"
        csv += "Category,Total Spent,Item Count,Percentage\n"
        for category in analytics.metrics.categoryBreakdown {
            csv += "\(category.category.rawValue),\(category.totalSpent),\(category.itemCount),\(category.percentageOfTotal)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func exportTimeBasedAnalyticsToJSON(_ analytics: TimeBasedAnalytics) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(analytics)
    }
    
    // MARK: - Depreciation Report Export
    
    public func exportDepreciationReport(
        _ report: DepreciationReport,
        format: ExportFormat = .csv
    ) async throws -> Data {
        switch format {
        case .csv:
            return try exportDepreciationReportToCSV(report)
        case .json:
            return try exportDepreciationReportToJSON(report)
        case .pdf:
            throw ExportError.formatNotSupported
        }
    }
    
    private func exportDepreciationReportToCSV(_ report: DepreciationReport) throws -> Data {
        var csv = "Depreciation Report\n"
        csv += "Generated: \(Date().formatted())\n\n"
        
        // Summary
        csv += "Summary\n"
        csv += "Total Original Value,Total Current Value,Total Depreciation,Depreciation %\n"
        csv += "\(report.totalOriginalValue),\(report.totalCurrentValue),\(report.totalDepreciation),\(report.depreciationPercentage)\n\n"
        
        // Items
        csv += "Depreciating Items\n"
        csv += "Item,Category,Purchase Date,Purchase Price,Current Value,Depreciation,Age (Years)\n"
        for item in report.items {
            csv += "\(item.itemName),\(item.category.rawValue),\(item.purchaseDate.formatted()),\(item.purchasePrice),\(item.currentValue),\(item.depreciationAmount),\(item.ageInYears)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func exportDepreciationReportToJSON(_ report: DepreciationReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(report)
    }
    
    // MARK: - Purchase Patterns Export
    
    public func exportPurchasePatterns(
        _ patterns: PurchasePattern,
        format: ExportFormat = .csv
    ) async throws -> Data {
        switch format {
        case .csv:
            return try exportPurchasePatternsToCSV(patterns)
        case .json:
            return try exportPurchasePatternsToJSON(patterns)
        case .pdf:
            throw ExportError.formatNotSupported
        }
    }
    
    private func exportPurchasePatternsToCSV(_ patterns: PurchasePattern) throws -> Data {
        var csv = "Purchase Patterns Report\n"
        csv += "Period: \(patterns.periodAnalyzed.start.formatted()) - \(patterns.periodAnalyzed.end.formatted())\n"
        csv += "Generated: \(Date().formatted())\n\n"
        
        // Insights
        csv += "Key Insights\n"
        for insight in patterns.insights {
            csv += "\"\(insight.title)\",\"\(insight.description)\",\(insight.type.rawValue),\(insight.impact.rawValue)\n"
        }
        csv += "\n"
        
        // Recommendations
        csv += "Recommendations\n"
        for rec in patterns.recommendations {
            csv += "\"\(rec.title)\",\"\(rec.description)\",\(rec.type.rawValue),\(rec.priority.rawValue)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func exportPurchasePatternsToJSON(_ patterns: PurchasePattern) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(patterns)
    }
    
    // MARK: - File Saving
    
    public func saveToFile(
        data: Data,
        filename: String,
        format: ExportFormat
    ) throws -> URL {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let exportDirectory = documentsDirectory.appendingPathComponent("Exports")
        
        // Create exports directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true
        )
        
        let fileURL = exportDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension(format.fileExtension)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Share Sheet Support
    
    #if canImport(UIKit)
    public func presentShareSheet(
        for data: Data,
        filename: String,
        format: ExportFormat,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension(format.fileExtension)
        
        do {
            try data.write(to: temporaryURL)
            
            let activityViewController = UIActivityViewController(
                activityItems: [temporaryURL],
                applicationActivities: nil
            )
            
            // For iPad
            if let sourceView = sourceView,
               let popover = activityViewController.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            }
            
            viewController.present(activityViewController, animated: true)
        } catch {
            print("Error presenting share sheet: \(error)")
        }
    }
    #endif
}

// MARK: - Export Errors

public enum ExportError: LocalizedError {
    case formatNotSupported
    case dataConversionFailed
    case fileWriteFailed
    
    public var errorDescription: String? {
        switch self {
        case .formatNotSupported:
            return "The requested export format is not supported"
        case .dataConversionFailed:
            return "Failed to convert data to the requested format"
        case .fileWriteFailed:
            return "Failed to write the export file"
        }
    }
}