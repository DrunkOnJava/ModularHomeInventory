//
//  BulkImportService.swift
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
//  Testing: GmailTests/BulkImportServiceTests.swift
//
//  Description: Service for bulk importing multiple emails as receipts
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Service for bulk importing emails as receipts
public class BulkImportService: ObservableObject {
    
    /// Import status for tracking progress
    public struct ImportStatus {
        public let totalCount: Int
        public let processedCount: Int
        public let successCount: Int
        public let failureCount: Int
        public let currentEmail: String?
        public let errors: [ImportError]
        
        public var progress: Double {
            guard totalCount > 0 else { return 0 }
            return Double(processedCount) / Double(totalCount)
        }
        
        public var isComplete: Bool {
            processedCount >= totalCount
        }
    }
    
    /// Import error details
    public struct ImportError {
        public let emailId: String
        public let subject: String
        public let error: Error
        public let timestamp: Date
    }
    
    /// Import result for a single email
    public struct ImportResult {
        public let emailId: String
        public let success: Bool
        public let receipt: Receipt?
        public let error: Error?
    }
    
    // MARK: - Properties
    
    @Published public private(set) var importStatus: ImportStatus?
    @Published public private(set) var isImporting = false
    
    private let classifier: EmailClassifier
    private let receiptService: ReceiptService
    private let importQueue = DispatchQueue(label: "com.homeinventory.gmail.import", attributes: .concurrent)
    private let statusUpdateQueue = DispatchQueue(label: "com.homeinventory.gmail.import.status")
    
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(receiptService: ReceiptService) {
        self.classifier = EmailClassifier()
        self.receiptService = receiptService
    }
    
    // MARK: - Public Methods
    
    /// Import multiple emails as receipts
    public func importEmails(_ emails: [EmailMessage], confidenceThreshold: Double = 0.7) async -> [ImportResult] {
        // Cancel any existing import
        currentTask?.cancel()
        
        // Reset status
        await MainActor.run {
            isImporting = true
            importStatus = ImportStatus(
                totalCount: emails.count,
                processedCount: 0,
                successCount: 0,
                failureCount: 0,
                currentEmail: nil,
                errors: []
            )
        }
        
        var results: [ImportResult] = []
        
        // Process emails
        for (index, email) in emails.enumerated() {
            // Check for cancellation
            if Task.isCancelled { break }
            
            // Update current email
            await updateStatus { status in
                ImportStatus(
                    totalCount: status.totalCount,
                    processedCount: index,
                    successCount: status.successCount,
                    failureCount: status.failureCount,
                    currentEmail: email.subject,
                    errors: status.errors
                )
            }
            
            // Process email
            let result = await processEmail(email, confidenceThreshold: confidenceThreshold)
            results.append(result)
            
            // Update counters
            await updateStatus { status in
                ImportStatus(
                    totalCount: status.totalCount,
                    processedCount: index + 1,
                    successCount: status.successCount + (result.success ? 1 : 0),
                    failureCount: status.failureCount + (result.success ? 0 : 1),
                    currentEmail: status.currentEmail,
                    errors: result.success ? status.errors : status.errors + [
                        ImportError(
                            emailId: email.id,
                            subject: email.subject,
                            error: result.error ?? ImportServiceError.unknownError,
                            timestamp: Date()
                        )
                    ]
                )
            }
        }
        
        // Mark import as complete
        await MainActor.run {
            isImporting = false
        }
        
        return results
    }
    
    /// Cancel ongoing import
    public func cancelImport() {
        currentTask?.cancel()
        Task { @MainActor in
            isImporting = false
        }
    }
    
    // MARK: - Private Methods
    
    private func processEmail(_ email: EmailMessage, confidenceThreshold: Double) async -> ImportResult {
        do {
            // Classify email
            let classification = classifier.classify(email)
            
            // Check confidence threshold
            guard classification.confidence >= confidenceThreshold else {
                throw ImportServiceError.belowConfidenceThreshold(
                    confidence: classification.confidence,
                    threshold: confidenceThreshold
                )
            }
            
            // Extract receipt data
            guard let extractedData = classification.extractedData else {
                throw ImportServiceError.noReceiptDataFound
            }
            
            // Create receipt
            let receipt = try await createReceipt(from: email, extractedData: extractedData, confidence: classification.confidence)
            
            // Save receipt
            try await receiptService.save(receipt)
            
            return ImportResult(
                emailId: email.id,
                success: true,
                receipt: receipt,
                error: nil
            )
            
        } catch {
            return ImportResult(
                emailId: email.id,
                success: false,
                receipt: nil,
                error: error
            )
        }
    }
    
    private func createReceipt(
        from email: EmailMessage,
        extractedData: EmailClassifier.ExtractedReceiptData,
        confidence: Double
    ) async throws -> Receipt {
        // Create items from extracted data
        var items: [Item] = []
        
        for extractedItem in extractedData.items {
            let item = Item(
                name: extractedItem.name,
                category: .other, // Default category for imported items
                quantity: extractedItem.quantity,
                purchasePrice: extractedItem.price,
                purchaseDate: email.date,
                notes: "Imported from Gmail on \(Date().formatted())",
                storeName: extractedData.retailer
            )
            items.append(item)
        }
        
        // Create receipt
        let receipt = Receipt(
            id: UUID(),
            storeName: extractedData.retailer ?? "Unknown Store",
            date: email.date,
            totalAmount: extractedData.totalAmount ?? 0,
            itemIds: items.map { $0.id },
            imageData: nil,
            rawText: email.body,
            confidence: confidence,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save items
        for item in items {
            try await saveItem(item)
        }
        
        return receipt
    }
    
    private func categorizeItem(_ name: String) -> String {
        let lowercased = name.lowercased()
        
        // Basic categorization logic
        switch lowercased {
        case _ where lowercased.contains("electronics") || lowercased.contains("phone") || lowercased.contains("computer"):
            return "Electronics"
        case _ where lowercased.contains("clothing") || lowercased.contains("shirt") || lowercased.contains("pants"):
            return "Clothing"
        case _ where lowercased.contains("book") || lowercased.contains("ebook"):
            return "Books"
        case _ where lowercased.contains("game") || lowercased.contains("toy"):
            return "Games & Toys"
        case _ where lowercased.contains("kitchen") || lowercased.contains("appliance"):
            return "Home & Kitchen"
        default:
            return "Other"
        }
    }
    
    private func saveItem(_ item: Item) async throws {
        // This would typically call a service to save the item
        // For now, we'll just simulate the save
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func updateStatus(_ update: (ImportStatus) -> ImportStatus) async {
        await MainActor.run {
            if let currentStatus = importStatus {
                importStatus = update(currentStatus)
            }
        }
    }
}

// MARK: - Import Service Errors

public enum ImportServiceError: LocalizedError {
    case belowConfidenceThreshold(confidence: Double, threshold: Double)
    case noReceiptDataFound
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .belowConfidenceThreshold(let confidence, let threshold):
            return "Email confidence (\(Int(confidence * 100))%) is below threshold (\(Int(threshold * 100))%)"
        case .noReceiptDataFound:
            return "No receipt data could be extracted from this email"
        case .unknownError:
            return "An unknown error occurred during import"
        }
    }
}

// MARK: - Receipt Service Protocol

public protocol ReceiptService {
    func save(_ receipt: Receipt) async throws
    func delete(_ receiptId: UUID) async throws
    func fetch(limit: Int, offset: Int) async throws -> [Receipt]
    func search(query: String) async throws -> [Receipt]
}