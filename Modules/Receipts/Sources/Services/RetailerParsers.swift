import Foundation
import Core

/// Protocol for retailer-specific receipt parsers
protocol RetailerParser {
    var retailerName: String { get }
    func canParse(_ text: String) -> Bool
    func parse(_ text: String) -> ParsedReceiptData?
}

/// Parser for Target receipts
struct TargetParser: RetailerParser {
    let retailerName = "Target"
    
    func canParse(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return upperText.contains("TARGET") && 
               (upperText.contains("CORPORATION") || upperText.contains("STORE"))
    }
    
    func parse(_ text: String) -> ParsedReceiptData? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var storeName = "Target"
        var date: Date?
        var totalAmount: Decimal?
        var items: [ParsedReceiptItem] = []
        
        // Find store number
        for line in lines {
            if line.contains("STORE #") || line.contains("Store #") {
                storeName = "Target " + line
                break
            }
        }
        
        // Parse date - Target format: MM/DD/YY HH:MM
        let dateRegex = try? NSRegularExpression(pattern: "\\d{2}/\\d{2}/\\d{2}\\s+\\d{2}:\\d{2}", options: [])
        for line in lines {
            if let match = dateRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let dateString = (line as NSString).substring(with: match.range)
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy HH:mm"
                date = formatter.date(from: dateString)
                break
            }
        }
        
        // Parse items and total
        let priceRegex = try? NSRegularExpression(pattern: "\\$?\\d+\\.\\d{2}", options: [])
        var inItemsSection = false
        
        for (_, line) in lines.enumerated() {
            let upperLine = line.uppercased()
            
            // Check for total
            if upperLine.contains("TOTAL") && !upperLine.contains("SUBTOTAL") {
                if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                    totalAmount = Decimal(string: priceString)
                }
            }
            
            // Parse items - Target items often have SKU numbers
            if line.contains("#") && priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) != nil {
                inItemsSection = true
            }
            
            if inItemsSection && !upperLine.contains("TOTAL") && !upperLine.contains("TAX") {
                if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                    
                    if let price = Decimal(string: priceString) {
                        // Get item name - everything before the price
                        let beforePrice = line.prefix(match.range.location)
                            .trimmingCharacters(in: .whitespaces)
                        
                        // Remove SKU if present
                        let itemName = beforePrice
                            .replacingOccurrences(of: #"#\d+"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                        
                        if !itemName.isEmpty {
                            let item = ParsedReceiptItem(
                                name: itemName,
                                quantity: 1,
                                price: price,
                                category: categorizeTargetItem(itemName)
                            )
                            items.append(item)
                        }
                    }
                }
            }
        }
        
        return ParsedReceiptData(
            storeName: storeName,
            date: date ?? Date(),
            totalAmount: totalAmount ?? 0,
            items: items,
            confidence: 0.85
        )
    }
    
    private func categorizeTargetItem(_ name: String) -> ItemCategory? {
        let upperName = name.uppercased()
        
        if upperName.contains("GROCERY") || upperName.contains("FOOD") {
            return .kitchen
        } else if upperName.contains("ELECTRONIC") || upperName.contains("TECH") {
            return .electronics
        } else if upperName.contains("CLOTHING") || upperName.contains("APPAREL") {
            return .clothing
        } else if upperName.contains("HOME") || upperName.contains("DECOR") {
            return .home
        } else if upperName.contains("TOY") || upperName.contains("GAME") {
            return .toys
        }
        
        return .other
    }
}

/// Parser for Walmart receipts
struct WalmartParser: RetailerParser {
    let retailerName = "Walmart"
    
    func canParse(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return upperText.contains("WALMART") || upperText.contains("WAL-MART")
    }
    
    func parse(_ text: String) -> ParsedReceiptData? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var storeName = "Walmart"
        var date: Date?
        var totalAmount: Decimal?
        var items: [ParsedReceiptItem] = []
        
