import Foundation

struct ReceiptParser {
    
    func parseEmail(subject: String, from: String, body: String) -> ReceiptInfo? {
        var retailer = extractRetailer(from: from, subject: subject)
        var orderNumber: String?
        var totalAmount: Double?
        var items: [ReceiptItem] = []
        var confidence = 0.0
        
        // Parse based on retailer or email patterns
        let emailLower = from.lowercased()
        let subjectLower = subject.lowercased()
        
        if emailLower.contains("amazon") || emailLower.contains("@amazon.") {
            (orderNumber, totalAmount, items, confidence) = parseAmazonReceipt(subject: subject, body: body)
            retailer = "Amazon"
        } else if emailLower.contains("walmart") || emailLower.contains("@walmart.") {
            (orderNumber, totalAmount, items, confidence) = parseWalmartReceipt(subject: subject, body: body)
            retailer = "Walmart"
        } else if emailLower.contains("target") || emailLower.contains("@target.") {
            (orderNumber, totalAmount, items, confidence) = parseTargetReceipt(subject: subject, body: body)
            retailer = "Target"
        } else if emailLower.contains("apple") || emailLower.contains("@apple.") || emailLower.contains("@itunes.") {
            (orderNumber, totalAmount, items, confidence) = parseAppleReceipt(subject: subject, body: body)
            retailer = "Apple"
        } else if emailLower.contains("cvs") || emailLower.contains("@cvs.") {
            (orderNumber, totalAmount, items, confidence) = parseCVSReceipt(subject: subject, body: body)
            retailer = "CVS"
        } else if emailLower.contains("uber") || emailLower.contains("@uber.") || emailLower.contains("lyft") || emailLower.contains("@lyft.") {
            (orderNumber, totalAmount, items, confidence) = parseRideShareReceipt(subject: subject, body: body)
            if emailLower.contains("lyft") {
                retailer = "Lyft"
            } else {
                retailer = "Uber"
            }
        } else if emailLower.contains("doordash") || emailLower.contains("@doordash.") || emailLower.contains("grubhub") || emailLower.contains("@grubhub.") {
            (orderNumber, totalAmount, items, confidence) = parseFoodDeliveryReceipt(subject: subject, body: body)
            if emailLower.contains("grubhub") {
                retailer = "Grubhub"
            } else {
                retailer = "DoorDash"
            }
        } else if emailLower.contains("insurance") || emailLower.contains("geico") || emailLower.contains("statefarm") || 
                  emailLower.contains("allstate") || emailLower.contains("progressive") ||
                  subjectLower.contains("policy") || subjectLower.contains("insurance") || 
                  subjectLower.contains("coverage") || subjectLower.contains("premium") {
            (orderNumber, totalAmount, items, confidence) = parseInsuranceDocument(subject: subject, body: body)
            if retailer == "Unknown" && confidence > 0.3 {
                retailer = "Insurance"
            }
        } else if emailLower.contains("affirm") || emailLower.contains("@affirm.") || emailLower.contains("klarna") || emailLower.contains("@klarna.") || 
                  emailLower.contains("afterpay") || emailLower.contains("@afterpay.") || emailLower.contains("sezzle") || emailLower.contains("@sezzle.") ||
                  subjectLower.contains("installment") || subjectLower.contains("payment plan") {
            (orderNumber, totalAmount, items, confidence) = parsePayLaterReceipt(subject: subject, body: body)
            if retailer == "Unknown" && confidence > 0.3 {
                if emailLower.contains("affirm") { retailer = "Affirm" }
                else if emailLower.contains("klarna") { retailer = "Klarna" }
                else if emailLower.contains("afterpay") { retailer = "Afterpay" }
                else if emailLower.contains("sezzle") { retailer = "Sezzle" }
                else { retailer = "Pay Later" }
            }
        } else if emailLower.contains("netflix") || emailLower.contains("spotify") || emailLower.contains("adobe") || 
                  emailLower.contains("microsoft") || emailLower.contains("google") || 
                  subjectLower.contains("subscription") || subjectLower.contains("recurring") || 
                  subjectLower.contains("membership") || subjectLower.contains("renewal") {
            (orderNumber, totalAmount, items, confidence) = parseSubscriptionReceipt(subject: subject, body: body)
            if retailer == "Unknown" && confidence > 0.3 {
                if emailLower.contains("netflix") { retailer = "Netflix" }
                else if emailLower.contains("spotify") { retailer = "Spotify" }
                else if emailLower.contains("adobe") { retailer = "Adobe" }
                else if emailLower.contains("microsoft") { retailer = "Microsoft" }
                else if emailLower.contains("google") { retailer = "Google" }
                else { retailer = "Subscription" }
            }
        } else if emailLower.contains("applecare") || (emailLower.contains("apple") && subjectLower.contains("warranty")) {
            (orderNumber, totalAmount, items, confidence) = parseWarrantyDocument(subject: subject, body: body)
            retailer = "AppleCare"
        } else if subjectLower.contains("warranty") || subjectLower.contains("protection plan") {
            (orderNumber, totalAmount, items, confidence) = parseWarrantyDocument(subject: subject, body: body)
            if retailer == "Unknown" && confidence > 0.3 {
                retailer = "Warranty"
            }
        } else if subjectLower.contains("receipt") || subjectLower.contains("order") || subjectLower.contains("purchase") {
            (orderNumber, totalAmount, items, confidence) = parseGenericReceipt(subject: subject, body: body)
        } else {
            // Still try generic parsing
            (orderNumber, totalAmount, items, confidence) = parseGenericReceipt(subject: subject, body: body)
        }
        
        // Only return if we found meaningful data
        guard confidence > 0.2 else { return nil }
        
        return ReceiptInfo(
            retailer: retailer,
            orderNumber: orderNumber,
            totalAmount: totalAmount,
            items: items,
            orderDate: nil, // Could parse from email body in future
            confidence: confidence
        )
    }
    
