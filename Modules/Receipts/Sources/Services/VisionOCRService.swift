import Foundation
import Vision
import Core
#if canImport(UIKit)
import UIKit
#endif

/// OCR service implementation using Apple's Vision framework
/// Swift 5.9 - No Swift 6 features
@available(iOS 13.0, *)
final class VisionOCRService: OCRServiceProtocol {
    
    #if canImport(UIKit)
    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let regions = observations.compactMap { observation -> OCRTextRegion? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    let boundingBox = self.convertBoundingBox(
                        observation.boundingBox,
                        imageSize: CGSize(width: cgImage.width, height: cgImage.height)
                    )
                    
                    return OCRTextRegion(
                        text: topCandidate.string,
                        confidence: Double(topCandidate.confidence),
                        boundingBox: boundingBox
                    )
                }
                
                let fullText = regions.map { $0.text }.joined(separator: "\n")
                let averageConfidence = regions.isEmpty ? 0.0 :
                    regions.map { $0.confidence }.reduce(0, +) / Double(regions.count)
                
                let result = OCRResult(
                    text: fullText,
                    confidence: averageConfidence,
                    language: "en", // Vision framework doesn't provide language detection
                    regions: regions
                )
                
                continuation.resume(returning: result)
            }
            
            // Configure request
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    func extractReceiptData(from image: UIImage) async throws -> OCRReceiptData? {
        let ocrResult = try await extractText(from: image)
        
        // Use enhanced parser that supports multiple retailers
        let enhancedParser = EnhancedReceiptParser()
        if let parsedData = enhancedParser.parse(ocrResult) {
            // Convert ParsedReceiptData to OCRReceiptData
            return OCRReceiptData(
                storeName: parsedData.storeName,
                date: parsedData.date,
                totalAmount: parsedData.totalAmount,
                items: parsedData.items.map { item in
                    OCRReceiptItem(
                        name: item.name,
                        price: item.price,
                        quantity: item.quantity
                    )
                },
                confidence: parsedData.confidence,
                rawText: parsedData.rawText ?? ocrResult.text
            )
        }
        
        // Fall back to basic parser if enhanced parser returns nil
        let parser = ReceiptParser()
        return parser.parse(ocrResult)
    }
    
    private func convertBoundingBox(_ normalizedBox: CGRect, imageSize: CGSize) -> CGRect {
        // Convert Vision's normalized coordinates (0-1) to image coordinates
        // Vision uses bottom-left origin, UIKit uses top-left
        let x = normalizedBox.origin.x * imageSize.width
        let y = (1 - normalizedBox.origin.y - normalizedBox.height) * imageSize.height
        let width = normalizedBox.width * imageSize.width
        let height = normalizedBox.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    #endif
}

/// Errors that can occur during OCR processing
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .noTextFound:
            return "No text was found in the image"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        }
    }
}

/// Receipt parser to extract structured data from OCR text
struct ReceiptParser {
    
    func parse(_ ocrResult: OCRResult) -> OCRReceiptData {
        let lines = ocrResult.text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let storeName = detectStoreName(from: lines)
        let date = detectDate(from: lines)
        let totalAmount = detectTotalAmount(from: lines)
        let items = detectItems(from: lines)
        
        return OCRReceiptData(
            storeName: storeName,
            date: date,
            totalAmount: totalAmount,
            items: items,
            confidence: ocrResult.confidence,
            rawText: ocrResult.text
        )
    }
    
    private func detectStoreName(from lines: [String]) -> String? {
        // Common patterns for store names (usually at the top)
        // Look for lines with all caps or specific keywords
        for (_, line) in lines.prefix(5).enumerated() {
            // Skip very short lines
            if line.count < 3 { continue }
            
            // Check if line is mostly uppercase (likely store name)
            let uppercaseCount = line.filter { $0.isUppercase }.count
            let letterCount = line.filter { $0.isLetter }.count
            if letterCount > 0 && Double(uppercaseCount) / Double(letterCount) > 0.7 {
                return line
            }
            
            // Check for common store name patterns
            if line.contains("STORE") || line.contains("MARKET") || 
               line.contains("MART") || line.contains("SHOP") {
                return line
            }
        }
        
        // If no pattern matched, return the first substantial line
        return lines.first { $0.count > 5 }
    }
    