        // Find store details
        for line in lines.prefix(10) {
            if line.uppercased().contains("WALMART") {
                storeName = line
                break
            }
        }
        
        // Parse date - Walmart format varies
        let datePatterns = [
            ("MM/dd/yy", #"\d{2}/\d{2}/\d{2}"#),
            ("MM/dd/yyyy", #"\d{2}/\d{2}/\d{4}"#)
        ]
        
        for line in lines {
            for (format, pattern) in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let dateString = (line as NSString).substring(with: match.range)
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let parsedDate = formatter.date(from: dateString) {
                        date = parsedDate
                        break
                    }
                }
            }
            if date != nil { break }
        }
        
        // Parse items and total
        let priceRegex = try? NSRegularExpression(pattern: "\\d+\\.\\d{2}", options: [])
        
        for line in lines {
            let upperLine = line.uppercased()
            
            // Check for total
            if upperLine.contains("TOTAL") && !upperLine.contains("SUBTOTAL") {
                if let match = priceRegex?.matches(in: line, options: [], range: NSRange(location: 0, length: line.count)).last {
                    let priceString = (line as NSString).substring(with: match.range)
                    totalAmount = Decimal(string: priceString)
                }
            }
            
            // Parse items - Walmart often has item codes
            if !upperLine.contains("TOTAL") && !upperLine.contains("TAX") && !upperLine.contains("CHANGE") {
                if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let priceString = (line as NSString).substring(with: match.range)
                    
                    if let price = Decimal(string: priceString), price > 0 {
                        let beforePrice = line.prefix(match.range.location)
                            .trimmingCharacters(in: .whitespaces)
                        
                        // Remove common Walmart prefixes
                        var itemName = beforePrice
                            .replacingOccurrences(of: #"^\d+\s+"#, with: "", options: .regularExpression)
                            .replacingOccurrences(of: #"\s+\d{12}$"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                        
                        if !itemName.isEmpty && itemName.count > 2 {
                            let item = ParsedReceiptItem(
                                name: itemName,
                                quantity: 1,
                                price: price
                            )
                            items.append(item)
                        }
                    }
                }
            }
        }
        
        return ParsedReceiptData(
            storeName: storeName,
            date: date ?? Date(),
            totalAmount: totalAmount ?? 0,
            items: items,
            confidence: 0.8
        )
    }
}

/// Parser for Amazon receipts/invoices
struct AmazonParser: RetailerParser {
    let retailerName = "Amazon"
    
    func canParse(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return upperText.contains("AMAZON") && 
               (upperText.contains("ORDER") || upperText.contains("INVOICE"))
    }
    
    func parse(_ text: String) -> ParsedReceiptData? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var date: Date?
        var totalAmount: Decimal?
        var items: [ParsedReceiptItem] = []
        var orderNumber: String?
        