    private func extractRetailer(from: String, subject: String) -> String {
        // First try to extract from sender name
        if let nameEnd = from.firstIndex(of: "<") {
            let name = String(from[..<nameEnd]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty && !name.lowercased().contains("noreply") && !name.lowercased().contains("no-reply") {
                return name
            }
        }
        
        // Extract from email address domain
        if let emailMatch = from.range(of: #"<(.+?)@(.+?)>"#, options: .regularExpression) {
            let email = String(from[emailMatch])
            if let atIndex = email.firstIndex(of: "@") {
                let domain = String(email[email.index(after: atIndex)...])
                    .replacingOccurrences(of: ">", with: "")
                    .split(separator: ".")
                    .first ?? ""
                
                // Clean up common email prefixes
                let cleaned = String(domain)
                    .replacingOccurrences(of: "email", with: "")
                    .replacingOccurrences(of: "mail", with: "")
                    .replacingOccurrences(of: "news", with: "")
                    .replacingOccurrences(of: "support", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleaned.isEmpty {
                    return cleaned.capitalized
                }
            }
        }
        
        return "Unknown"
    }
    
    private func parseAmazonReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var orderNumber: String?
        var total: Double?
        var items: [ReceiptItem] = []
        
        // Check if it's an Amazon receipt
        let subjectLower = subject.lowercased()
        if subjectLower.contains("order") || subjectLower.contains("shipment") || subjectLower.contains("delivered") || subjectLower.contains("your amazon.com order") {
            confidence += 0.4
        }
        
        // Extract order number - Amazon uses format like 123-4567890-1234567
        let orderPatterns = [
            #"\b\d{3}-\d{7}-\d{7}\b"#,
            #"Order\s*#?\s*([0-9-]+)"#,
            #"Order\s+ID:?\s*([0-9-]+)"#
        ]
        
        for pattern in orderPatterns {
            if let orderMatch = body.range(of: pattern, options: .regularExpression) {
                let matched = String(body[orderMatch])
                orderNumber = matched.replacingOccurrences(of: "Order", with: "")
                    .replacingOccurrences(of: "ID", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                confidence += 0.3
                break
            }
        }
        
        // Extract total - Amazon uses various formats
        let totalPatterns = [
            #"Order Total:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Grand Total:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Total for this order:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Total:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        for pattern in totalPatterns {
            if let totalMatch = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let totalString = String(body[totalMatch])
                if let value = extractPrice(from: totalString) {
                    total = value
                    confidence += 0.2
                    break
                }
            }
        }
        
        // Look for item patterns
        let itemPatterns = [
            #"(.+?)\s+\$([0-9,]+\.?[0-9]*)"#,
            #"Item:?\s*(.+?)\s+Price:?\s*\$([0-9,]+\.?[0-9]*)"#
        ]
        
        let lines = body.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip lines that are clearly not items
            if trimmedLine.isEmpty || 
               trimmedLine.lowercased().contains("total") ||
               trimmedLine.lowercased().contains("tax") ||
               trimmedLine.lowercased().contains("shipping") ||
               trimmedLine.lowercased().contains("subtotal") {
                continue
            }
            
            // Try to extract item and price
            for pattern in itemPatterns {
                if let match = trimmedLine.range(of: pattern, options: .regularExpression) {
                    let matched = String(trimmedLine[match])
                    if let price = extractPrice(from: matched) {
                        let name = matched.replacingOccurrences(of: #"\$[0-9,]+\.?[0-9]*"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty && name.count > 3 {
                            items.append(ReceiptItem(name: name, price: price, quantity: 1))
                            break
                        }
                    }
                }
            }
        }
        
        if !items.isEmpty {
            confidence += 0.1
        }
        
        return (orderNumber, total, items, confidence)
    }
    
