import Foundation

/// Service for exporting items to CSV files
/// Swift 5.9 - No Swift 6 features
public final class CSVExportService {
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let dateFormatter: DateFormatter
    private let currencyFormatter: NumberFormatter
    
    public init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.currencyFormatter = NumberFormatter()
        self.currencyFormatter.numberStyle = .currency
        self.currencyFormatter.locale = Locale(identifier: "en_US")
    }
    
    // MARK: - Public Methods
    
    /// Export items to CSV
    public func exportItems(
        items: [Item]? = nil,
        configuration: CSVExportConfiguration
    ) async throws -> CSVExportResult {
        let startTime = Date()
        
        // Configure formatters
        dateFormatter.dateFormat = configuration.dateFormat
        currencyFormatter.currencySymbol = configuration.currencySymbol
        
        // Get items if not provided
        let itemsToExport: [Item]
        if let items = items {
            itemsToExport = items
        } else {
            itemsToExport = try await itemRepository.fetchAll()
        }
        
        // Get locations for mapping
        let locations = try await locationRepository.fetchAll()
        let locationMap = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        
        // Sort items
        let sortedItems = sortItems(itemsToExport, configuration: configuration)
        
        // Build CSV content
        var csvLines: [String] = []
        
        // Add headers if requested
        if configuration.includeHeaders {
            let headers = buildHeaders(configuration: configuration)
            csvLines.append(headers.joined(separator: configuration.delimiter))
        }
        
        // Add data rows
        for item in sortedItems {
            let row = buildRow(
                for: item,
                configuration: configuration,
                locationMap: locationMap
            )
            csvLines.append(row.joined(separator: configuration.delimiter))
        }
        
        // Convert to data
        let csvString = csvLines.joined(separator: "\n")
        guard let data = csvString.data(using: configuration.encoding) else {
            throw CSVExportError.encodingFailed
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let fileName = generateFileName()
        
        return CSVExportResult(
            data: data,
            fileName: fileName,
            itemCount: sortedItems.count,
            fileSize: data.count,
            duration: duration
        )
    }
    
    /// Export filtered items
    public func exportFilteredItems(
        criteria: ItemSearchCriteria,
        configuration: CSVExportConfiguration
    ) async throws -> CSVExportResult {
        let items = try await itemRepository.searchWithCriteria(criteria)
        return try await exportItems(items: items, configuration: configuration)
    }
    
    /// Export items by category
    public func exportByCategory(
        category: ItemCategory,
        configuration: CSVExportConfiguration
    ) async throws -> CSVExportResult {
        let items = try await itemRepository.fetchByCategory(category)
        return try await exportItems(items: items, configuration: configuration)
    }
    
    /// Export items by location
    public func exportByLocation(
        locationId: UUID,
        configuration: CSVExportConfiguration
    ) async throws -> CSVExportResult {
        let items = try await itemRepository.fetchByLocation(locationId)
        return try await exportItems(items: items, configuration: configuration)
    }
    
    // MARK: - Private Methods
    
    private func sortItems(_ items: [Item], configuration: CSVExportConfiguration) -> [Item] {
        let sorted = items.sorted { item1, item2 in
            switch configuration.sortBy {
            case .name:
                return item1.name < item2.name
            case .category:
                return item1.category.rawValue < item2.category.rawValue
            case .purchaseDate:
                let date1 = item1.purchaseDate ?? Date.distantPast
                let date2 = item2.purchaseDate ?? Date.distantPast
                return date1 < date2
            case .purchasePrice:
                let price1 = item1.purchasePrice ?? 0
                let price2 = item2.purchasePrice ?? 0
                return price1 < price2
            case .createdAt:
                return item1.createdAt < item2.createdAt
            }
        }
        
        return configuration.sortAscending ? sorted : sorted.reversed()
    }
    
    private func buildHeaders(configuration: CSVExportConfiguration) -> [String] {
        if configuration.includeAllFields {
            return CSVExportField.allCases.map { $0.displayName }
        } else {
            return configuration.selectedFields
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.displayName }
        }
    }
    
    private func buildRow(
        for item: Item,
        configuration: CSVExportConfiguration,
        locationMap: [UUID: Location]
    ) -> [String] {
        let fields = configuration.includeAllFields ? 
            CSVExportField.allCases : 
            Array(configuration.selectedFields).sorted { $0.rawValue < $1.rawValue }
        
        return fields.map { field in
            formatValue(for: field, item: item, locationMap: locationMap)
        }
    }
    
    private func formatValue(
        for field: CSVExportField,
        item: Item,
        locationMap: [UUID: Location]
    ) -> String {
        switch field {
        case .name:
            return escapeCSVValue(item.name)
            
        case .brand:
            return escapeCSVValue(item.brand ?? "")
            
        case .model:
            return escapeCSVValue(item.model ?? "")
            
        case .serialNumber:
            return escapeCSVValue(item.serialNumber ?? "")
            
        case .barcode:
            return escapeCSVValue(item.barcode ?? "")
            
        case .category:
            return item.category.displayName
            
        case .location:
            if let locationId = item.locationId,
               let location = locationMap[locationId] {
                return escapeCSVValue(location.name)
            }
            return ""
            
        case .storeName:
            return escapeCSVValue(item.storeName ?? "")
            
        case .purchaseDate:
            if let date = item.purchaseDate {
                return dateFormatter.string(from: date)
            }
            return ""
            
        case .purchasePrice:
            if let price = item.purchasePrice {
                return currencyFormatter.string(from: NSDecimalNumber(decimal: price)) ?? String(describing: price)
            }
            return ""
            
        case .quantity:
            return String(item.quantity)
            
        case .condition:
            return item.condition.displayName
            
        case .warrantyEndDate:
            // TODO: Implement when warrantyEndDate is added to Item model
            return ""
            
        case .tags:
            return escapeCSVValue(item.tags.joined(separator: ", "))
            
        case .notes:
            return escapeCSVValue(item.notes ?? "")
            
        case .createdAt:
            return dateFormatter.string(from: item.createdAt)
            
        case .updatedAt:
            return dateFormatter.string(from: item.updatedAt)
        }
    }
    
    private func escapeCSVValue(_ value: String) -> String {
        // Check if value needs escaping
        if value.contains("\"") || value.contains(",") || value.contains("\n") || value.contains("\r") {
            // Escape quotes by doubling them
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
    
    private func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "inventory_export_\(timestamp).csv"
    }
}

/// CSV export errors
public enum CSVExportError: LocalizedError {
    case encodingFailed
    case noItemsToExport
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode CSV data"
        case .noItemsToExport:
            return "No items to export"
        }
    }
}