        // Find order number
        for line in lines {
            if line.contains("Order #") || line.contains("Order Number") {
                orderNumber = line.replacingOccurrences(of: "Order #", with: "")
                    .replacingOccurrences(of: "Order Number", with: "")
                    .trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Parse date - Amazon uses various formats
        let datePatterns = [
            ("MMMM d, yyyy", #"[A-Za-z]+ \d{1,2}, \d{4}"#),
            ("MMM d, yyyy", #"[A-Za-z]{3} \d{1,2}, \d{4}"#)
        ]
        
        for line in lines {
            for (format, pattern) in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let dateString = (line as NSString).substring(with: match.range)
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let parsedDate = formatter.date(from: dateString) {
                        date = parsedDate
                        break
                    }
                }
            }
            if date != nil { break }
        }
        
        // Parse total and items
        let priceRegex = try? NSRegularExpression(pattern: "\\$\\d+\\.\\d{2}", options: [])
        
        for (index, line) in lines.enumerated() {
            // Check for order total
            if line.contains("Order Total") || line.contains("Grand Total") {
                if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                    totalAmount = Decimal(string: priceString)
                }
            }
            
            // Parse items - look for price patterns
            if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let priceString = (line as NSString).substring(with: match.range)
                    .replacingOccurrences(of: "$", with: "")
                
                if let price = Decimal(string: priceString), price > 0 {
                    // Check if this is an item line (not total, tax, shipping)
                    let lowerLine = line.lowercased()
                    if !lowerLine.contains("total") && !lowerLine.contains("tax") && 
                       !lowerLine.contains("shipping") && !lowerLine.contains("discount") {
                        
                        // Item name might be on the same line or the line before
                        var itemName = line.prefix(match.range.location)
                            .trimmingCharacters(in: .whitespaces)
                        
                        if itemName.isEmpty && index > 0 {
                            itemName = lines[index - 1]
                        }
                        
                        if !itemName.isEmpty {
                            let item = ParsedReceiptItem(
                                name: itemName,
                                quantity: 1,
                                price: price,
                                category: .other
                            )
                            items.append(item)
                        }
                    }
                }
            }
        }
        
        let storeName = orderNumber != nil ? "Amazon (Order: \(orderNumber!))" : "Amazon"
        
        return ParsedReceiptData(
            storeName: storeName,
            date: date ?? Date(),
            totalAmount: totalAmount ?? 0,
            items: items,
            confidence: 0.75
        )
    }
}

/// Parser for Apple Store receipts
struct AppleStoreParser: RetailerParser {
    let retailerName = "Apple"
    
    func canParse(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return upperText.contains("APPLE STORE") || 
               (upperText.contains("APPLE") && upperText.contains("RECEIPT"))
    }
    
    func parse(_ text: String) -> ParsedReceiptData? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var storeName = "Apple Store"
        var date: Date?
        var totalAmount: Decimal?
        var items: [ParsedReceiptItem] = []
        
        // Find store location
        for line in lines.prefix(10) {
            if line.contains("Apple Store") {
                storeName = line
                break
            }
        }
        
        // Parse date
        let dateRegex = try? NSRegularExpression(pattern: "\\d{2}/\\d{2}/\\d{4}", options: [])
        for line in lines {
            if let match = dateRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let dateString = (line as NSString).substring(with: match.range)
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                date = formatter.date(from: dateString)
                break
            }
        }
        
        // Parse items and total
        let priceRegex = try? NSRegularExpression(pattern: "\\$[\\d,]+\\.\\d{2}", options: [])
        
        for line in lines {
            let upperLine = line.uppercased()
            
            if upperLine.contains("TOTAL") && !upperLine.contains("SUBTOTAL") {
                if let match = priceRegex?.matches(in: line, options: [], range: NSRange(location: 0, length: line.count)).last {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: ",", with: "")
                    totalAmount = Decimal(string: priceString)
                }
            }
            
            // Apple products often have specific patterns
            if (line.contains("iPhone") || line.contains("iPad") || line.contains("Mac") || 
                line.contains("AirPods") || line.contains("Apple Watch")) {
                if let match = priceRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: ",", with: "")
                    
                    if let price = Decimal(string: priceString) {
                        let itemName = line.prefix(match.range.location)
                            .trimmingCharacters(in: .whitespaces)
                        
                        let item = ParsedReceiptItem(
                            name: itemName,
                            quantity: 1,
                            price: price,
                            category: .electronics
                        )
                        items.append(item)
                    }
                }
            }
        }
        
        return ParsedReceiptData(
            storeName: storeName,
            date: date ?? Date(),
            totalAmount: totalAmount ?? 0,
            items: items,
            confidence: 0.9
        )
    }
}

/// Parser for Best Buy receipts
struct BestBuyParser: RetailerParser {
    let retailerName = "Best Buy"
    
    func canParse(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return upperText.contains("BEST BUY") || upperText.contains("BESTBUY")
    }
    