    private func detectDate(from lines: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        let datePatterns = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "MMM dd, yyyy",
            "MM/dd/yy",
            "dd/MM/yy"
        ]
        
        for line in lines {
            for pattern in datePatterns {
                dateFormatter.dateFormat = pattern
                if let date = dateFormatter.date(from: line) {
                    return date
                }
                
                // Try to find date within the line
                let components = line.components(separatedBy: .whitespaces)
                for component in components {
                    if let date = dateFormatter.date(from: component) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private func detectTotalAmount(from lines: [String]) -> Decimal? {
        // Look for total amount patterns
        let totalKeywords = ["TOTAL", "AMOUNT", "GRAND TOTAL", "SUBTOTAL", "BALANCE", "DUE"]
        let priceRegex = try? NSRegularExpression(pattern: "\\$?\\d+\\.\\d{2}", options: [])
        
        for (index, line) in lines.enumerated() {
            let upperLine = line.uppercased()
            
            // Check if line contains total keywords
            if totalKeywords.contains(where: { upperLine.contains($0) }) {
                // Extract price from this line or the next few lines
                for checkLine in lines[index...min(index + 2, lines.count - 1)] {
                    if let match = priceRegex?.firstMatch(
                        in: checkLine,
                        options: [],
                        range: NSRange(location: 0, length: checkLine.count)
                    ) {
                        let priceString = (checkLine as NSString).substring(with: match.range)
                            .replacingOccurrences(of: "$", with: "")
                        
                        if let price = Decimal(string: priceString) {
                            return price
                        }
                    }
                }
            }
        }
        
        // If no total found, look for the largest price in the receipt
        var prices: [Decimal] = []
        for line in lines {
            if let matches = priceRegex?.matches(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.count)
            ) {
                for match in matches {
                    let priceString = (line as NSString).substring(with: match.range)
                        .replacingOccurrences(of: "$", with: "")
                    
                    if let price = Decimal(string: priceString) {
                        prices.append(price)
                    }
                }
            }
        }
        
        return prices.max()
    }
    
    private func detectItems(from lines: [String]) -> [OCRReceiptItem] {
        var items: [OCRReceiptItem] = []
        let priceRegex = try? NSRegularExpression(pattern: "\\$?\\d+\\.\\d{2}", options: [])
        let quantityRegex = try? NSRegularExpression(pattern: "^\\d+\\s+|\\s+\\d+\\s+@", options: [])
        
        for line in lines {
            // Skip lines that are likely headers or totals
            let upperLine = line.uppercased()
            if upperLine.contains("TOTAL") || upperLine.contains("TAX") || 
               upperLine.contains("SUBTOTAL") || upperLine.contains("CHANGE") {
                continue
            }
            
            // Look for lines with prices
            if let priceMatch = priceRegex?.firstMatch(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.count)
            ) {
                let priceString = (line as NSString).substring(with: priceMatch.range)
                    .replacingOccurrences(of: "$", with: "")
                
                if let price = Decimal(string: priceString) {
                    // Extract item name (everything before the price)
                    let beforePrice = line.prefix(priceMatch.range.location)
                        .trimmingCharacters(in: .whitespaces)
                    
                    if !beforePrice.isEmpty {
                        // Check for quantity
                        var quantity: Int? = nil
                        var itemName = String(beforePrice)
                        
                        if let quantityMatch = quantityRegex?.firstMatch(
                            in: beforePrice,
                            options: [],
                            range: NSRange(location: 0, length: beforePrice.count)
                        ) {
                            let quantityString = (beforePrice as NSString)
                                .substring(with: quantityMatch.range)
                                .trimmingCharacters(in: .whitespaces)
                                .replacingOccurrences(of: "@", with: "")
                            
                            quantity = Int(quantityString)
                            
                            // Remove quantity from item name
                            itemName = beforePrice
                                .replacingOccurrences(of: quantityString, with: "")
                                .trimmingCharacters(in: .whitespaces)
                        }
                        
                        let item = OCRReceiptItem(
                            name: itemName,
                            price: price,
                            quantity: quantity ?? 1
                        )
                        items.append(item)
                    }
                }
            }
        }
        
        return items
    }
}