    private func parseWalmartReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        // Similar parsing logic for Walmart
        return parseGenericReceipt(subject: subject, body: body)
    }
    
    private func parseTargetReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        // Similar parsing logic for Target
        return parseGenericReceipt(subject: subject, body: body)
    }
    
    private func parseAppleReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        // Similar parsing logic for Apple
        return parseGenericReceipt(subject: subject, body: body)
    }
    
    private func parseCVSReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        // Similar parsing logic for CVS
        return parseGenericReceipt(subject: subject, body: body)
    }
    
    private func parseRideShareReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var orderNumber: String?
        var total: Double?
        var items: [ReceiptItem] = []
        
        // Ride share specific parsing
        if subject.lowercased().contains("trip") || subject.lowercased().contains("ride") || subject.lowercased().contains("fare") {
            confidence += 0.4
        }
        
        // Extract trip/order ID
        if let tripMatch = body.range(of: #"Trip ID:?\s*([A-Z0-9-]+)"#, options: [.regularExpression, .caseInsensitive]) {
            orderNumber = String(body[tripMatch]).replacingOccurrences(of: "Trip ID", with: "").trimmingCharacters(in: .whitespaces)
            confidence += 0.2
        }
        
        // Extract fare
        let farePatterns = [
            #"Total:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Fare:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"You paid:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        for pattern in farePatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    total = value
                    confidence += 0.3
                    break
                }
            }
        }
        
        return (orderNumber, total, items, confidence)
    }
    
    private func parseFoodDeliveryReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var orderNumber: String?
        var total: Double?
        var items: [ReceiptItem] = []
        
        // Food delivery specific parsing
        if subject.lowercased().contains("order") || subject.lowercased().contains("delivery") || subject.lowercased().contains("food") {
            confidence += 0.4
        }
        
        // Extract order number
        if let orderMatch = body.range(of: #"Order #?\s*([0-9-]+)"#, options: .regularExpression) {
            orderNumber = String(body[orderMatch]).replacingOccurrences(of: "Order", with: "").trimmingCharacters(in: .whitespaces)
            confidence += 0.2
        }
        
        // Extract total
        if let totalMatch = body.range(of: #"Total:?\s*\$?([0-9,]+\.?[0-9]*)"#, options: [.regularExpression, .caseInsensitive]) {
            if let value = extractPrice(from: String(body[totalMatch])) {
                total = value
                confidence += 0.3
            }
        }
        
        return (orderNumber, total, items, confidence)
    }
    
    private func parseGenericReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var orderNumber: String?
        var total: Double?
        var items: [ReceiptItem] = []
        
        // Check for receipt keywords in subject
        let receiptKeywords = ["receipt", "order", "purchase", "invoice", "payment", "transaction", "confirmation", "summary"]
        let subjectLower = subject.lowercased()
        let bodyLower = body.lowercased()
        
        var keywordFound = false
        for keyword in receiptKeywords {
            if subjectLower.contains(keyword) {
                confidence += 0.15
                keywordFound = true
                break
            }
        }
        
        // If not in subject, check body
        if !keywordFound {
            for keyword in receiptKeywords {
                if bodyLower.contains(keyword) {
                    confidence += 0.05
                    break
                }
            }
        }
        
        // Extract order/receipt number with more patterns
        let numberPatterns = [
            #"Order\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"Receipt\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"Transaction\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"Reference\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"Confirmation\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"Invoice\s*#?\s*:?\s*([A-Z0-9-]+)"#,
            #"#([A-Z0-9-]{4,})"#  // Generic pattern for order numbers
        ]
        
        for pattern in numberPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(body[match])
                // Clean up the match
                let cleaned = matched
                    .replacingOccurrences(of: "Order", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Receipt", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Transaction", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Reference", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Confirmation", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Invoice", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if cleaned.count >= 4 {  // Minimum length for order number
                    orderNumber = cleaned
                    confidence += 0.2
                    break
                }
            }
        }
        
        // Extract total with more patterns and better validation
        let totalPatterns = [
            #"Total:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Grand\s*Total:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount\s*Due:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount\s*Paid:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Payment\s*Amount:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"You\s*paid:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Charged:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        var maxTotal: Double = 0.0
        for pattern in totalPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    // Take the largest value found (likely the total, not subtotal)
                    if value > maxTotal {
                        maxTotal = value
                        total = value
                    }
                }
            }
        }
        
        if total != nil {
            confidence += 0.25
        }
        
        // Look for date patterns to increase confidence
        let datePatterns = [
            #"\b\d{1,2}/\d{1,2}/\d{2,4}\b"#,
            #"\b\d{4}-\d{2}-\d{2}\b"#,
            #"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b"#
        ]
        
        for pattern in datePatterns {
            if body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                confidence += 0.05
                break
            }
        }
        
        // Look for currency symbols to increase confidence
        if body.contains("$") || body.contains("USD") || body.contains("€") || body.contains("£") {
            confidence += 0.05
        }
        
        return (orderNumber, total, items, confidence)
    }
    
    private func parseInsuranceDocument(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var policyNumber: String?
        var premium: Double?
        var items: [ReceiptItem] = []
        
        // Check for insurance keywords
        let insuranceKeywords = ["policy", "insurance", "coverage", "premium", "deductible", "claim", "renewal", "effective date"]
        let lowercasedContent = (subject + " " + body).lowercased()
        
        for keyword in insuranceKeywords {
            if lowercasedContent.contains(keyword) {
                confidence += 0.1
                if confidence >= 0.3 { break }
            }
        }
        
        // Extract policy number
        let policyPatterns = [
            #"Policy\s*(?:Number|#|No\.?)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Policy\s+ID\s*:?\s*([A-Z0-9-]+)"#,
            #"Account\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Contract\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#
        ]
        
        for pattern in policyPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(body[match])
                policyNumber = matched
                    .replacingOccurrences(of: "Policy", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Number", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Account", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Contract", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "ID", with: "")
                    .replacingOccurrences(of: "No.", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !policyNumber!.isEmpty {
                    confidence += 0.25
                    break
                }
            }
        }
        
        // Extract premium/payment amount
        let premiumPatterns = [
            #"Premium\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Monthly\s+Premium\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Annual\s+Premium\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount\s+Due\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Payment\s+Amount\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Total\s+Premium\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        for pattern in premiumPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    premium = value
                    confidence += 0.3
                    
                    // Add as an item
                    let premiumType = String(body[match]).contains("Annual") ? "Annual Premium" : "Premium"
                    items.append(ReceiptItem(name: premiumType, price: value, quantity: 1))
                    break
                }
            }
        }
        
        // Look for coverage details to add as items
        let coveragePatterns = [
            #"(Liability|Collision|Comprehensive|Medical|Property|Renters?)\s+Coverage"#,
            #"(Auto|Home|Life|Health|Renters?)\s+Insurance"#
        ]
        
        for pattern in coveragePatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let coverage = String(body[match])
                if items.isEmpty || !items.contains(where: { $0.name == coverage }) {
                    items.append(ReceiptItem(name: coverage, price: nil, quantity: 1))
                }
                confidence += 0.05
            }
        }
        
        return (policyNumber, premium, items, confidence)
    }
    
    private func parseWarrantyDocument(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var warrantyNumber: String?
        var cost: Double?
        var items: [ReceiptItem] = []
        
        // Check for warranty keywords
        let warrantyKeywords = ["warranty", "protection", "applecare", "coverage", "service contract", "extended warranty"]
        let lowercasedContent = (subject + " " + body).lowercased()
        
        for keyword in warrantyKeywords {
            if lowercasedContent.contains(keyword) {
                confidence += 0.15
                if confidence >= 0.3 { break }
            }
        }
        
        // Extract warranty/agreement number
        let warrantyPatterns = [
            #"Agreement\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Warranty\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Service\s+Contract\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"AppleCare\s*(?:Agreement|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Registration\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#
        ]
        
        for pattern in warrantyPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(body[match])
                warrantyNumber = matched
                    .replacingOccurrences(of: "Agreement", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Warranty", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Service Contract", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "AppleCare", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Registration", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Number", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !warrantyNumber!.isEmpty {
                    confidence += 0.25
                    break
                }
            }
        }
        
        // Extract cost
        let costPatterns = [
            #"Total\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Cost\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Price\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"AppleCare\+?\s+for\s+.+?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        for pattern in costPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    cost = value
                    confidence += 0.3
                    break
                }
            }
        }
        
        // Look for product covered
        let productPatterns = [
            #"(iPhone|iPad|Mac|MacBook|Apple Watch|AirPods)[^,\n]*"#,
            #"Product\s*:?\s*([^\n]+)"#,
            #"Device\s*:?\s*([^\n]+)"#,
            #"Coverage\s+for\s*:?\s*([^\n]+)"#
        ]
        
        for pattern in productPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let product = String(body[match])
                    .replacingOccurrences(of: "Product:", with: "")
                    .replacingOccurrences(of: "Device:", with: "")
                    .replacingOccurrences(of: "Coverage for:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !product.isEmpty {
                    items.append(ReceiptItem(name: "Warranty: \(product)", price: cost, quantity: 1))
                    confidence += 0.1
                    break
                }
            }
        }
        
        // If no specific product found, add generic warranty item
        if items.isEmpty && cost != nil {
            items.append(ReceiptItem(name: "Extended Warranty", price: cost, quantity: 1))
        }
        
        return (warrantyNumber, cost, items, confidence)
    }
    
    private func parseSubscriptionReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var subscriptionId: String?
        var amount: Double?
        var items: [ReceiptItem] = []
        
        // Check for subscription keywords
        let subscriptionKeywords = ["subscription", "recurring", "membership", "renewal", "monthly", "annual", "yearly", "plan"]
        let lowercasedContent = (subject + " " + body).lowercased()
        
        for keyword in subscriptionKeywords {
            if lowercasedContent.contains(keyword) {
                confidence += 0.12
                if confidence >= 0.3 { break }
            }
        }
        
        // Extract subscription/account ID
        let idPatterns = [
            #"Subscription\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Account\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Member\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Customer\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#
        ]
        
        for pattern in idPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(body[match])
                subscriptionId = matched
                    .replacingOccurrences(of: "Subscription", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Account", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Member", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Customer", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "ID", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !subscriptionId!.isEmpty {
                    confidence += 0.2
                    break
                }
            }
        }
        
        // Extract amount
        let amountPatterns = [
            #"Monthly\s*(?:charge|payment|fee)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Annual\s*(?:charge|payment|fee)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Subscription\s*(?:fee|cost|price)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount\s*(?:charged|due)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Total\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        for pattern in amountPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    amount = value
                    confidence += 0.3
                    
                    // Determine subscription type
                    let matchStr = String(body[match]).lowercased()
                    let subscriptionType = matchStr.contains("annual") || matchStr.contains("yearly") ? "Annual Subscription" : "Monthly Subscription"
                    items.append(ReceiptItem(name: subscriptionType, price: value, quantity: 1))
                    break
                }
            }
        }
        
        // Look for service name
        let servicePatterns = [
            #"(Netflix|Spotify|Adobe|Microsoft|Google|Apple|Amazon Prime|Disney\+|Hulu)[^\n]*"#,
            #"Service\s*:?\s*([^\n]+)"#,
            #"Plan\s*:?\s*([^\n]+)"#
        ]
        
        for pattern in servicePatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let service = String(body[match])
                    .replacingOccurrences(of: "Service:", with: "")
                    .replacingOccurrences(of: "Plan:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !service.isEmpty && items.isEmpty {
                    items.append(ReceiptItem(name: service, price: amount, quantity: 1))
                    confidence += 0.1
                    break
                }
            }
        }
        
        return (subscriptionId, amount, items, confidence)
    }
    
    private func parsePayLaterReceipt(subject: String, body: String) -> (String?, Double?, [ReceiptItem], Double) {
        var confidence = 0.0
        var paymentPlanId: String?
        var amount: Double?
        var items: [ReceiptItem] = []
        
        // Check for pay-later keywords
        let payLaterKeywords = ["installment", "payment plan", "pay later", "affirm", "klarna", "afterpay", "sezzle", "split payment"]
        let lowercasedContent = (subject + " " + body).lowercased()
        
        for keyword in payLaterKeywords {
            if lowercasedContent.contains(keyword) {
                confidence += 0.15
                if confidence >= 0.3 { break }
            }
        }
        
        // Extract payment plan ID
        let idPatterns = [
            #"Plan\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Payment\s*Plan\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Order\s*(?:ID|#)?\s*:?\s*([A-Z0-9-]+)"#,
            #"Reference\s*(?:Number|#)?\s*:?\s*([A-Z0-9-]+)"#
        ]
        
        for pattern in idPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(body[match])
                paymentPlanId = matched
                    .replacingOccurrences(of: "Plan", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Payment", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Order", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Reference", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Number", with: "")
                    .replacingOccurrences(of: "ID", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !paymentPlanId!.isEmpty {
                    confidence += 0.2
                    break
                }
            }
        }
        
        // Extract amounts
        let amountPatterns = [
            #"Total\s*(?:amount|purchase)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Purchase\s*(?:amount|total)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Installment\s*(?:amount|payment)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Payment\s*(?:amount|due)?\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#,
            #"Amount\s*:?\s*\$?([0-9,]+\.?[0-9]*)"#
        ]
        
        var totalAmount: Double?
        var installmentAmount: Double?
        
        for pattern in amountPatterns {
            if let match = body.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                if let value = extractPrice(from: String(body[match])) {
                    let matchStr = String(body[match]).lowercased()
                    if matchStr.contains("total") || matchStr.contains("purchase") {
                        totalAmount = value
                    } else if matchStr.contains("installment") || matchStr.contains("payment") {
                        installmentAmount = value
                    }
                    
                    if amount == nil {
                        amount = value
                        confidence += 0.25
                    }
                }
            }
        }
        
        // Add installment details
        if let total = totalAmount {
            items.append(ReceiptItem(name: "Total Purchase", price: total, quantity: 1))
        }
        if let installment = installmentAmount {
            items.append(ReceiptItem(name: "Installment Payment", price: installment, quantity: 1))
        }
        
        // Look for number of installments
        if let installmentMatch = body.range(of: #"(\d+)\s*(?:installments?|payments?)"#, options: [.regularExpression, .caseInsensitive]) {
            let matched = String(body[installmentMatch])
            if let numInstallments = Int(matched.filter { $0.isNumber }) {
                items.append(ReceiptItem(name: "\(numInstallments) Installments", price: nil, quantity: 1))
                confidence += 0.1
            }
        }
        
        return (paymentPlanId, amount, items, confidence)
    }
    
    private func extractPrice(from text: String) -> Double? {
        let pattern = #"\$?([0-9,]+\.?[0-9]*)"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let priceString = String(text[match])
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Double(priceString)
        }
        return nil
    }
}