    func parse(_ text: String) -> ParsedReceiptData? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var storeName = "Best Buy"
        var date: Date?
        var totalAmount: Decimal?
        var items: [ParsedReceiptItem] = []
        
        // Parse store number
        for line in lines {
            if line.contains("Store") && line.contains("#") {
                storeName = "Best Buy " + line
                break
            }
        }
        
        // Parse date and items
        let priceRegex = try? NSRegularExpression(pattern: "\\d+\\.\\d{2}", options: [])
        let skuRegex = try? NSRegularExpression(pattern: "SKU:\\s*\\d+", options: [])
        
        for (index, line) in lines.enumerated() {
            // Date parsing
            if line.contains("/") && date == nil {
                let dateRegex = try? NSRegularExpression(pattern: "\\d{2}/\\d{2}/\\d{2,4}", options: [])
                if let match = dateRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                    let dateString = (line as NSString).substring(with: match.range)
                    let formatter = DateFormatter()
                    formatter.dateFormat = dateString.count == 8 ? "MM/dd/yy" : "MM/dd/yyyy"
                    date = formatter.date(from: dateString)
                }
            }
            
            // Total
            if line.uppercased().contains("TOTAL") && !line.uppercased().contains("SUBTOTAL") {
                if let match = priceRegex?.matches(in: line, options: [], range: NSRange(location: 0, length: line.count)).last {
                    let priceString = (line as NSString).substring(with: match.range)
                    totalAmount = Decimal(string: priceString)
                }
            }
            
            // Items - Best Buy often shows SKU on separate line
            if skuRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) != nil {
                // Item name is usually on the line before SKU
                if index > 0 {
                    let itemLine = lines[index - 1]
                    if let priceMatch = priceRegex?.firstMatch(in: itemLine, options: [], range: NSRange(location: 0, length: itemLine.count)) {
                        let priceString = (itemLine as NSString).substring(with: priceMatch.range)
                        if let price = Decimal(string: priceString) {
                            let itemName = itemLine.prefix(priceMatch.range.location)
                                .trimmingCharacters(in: .whitespaces)
                            
                            let item = ParsedReceiptItem(
                                name: itemName,
                                quantity: 1,
                                price: price,
                                category: .electronics
                            )
                            items.append(item)
                        }
                    }
                }
            }
        }
        
        return ParsedReceiptData(
            storeName: storeName,
            date: date ?? Date(),
            totalAmount: totalAmount ?? 0,
            items: items,
            confidence: 0.8
        )
    }
}

/// Main receipt parser that delegates to retailer-specific parsers
public struct EnhancedReceiptParser {
    private let parsers: [RetailerParser] = [
        TargetParser(),
        WalmartParser(),
        AmazonParser(),
        AppleStoreParser(),
        BestBuyParser()
    ]
    
    public init() {}
    
    public func parse(_ ocrResult: OCRResult) -> ParsedReceiptData? {
        let text = ocrResult.text
        
        // Try each retailer parser
        for parser in parsers {
            if parser.canParse(text) {
                if var data = parser.parse(text) {
                    // Add raw text from OCR
                    data.rawText = ocrResult.text
                    return data
                }
            }
        }
        
        // Fall back to generic parsing
        return genericParse(ocrResult)
    }
    
    private func genericParse(_ ocrResult: OCRResult) -> ParsedReceiptData {
        let parser = ReceiptParser()
        let data = parser.parse(ocrResult)
        return ParsedReceiptData(
            storeName: data.storeName ?? "Unknown Store",
            date: data.date ?? Date(),
            totalAmount: data.totalAmount ?? 0,
            items: data.items.map { ocrItem in
                ParsedReceiptItem(
                    name: ocrItem.name,
                    quantity: ocrItem.quantity ?? 1,
                    price: ocrItem.price ?? 0
                )
            },
            confidence: data.confidence,
            rawText: data.rawText
        )
    }
}