import Foundation

/// CSV import configuration
/// Swift 5.9 - No Swift 6 features
public struct CSVImportConfiguration: Codable {
    public let delimiter: String
    public let hasHeaders: Bool
    public let encodingName: String // Store encoding name instead of String.Encoding
    public let dateFormat: String
    public let currencySymbol: String
    public let columnMapping: CSVColumnMapping
    
    public var encoding: String.Encoding {
        switch encodingName {
        case "utf8": return .utf8
        case "utf16": return .utf16
        case "iso2022JP": return .iso2022JP
        case "isoLatin1": return .isoLatin1
        case "windowsCP1252": return .windowsCP1252
        default: return .utf8
        }
    }
    
    public init(
        delimiter: String = ",",
        hasHeaders: Bool = true,
        encoding: String.Encoding = .utf8,
        dateFormat: String = "yyyy-MM-dd",
        currencySymbol: String = "$",
        columnMapping: CSVColumnMapping = CSVColumnMapping()
    ) {
        self.delimiter = delimiter
        self.hasHeaders = hasHeaders
        
        // Convert encoding to string name
        switch encoding {
        case .utf8: self.encodingName = "utf8"
        case .utf16: self.encodingName = "utf16"
        case .iso2022JP: self.encodingName = "iso2022JP"
        case .isoLatin1: self.encodingName = "isoLatin1"
        case .windowsCP1252: self.encodingName = "windowsCP1252"
        default: self.encodingName = "utf8"
        }
        
        self.dateFormat = dateFormat
        self.currencySymbol = currencySymbol
        self.columnMapping = columnMapping
    }
}

/// CSV column mapping
public struct CSVColumnMapping: Codable {
    public var name: Int?
    public var brand: Int?
    public var model: Int?
    public var serialNumber: Int?
    public var barcode: Int?
    public var category: Int?
    public var location: Int?
    public var storeName: Int?
    public var purchaseDate: Int?
    public var purchasePrice: Int?
    public var quantity: Int?
    public var notes: Int?
    public var tags: Int?
    public var warrantyEndDate: Int?
    public var condition: Int?
    
    public init() {}
    
    public func isValid() -> Bool {
        // At minimum, need a name column
        return name != nil
    }
}

/// CSV import result
public struct CSVImportResult {
    public let totalRows: Int
    public let successfulImports: Int
    public let failedImports: Int
    public let errors: [CSVImportError]
    public let importedItems: [Item]
    public let duplicateItems: [Item]
    public let duration: TimeInterval
    
    public var successRate: Double {
        guard totalRows > 0 else { return 0 }
        return Double(successfulImports) / Double(totalRows)
    }
    
    public init(
        totalRows: Int,
        successfulImports: Int,
        failedImports: Int,
        errors: [CSVImportError],
        importedItems: [Item],
        duplicateItems: [Item],
        duration: TimeInterval
    ) {
        self.totalRows = totalRows
        self.successfulImports = successfulImports
        self.failedImports = failedImports
        self.errors = errors
        self.importedItems = importedItems
        self.duplicateItems = duplicateItems
        self.duration = duration
    }
}

/// CSV import error
public struct CSVImportError: Error, Identifiable {
    public let id = UUID()
    public let row: Int
    public let column: String?
    public let value: String?
    public let reason: CSVImportErrorReason
    public let description: String
    
    public init(
        row: Int,
        column: String? = nil,
        value: String? = nil,
        reason: CSVImportErrorReason,
        description: String
    ) {
        self.row = row
        self.column = column
        self.value = value
        self.reason = reason
        self.description = description
    }
}

/// CSV import error reasons
public enum CSVImportErrorReason: String, Codable {
    case missingRequiredField = "Missing Required Field"
    case invalidDateFormat = "Invalid Date Format"
    case invalidNumberFormat = "Invalid Number Format"
    case invalidCategory = "Invalid Category"
    case invalidLocation = "Invalid Location"
    case duplicateItem = "Duplicate Item"
    case parsingError = "Parsing Error"
    case unknown = "Unknown Error"
}

/// CSV preview data
public struct CSVPreviewData {
    public let headers: [String]
    public let rows: [[String]]
    public let totalRows: Int
    public let hasHeaders: Bool
    
    public init(
        headers: [String],
        rows: [[String]],
        totalRows: Int,
        hasHeaders: Bool
    ) {
        self.headers = headers
        self.rows = rows
        self.totalRows = totalRows
        self.hasHeaders = hasHeaders
    }
}

/// CSV import template
public struct CSVImportTemplate: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let configuration: CSVImportConfiguration
    public let sampleData: String
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        configuration: CSVImportConfiguration,
        sampleData: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.configuration = configuration
        self.sampleData = sampleData
        self.createdAt = createdAt
    }
}

/// Default CSV templates
public extension CSVImportTemplate {
    static let basic = CSVImportTemplate(
        name: "Basic Inventory",
        description: "Simple item list with essential fields",
        configuration: CSVImportConfiguration(
            columnMapping: {
                var mapping = CSVColumnMapping()
                mapping.name = 0
                mapping.category = 1
                mapping.quantity = 2
                mapping.purchasePrice = 3
                mapping.purchaseDate = 4
                return mapping
            }()
        ),
        sampleData: """
Name,Category,Quantity,Price,Purchase Date
iPhone 13 Pro,Electronics,1,999.00,2023-09-15
Coffee Maker,Appliances,1,149.99,2023-08-20
Desk Chair,Furniture,1,299.00,2023-07-10
"""
    )
    
    static let detailed = CSVImportTemplate(
        name: "Detailed Inventory",
        description: "Comprehensive item tracking with all fields",
        configuration: CSVImportConfiguration(
            columnMapping: {
                var mapping = CSVColumnMapping()
                mapping.name = 0
                mapping.brand = 1
                mapping.model = 2
                mapping.serialNumber = 3
                mapping.barcode = 4
                mapping.category = 5
                mapping.location = 6
                mapping.storeName = 7
                mapping.purchaseDate = 8
                mapping.purchasePrice = 9
                mapping.quantity = 10
                mapping.condition = 11
                mapping.warrantyEndDate = 12
                mapping.tags = 13
                mapping.notes = 14
                return mapping
            }()
        ),
        sampleData: """
Name,Brand,Model,Serial Number,Barcode,Category,Location,Store,Purchase Date,Price,Quantity,Condition,Warranty End,Tags,Notes
iPhone 13 Pro,Apple,A2638,F2LXX1234,190199999999,Electronics,Office,Apple Store,2023-09-15,999.00,1,New,2024-09-15,"phone,work",128GB Space Gray
Coffee Maker,Breville,BES870XL,BRV123456,987654321012,Appliances,Kitchen,Amazon,2023-08-20,149.99,1,New,2025-08-20,"kitchen,coffee",Barista Express
"""
    )
    
    static let allTemplates = [basic, detailed]
}