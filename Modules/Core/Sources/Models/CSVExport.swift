import Foundation

/// CSV export configuration
/// Swift 5.9 - No Swift 6 features
public struct CSVExportConfiguration: Codable {
    public let delimiter: String
    public let includeHeaders: Bool
    public let encoding: String.Encoding
    public let dateFormat: String
    public let currencySymbol: String
    public let includeAllFields: Bool
    public let selectedFields: Set<CSVExportField>
    public let sortBy: CSVExportSortField
    public let sortAscending: Bool
    
    public init(
        delimiter: String = ",",
        includeHeaders: Bool = true,
        encoding: String.Encoding = .utf8,
        dateFormat: String = "yyyy-MM-dd",
        currencySymbol: String = "$",
        includeAllFields: Bool = true,
        selectedFields: Set<CSVExportField> = [],
        sortBy: CSVExportSortField = .name,
        sortAscending: Bool = true
    ) {
        self.delimiter = delimiter
        self.includeHeaders = includeHeaders
        self.encoding = encoding
        self.dateFormat = dateFormat
        self.currencySymbol = currencySymbol
        self.includeAllFields = includeAllFields
        self.selectedFields = selectedFields
        self.sortBy = sortBy
        self.sortAscending = sortAscending
    }
}

/// CSV export fields
public enum CSVExportField: String, Codable, CaseIterable {
    case name = "Name"
    case brand = "Brand"
    case model = "Model"
    case serialNumber = "Serial Number"
    case barcode = "Barcode"
    case category = "Category"
    case location = "Location"
    case storeName = "Store"
    case purchaseDate = "Purchase Date"
    case purchasePrice = "Price"
    case quantity = "Quantity"
    case condition = "Condition"
    case warrantyEndDate = "Warranty End"
    case tags = "Tags"
    case notes = "Notes"
    case createdAt = "Created Date"
    case updatedAt = "Updated Date"
    
    public var displayName: String { rawValue }
}

/// CSV export sort fields
public enum CSVExportSortField: String, Codable, CaseIterable {
    case name = "Name"
    case category = "Category"
    case purchaseDate = "Purchase Date"
    case purchasePrice = "Price"
    case createdAt = "Created Date"
    
    public var displayName: String { rawValue }
}

/// CSV export result
public struct CSVExportResult {
    public let data: Data
    public let fileName: String
    public let itemCount: Int
    public let fileSize: Int
    public let duration: TimeInterval
    
    public var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    public init(
        data: Data,
        fileName: String,
        itemCount: Int,
        fileSize: Int,
        duration: TimeInterval
    ) {
        self.data = data
        self.fileName = fileName
        self.itemCount = itemCount
        self.fileSize = fileSize
        self.duration = duration
    }
}

/// CSV export template
public struct CSVExportTemplate: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let configuration: CSVExportConfiguration
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        configuration: CSVExportConfiguration,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.configuration = configuration
        self.createdAt = createdAt
    }
}

/// Default export templates
public extension CSVExportTemplate {
    static let basic = CSVExportTemplate(
        name: "Basic Export",
        description: "Essential item information",
        configuration: CSVExportConfiguration(
            includeAllFields: false,
            selectedFields: [
                .name, .category, .quantity, .purchasePrice, .purchaseDate
            ]
        )
    )
    
    static let full = CSVExportTemplate(
        name: "Full Export",
        description: "All item fields",
        configuration: CSVExportConfiguration(
            includeAllFields: true
        )
    )
    
    static let financial = CSVExportTemplate(
        name: "Financial Export",
        description: "Purchase and value information",
        configuration: CSVExportConfiguration(
            includeAllFields: false,
            selectedFields: [
                .name, .brand, .category, .purchaseDate, .purchasePrice, 
                .quantity, .storeName, .warrantyEndDate
            ],
            sortBy: .purchaseDate,
            sortAscending: false
        )
    )
    
    static let inventory = CSVExportTemplate(
        name: "Inventory List",
        description: "Current inventory status",
        configuration: CSVExportConfiguration(
            includeAllFields: false,
            selectedFields: [
                .name, .brand, .model, .serialNumber, .category, 
                .location, .quantity, .condition
            ],
            sortBy: .category
        )
    )
    
    static let allTemplates = [basic, full, financial, inventory]
}