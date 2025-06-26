//
//  EmailClassifier.swift
//  Gmail Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Gmail
//  Dependencies: Foundation, Core
//  Testing: GmailTests/EmailClassifierTests.swift
//
//  Description: Smart email classification system with 7-factor confidence scoring
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Email classifier for determining if an email is a receipt and extracting relevant information
public class EmailClassifier {
    
    public init() {}
    
    /// Classification result with confidence score
    public struct ClassificationResult {
        public let isReceipt: Bool
        public let confidence: Double
        public let factors: ClassificationFactors
        public let extractedData: ExtractedReceiptData?
    }
    
    /// Factors contributing to classification decision
    public struct ClassificationFactors {
        public let subjectScore: Double
        public let senderScore: Double
        public let bodyScore: Double
        public let attachmentScore: Double
        public let dateScore: Double
        public let amountScore: Double
        public let keywordScore: Double
    }
    
    /// Extracted receipt data
    public struct ExtractedReceiptData {
        public let retailer: String?
        public let totalAmount: Decimal?
        public let orderNumber: String?
        public let items: [ExtractedItem]
    }
    
    /// Extracted item from receipt
    public struct ExtractedItem {
        public let name: String
        public let price: Decimal?
        public let quantity: Int
    }
    
    // MARK: - Properties
    
    private let subjectKeywords = [
        "receipt", "invoice", "order", "purchase", "payment", "confirmation",
        "transaction", "billing", "statement", "your order", "order details",
        "order summary", "thank you for your order", "payment received"
    ]
    
    private let bodyKeywords = [
        "total", "subtotal", "tax", "shipping", "delivery", "payment",
        "paid", "amount", "price", "cost", "charge", "fee", "balance",
        "order number", "transaction id", "confirmation number", "invoice number"
    ]
    
    private let knownRetailers = [
        "amazon", "apple", "best buy", "walmart", "target", "ebay", "etsy",
        "home depot", "lowe's", "costco", "sephora", "nike", "adidas",
        "nordstrom", "macy's", "wayfair", "ikea", "williams sonoma",
        "west elm", "pottery barn", "crate and barrel", "anthropologie",
        "zara", "h&m", "uniqlo", "gap", "old navy", "banana republic",
        "j.crew", "rei", "patagonia", "north face", "columbia",
        "dick's sporting goods", "foot locker", "finish line", "gamestop",
        "steam", "playstation", "xbox", "nintendo", "uber", "lyft",
        "doordash", "grubhub", "postmates", "instacart", "seamless"
    ]
    
    // MARK: - Public Methods
    
