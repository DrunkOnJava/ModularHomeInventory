import Foundation

/// Service for importing items from CSV files
/// Swift 5.9 - No Swift 6 features
public final class CSVImportService {
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter
    
    public init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.locale = Locale(identifier: "en_US")
    }
    
    // MARK: - Public Methods
    
    /// Preview CSV file without importing
    public func previewCSV(
        data: Data,
        configuration: CSVImportConfiguration
    ) throws -> CSVPreviewData {
        guard let csvString = String(data: data, encoding: configuration.encoding) else {
            throw CSVImportError(
                row: 0,
                reason: .parsingError,
                description: "Unable to decode file with specified encoding"
            )
        }
        
        let rows = parseCSV(csvString, delimiter: configuration.delimiter)
        guard !rows.isEmpty else {
            throw CSVImportError(
                row: 0,
                reason: .parsingError,
                description: "CSV file is empty"
            )
        }
        
        let headers = configuration.hasHeaders ? rows[0] : generateHeaders(columnCount: rows[0].count)
        let dataRows = configuration.hasHeaders ? Array(rows.dropFirst()) : rows
        let previewRows = Array(dataRows.prefix(10))
        
        return CSVPreviewData(
            headers: headers,
            rows: previewRows,
            totalRows: dataRows.count,
            hasHeaders: configuration.hasHeaders
        )
    }
    
    /// Import items from CSV data
    public func importCSV(
        data: Data,
        configuration: CSVImportConfiguration,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> CSVImportResult {
        let startTime = Date()
        
        guard let csvString = String(data: data, encoding: configuration.encoding) else {
            throw CSVImportError(
                row: 0,
                reason: .parsingError,
                description: "Unable to decode file with specified encoding"
            )
        }
        
        // Configure formatters
        dateFormatter.dateFormat = configuration.dateFormat
        numberFormatter.currencySymbol = configuration.currencySymbol
        
        // Parse CSV
        let rows = parseCSV(csvString, delimiter: configuration.delimiter)
        guard !rows.isEmpty else {
            throw CSVImportError(
                row: 0,
                reason: .parsingError,
                description: "CSV file is empty"
            )
        }
        
        // Skip header if present
        let dataRows = configuration.hasHeaders ? Array(rows.dropFirst()) : rows
        let totalRows = dataRows.count
        
        var importedItems: [Item] = []
        var duplicateItems: [Item] = []
        var errors: [CSVImportError] = []
        var successCount = 0
        
        // Get existing locations
        let existingLocations = try await locationRepository.fetchAll()
        
        // Process each row
        for (index, row) in dataRows.enumerated() {
            let rowNumber = configuration.hasHeaders ? index + 2 : index + 1
            
            do {
                let item = try parseItem(
                    from: row,
                    rowNumber: rowNumber,
                    configuration: configuration,
                    existingLocations: existingLocations
                )
                
                // Check for duplicates
                if let existingItem = try await checkForDuplicate(item) {
                    duplicateItems.append(existingItem)
                    errors.append(CSVImportError(
                        row: rowNumber,
                        reason: .duplicateItem,
                        description: "Item '\(item.name)' already exists"
                    ))
                } else {
                    // Save item
                    try await itemRepository.save(item)
                    importedItems.append(item)
                    successCount += 1
                }
            } catch let error as CSVImportError {
                errors.append(error)
            } catch {
                errors.append(CSVImportError(
                    row: rowNumber,
                    reason: .unknown,
                    description: error.localizedDescription
                ))
            }
            
            // Report progress
            let progress = Double(index + 1) / Double(totalRows)
            progressHandler?(progress)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return CSVImportResult(
            totalRows: totalRows,
            successfulImports: successCount,
            failedImports: totalRows - successCount,
            errors: errors,
            importedItems: importedItems,
            duplicateItems: duplicateItems,
            duration: duration
        )
    }
    
    /// Export template CSV
    public func exportTemplate(_ template: CSVImportTemplate) -> Data? {
        return template.sampleData.data(using: .utf8)
    }
    
    // MARK: - Private Methods
    
    private func parseCSV(_ csv: String, delimiter: String) -> [[String]] {
        var rows: [[String]] = []
        let lines = csv.components(separatedBy: .newlines)
        
        for line in lines {
            if line.isEmpty { continue }
            
            // Simple CSV parsing - handles basic cases
            // For production, consider using a robust CSV parsing library
            let columns = parseCSVLine(line, delimiter: delimiter)
            rows.append(columns)
        }
        
        return rows
    }
    
    private func parseCSVLine(_ line: String, delimiter: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        let characters = Array(line)
        
        for i in 0..<characters.count {
            let char = characters[i]
            
            if char == "\"" {
                if insideQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    // Escaped quote
                    currentColumn.append("\"")
                    continue
                }
                insideQuotes.toggle()
            } else if String(char) == delimiter && !insideQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        
        // Add the last column
        columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
        
        return columns
    }
    
    private func generateHeaders(columnCount: Int) -> [String] {
        return (0..<columnCount).map { "Column \($0 + 1)" }
    }
    
    private func parseItem(
        from row: [String],
        rowNumber: Int,
        configuration: CSVImportConfiguration,
        existingLocations: [Location]
    ) throws -> Item {
        let mapping = configuration.columnMapping
        
        // Parse required fields
        guard let nameIndex = mapping.name,
              nameIndex < row.count,
              !row[nameIndex].isEmpty else {
            throw CSVImportError(
                row: rowNumber,
                column: "Name",
                reason: .missingRequiredField,
                description: "Name is required"
            )
        }
        
        let name = row[nameIndex]
        
        // Parse optional fields
        var item = Item(name: name)
        
        // Brand
        if let index = mapping.brand, index < row.count, !row[index].isEmpty {
            item.brand = row[index]
        }
        
        // Model
        if let index = mapping.model, index < row.count, !row[index].isEmpty {
            item.model = row[index]
        }
        
        // Serial Number
        if let index = mapping.serialNumber, index < row.count, !row[index].isEmpty {
            item.serialNumber = row[index]
        }
        
        // Barcode
        if let index = mapping.barcode, index < row.count, !row[index].isEmpty {
            item.barcode = row[index]
        }
        
        // Category
        if let index = mapping.category, index < row.count, !row[index].isEmpty {
            let categoryString = row[index]
            if let category = ItemCategory.allCases.first(where: { 
                $0.rawValue.lowercased() == categoryString.lowercased() ||
                $0.displayName.lowercased() == categoryString.lowercased()
            }) {
                item.category = category
            } else {
                throw CSVImportError(
                    row: rowNumber,
                    column: "Category",
                    value: categoryString,
                    reason: .invalidCategory,
                    description: "Invalid category: \(categoryString)"
                )
            }
        }
        
        // Location
        if let index = mapping.location, index < row.count, !row[index].isEmpty {
            let locationName = row[index]
            if let location = existingLocations.first(where: { 
                $0.name.lowercased() == locationName.lowercased() 
            }) {
                item.locationId = location.id
            } else {
                // Create new location
                let newLocation = Location(name: locationName)
                do {
                    try await locationRepository.save(newLocation)
                    item.locationId = newLocation.id
                } catch {
                    // Location creation failed, continue without location
                }
            }
        }
        
        // Store Name
        if let index = mapping.storeName, index < row.count, !row[index].isEmpty {
            item.storeName = row[index]
        }
        
        // Purchase Date
        if let index = mapping.purchaseDate, index < row.count, !row[index].isEmpty {
            let dateString = row[index]
            if let date = dateFormatter.date(from: dateString) {
                item.purchaseDate = date
            } else {
                throw CSVImportError(
                    row: rowNumber,
                    column: "Purchase Date",
                    value: dateString,
                    reason: .invalidDateFormat,
                    description: "Invalid date format: \(dateString)"
                )
            }
        }
        
        // Purchase Price
        if let index = mapping.purchasePrice, index < row.count, !row[index].isEmpty {
            let priceString = row[index].replacingOccurrences(of: configuration.currencySymbol, with: "")
            if let number = numberFormatter.number(from: priceString) {
                item.purchasePrice = Decimal(number.doubleValue)
            } else if let doubleValue = Double(priceString) {
                item.purchasePrice = Decimal(doubleValue)
            } else {
                throw CSVImportError(
                    row: rowNumber,
                    column: "Purchase Price",
                    value: row[index],
                    reason: .invalidNumberFormat,
                    description: "Invalid price format: \(row[index])"
                )
            }
        }
        
        // Quantity
        if let index = mapping.quantity, index < row.count, !row[index].isEmpty {
            if let quantity = Int(row[index]) {
                item.quantity = quantity
            } else {
                throw CSVImportError(
                    row: rowNumber,
                    column: "Quantity",
                    value: row[index],
                    reason: .invalidNumberFormat,
                    description: "Invalid quantity: \(row[index])"
                )
            }
        }
        
        // Notes
        if let index = mapping.notes, index < row.count, !row[index].isEmpty {
            item.notes = row[index]
        }
        
        // Tags
        if let index = mapping.tags, index < row.count, !row[index].isEmpty {
            let tagsString = row[index]
            let tags = tagsString
                .components(separatedBy: CharacterSet(charactersIn: ",;|"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if !tags.isEmpty {
                item.tags = tags
            }
        }
        
        // Warranty End Date - skip for now since Item doesn't have this property
        // TODO: Create warranty record when warranty end date is provided
        
        // Condition
        if let index = mapping.condition, index < row.count, !row[index].isEmpty {
            let conditionString = row[index]
            if let condition = ItemCondition.allCases.first(where: { 
                $0.rawValue.lowercased() == conditionString.lowercased() ||
                $0.displayName.lowercased() == conditionString.lowercased()
            }) {
                item.condition = condition
            }
        }
        
        return item
    }
    
    private func checkForDuplicate(_ item: Item) async throws -> Item? {
        // Check by barcode first
        if let barcode = item.barcode {
            if let existing = try await itemRepository.fetchByBarcode(barcode) {
                return existing
            }
        }
        
        // Check by name and brand
        let allItems = try await itemRepository.fetchAll()
        return allItems.first { existing in
            existing.name.lowercased() == item.name.lowercased() &&
            existing.brand?.lowercased() == item.brand?.lowercased() &&
            existing.model?.lowercased() == item.model?.lowercased()
        }
    }
}