    /// Classify an email message
    public func classify(_ email: EmailMessage) -> ClassificationResult {
        let factors = calculateFactors(for: email)
        let confidence = calculateConfidence(from: factors)
        let isReceipt = confidence >= 0.7 // 70% threshold
        
        var extractedData: ExtractedReceiptData? = nil
        if isReceipt {
            extractedData = extractData(from: email)
        }
        
        return ClassificationResult(
            isReceipt: isReceipt,
            confidence: confidence,
            factors: factors,
            extractedData: extractedData
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateFactors(for email: EmailMessage) -> ClassificationFactors {
        return ClassificationFactors(
            subjectScore: calculateSubjectScore(email.subject),
            senderScore: calculateSenderScore(email.from),
            bodyScore: calculateBodyScore(email.snippet),
            attachmentScore: calculateAttachmentScore(email),
            dateScore: calculateDateScore(email.date),
            amountScore: calculateAmountScore(email),
            keywordScore: calculateKeywordScore(email)
        )
    }
    
    private func calculateSubjectScore(_ subject: String) -> Double {
        let lowercased = subject.lowercased()
        var score = 0.0
        
        for keyword in subjectKeywords {
            if lowercased.contains(keyword) {
                score += 1.0
            }
        }
        
        return min(score / 3.0, 1.0) // Normalize to 0-1
    }
    
    private func calculateSenderScore(_ sender: String) -> Double {
        let lowercased = sender.lowercased()
        
        for retailer in knownRetailers {
            if lowercased.contains(retailer) {
                return 1.0
            }
        }
        
        // Check for common receipt sender patterns
        if lowercased.contains("noreply") || 
           lowercased.contains("donotreply") ||
           lowercased.contains("receipt") ||
           lowercased.contains("billing") ||
           lowercased.contains("order") {
            return 0.7
        }
        
        return 0.0
    }
    
    private func calculateBodyScore(_ snippet: String) -> Double {
        let lowercased = snippet.lowercased()
        var score = 0.0
        
        for keyword in bodyKeywords {
            if lowercased.contains(keyword) {
                score += 1.0
            }
        }
        
        return min(score / 5.0, 1.0) // Normalize to 0-1
    }
    
    private func calculateAttachmentScore(_ email: EmailMessage) -> Double {
        // Check if email has attachments (would need to be implemented in EmailMessage)
        // For now, assume no attachments
        return 0.0
    }
    
    private func calculateDateScore(_ date: Date) -> Double {
        // Recent emails are more likely to be relevant receipts
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysAgo <= 7 {
            return 1.0
        } else if daysAgo <= 30 {
            return 0.7
        } else if daysAgo <= 90 {
            return 0.4
        } else {
            return 0.1
        }
    }
    
    private func calculateAmountScore(_ email: EmailMessage) -> Double {
        let pattern = #"(?:[$€£¥]|USD|EUR|GBP)\s*(\d+(?:[.,]\d{2})?)"#
        
        if let _ = email.snippet.range(of: pattern, options: .regularExpression) {
            return 1.0
        }
        
        return 0.0
    }
    
    private func calculateKeywordScore(_ email: EmailMessage) -> Double {
        let fullText = "\(email.subject) \(email.snippet)".lowercased()
        var score = 0.0
        
        // High-value keywords
        let highValueKeywords = ["order confirmation", "payment receipt", "invoice", "transaction complete"]
        for keyword in highValueKeywords {
            if fullText.contains(keyword) {
                score += 2.0
            }
        }
        
        // Medium-value keywords
        let mediumValueKeywords = ["thank you", "shipped", "delivered", "processing"]
        for keyword in mediumValueKeywords {
            if fullText.contains(keyword) {
                score += 1.0
            }
        }
        
        return min(score / 4.0, 1.0) // Normalize to 0-1
    }
    
    private func calculateConfidence(from factors: ClassificationFactors) -> Double {
        // Weighted average of all factors
        let weights: [(Double, Double)] = [
            (factors.subjectScore, 0.2),
            (factors.senderScore, 0.25),
            (factors.bodyScore, 0.15),
            (factors.attachmentScore, 0.05),
            (factors.dateScore, 0.1),
            (factors.amountScore, 0.15),
            (factors.keywordScore, 0.1)
        ]
        
        let totalWeight = weights.reduce(0) { $0 + $1.1 }
        let weightedSum = weights.reduce(0) { $0 + ($1.0 * $1.1) }
        
        return weightedSum / totalWeight
    }
    
    private func extractData(from email: EmailMessage) -> ExtractedReceiptData {
        let retailer = extractRetailer(from: email)
        let totalAmount = extractAmount(from: email.snippet)
        let orderNumber = extractOrderNumber(from: email.snippet)
        let items = extractItems(from: email.snippet)
        
        return ExtractedReceiptData(
            retailer: retailer,
            totalAmount: totalAmount,
            orderNumber: orderNumber,
            items: items
        )
    }
    
    private func extractRetailer(from email: EmailMessage) -> String? {
        let lowercasedSender = email.from.lowercased()
        
        for retailer in knownRetailers {
            if lowercasedSender.contains(retailer) {
                return retailer.capitalized
            }
        }
        
        // Extract from email domain
        if let atIndex = email.from.firstIndex(of: "@"),
           let dotIndex = email.from[atIndex...].firstIndex(of: ".") {
            let domain = String(email.from[email.from.index(after: atIndex)..<dotIndex])
            return domain.capitalized
        }
        
        return nil
    }
    
    private func extractAmount(from text: String) -> Decimal? {
        // Look for total amount patterns
        let patterns = [
            #"(?:total|amount|charged).*?(?:[$€£¥]|USD|EUR|GBP)\s*(\d+(?:[.,]\d{2})?)"#,
            #"(?:[$€£¥]|USD|EUR|GBP)\s*(\d+(?:[.,]\d{2})?)\s*(?:total|amount)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
                return Decimal(string: amountString)
            }
        }
        
        return nil
    }
    
    private func extractOrderNumber(from text: String) -> String? {
        let patterns = [
            #"(?:order|confirmation|transaction|invoice).*?#\s*([A-Z0-9-]+)"#,
            #"#\s*([A-Z0-9-]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    private func extractItems(from text: String) -> [ExtractedItem] {
        // Basic item extraction - would need more sophisticated parsing for real implementation
        var items: [ExtractedItem] = []
        
        // Look for item patterns
        let itemPattern = #"(\d+)\s*x\s*(.+?)\s*(?:[$€£¥]|USD|EUR|GBP)\s*(\d+(?:[.,]\d{2})?)"#
        
        if let regex = try? NSRegularExpression(pattern: itemPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let quantityRange = Range(match.range(at: 1), in: text),
                   let nameRange = Range(match.range(at: 2), in: text),
                   let priceRange = Range(match.range(at: 3), in: text) {
                    
                    let quantity = Int(text[quantityRange]) ?? 1
                    let name = String(text[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let priceString = String(text[priceRange]).replacingOccurrences(of: ",", with: "")
                    let price = Decimal(string: priceString)
                    
                    items.append(ExtractedItem(name: name, price: price, quantity: quantity))
                }
            }
        }
        
        return items
    }
}