//
//  Document.swift
//  Core
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
//  Module: Core
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/DocumentTests.swift
//
//  Description: Model for document attachments including PDFs, receipts, manuals, and other file types
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Model for document attachments (PDFs, receipts, manuals, etc.)
/// Swift 5.9 - No Swift 6 features
public struct Document: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var type: DocumentType
    public var category: DocumentCategory
    public var subcategory: String?
    public var fileSize: Int64 // in bytes
    public var mimeType: String
    public var itemId: UUID? // Optional association with an item
    public var receiptId: UUID? // Optional association with a receipt
    public var warrantyId: UUID? // Optional association with a warranty
    public var tags: [String]
    public var notes: String?
    public var pageCount: Int?
    public var thumbnailData: Data? // Cached thumbnail
    public var searchableText: String? // Extracted text for search
    public let createdAt: Date
    public var updatedAt: Date
    
    public enum DocumentType: String, Codable, CaseIterable {
        case pdf = "pdf"
        case image = "image"
        case text = "text"
        case other = "other"
        
        public var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .image: return "photo.fill"
            case .text: return "doc.text.fill"
            case .other: return "doc.fill"
            }
        }
        
        public static func from(mimeType: String) -> DocumentType {
            if mimeType.starts(with: "application/pdf") {
                return .pdf
            } else if mimeType.starts(with: "image/") {
                return .image
            } else if mimeType.starts(with: "text/") {
                return .text
            } else {
                return .other
            }
        }
    }
    
    public enum DocumentCategory: String, Codable, CaseIterable {
        case receipt = "receipt"
        case manual = "manual"
        case warranty = "warranty"
        case invoice = "invoice"
        case certificate = "certificate"
        case insurance = "insurance"
        case contract = "contract"
        case specification = "specification"
        case other = "other"
        
        public var displayName: String {
            switch self {
            case .receipt: return "Receipt"
            case .manual: return "Manual"
            case .warranty: return "Warranty"
            case .invoice: return "Invoice"
            case .certificate: return "Certificate"
            case .insurance: return "Insurance"
            case .contract: return "Contract"
            case .specification: return "Specification"
            case .other: return "Other"
            }
        }
        
        public var icon: String {
            switch self {
            case .receipt: return "receipt"
            case .manual: return "book.fill"
            case .warranty: return "shield.fill"
            case .invoice: return "doc.text.fill"
            case .certificate: return "rosette"
            case .insurance: return "umbrella.fill"
            case .contract: return "signature"
            case .specification: return "doc.badge.gearshape"
            case .other: return "folder.fill"
            }
        }
        
        public var color: String {
            switch self {
            case .receipt: return "#FF6B6B"      // Red
            case .manual: return "#4ECDC4"       // Teal
            case .warranty: return "#45B7D1"     // Blue
            case .invoice: return "#96CEB4"      // Green
            case .certificate: return "#FECA57"  // Yellow
            case .insurance: return "#9B59B6"    // Purple
            case .contract: return "#E67E22"     // Orange
            case .specification: return "#95A5A6" // Gray
            case .other: return "#7F8C8D"        // Dark Gray
            }
        }
        
        public var subcategories: [String] {
            switch self {
            case .receipt:
                return ["Purchase", "Return", "Exchange", "Service", "Subscription"]
            case .manual:
                return ["User Guide", "Installation", "Quick Start", "Troubleshooting", "Technical"]
            case .warranty:
                return ["Standard", "Extended", "Service Plan", "Protection Plan"]
            case .invoice:
                return ["Purchase", "Service", "Repair", "Maintenance"]
            case .certificate:
                return ["Authenticity", "Appraisal", "Compliance", "Registration"]
            case .insurance:
                return ["Policy", "Claim", "Coverage", "Renewal"]
            case .contract:
                return ["Purchase", "Service", "Lease", "Rental"]
            case .specification:
                return ["Technical", "Product", "Safety", "Compliance"]
            case .other:
                return []
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DocumentType,
        category: DocumentCategory = .other,
        subcategory: String? = nil,
        fileSize: Int64,
        mimeType: String,
        itemId: UUID? = nil,
        receiptId: UUID? = nil,
        warrantyId: UUID? = nil,
        tags: [String] = [],
        notes: String? = nil,
        pageCount: Int? = nil,
        thumbnailData: Data? = nil,
        searchableText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.subcategory = subcategory
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.itemId = itemId
        self.receiptId = receiptId
        self.warrantyId = warrantyId
        self.tags = tags
        self.notes = notes
        self.pageCount = pageCount
        self.thumbnailData = thumbnailData
        self.searchableText = searchableText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Human-readable file size
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Check if document is a PDF
    public var isPDF: Bool {
        type == .pdf || mimeType == "application/pdf"
    }
    
    /// Check if document is an image
    public var isImage: Bool {
        type == .image || mimeType.starts(with: "image/")
    }
}

// MARK: - Document Storage Protocol
public protocol DocumentStorageProtocol {
    /// Save document data to storage
    func saveDocument(_ data: Data, documentId: UUID) async throws -> URL
    
    /// Load document data from storage
    func loadDocument(documentId: UUID) async throws -> Data
    
    /// Delete document from storage
    func deleteDocument(documentId: UUID) async throws
    
    /// Get document URL for sharing/viewing
    func getDocumentURL(documentId: UUID) -> URL?
    
    /// Check if document exists
    func documentExists(documentId: UUID) -> Bool
}

// MARK: - Document Repository Protocol
public protocol DocumentRepository: Repository where Entity == Document {
    /// Fetch documents for an item
    func fetchByItemId(_ itemId: UUID) async throws -> [Document]
    
    /// Fetch documents by category
    func fetchByCategory(_ category: Document.DocumentCategory) async throws -> [Document]
    
    /// Search documents by text
    func search(query: String) async throws -> [Document]
    
    /// Fetch documents by tags
    func fetchByTags(_ tags: [String]) async throws -> [Document]
    
    /// Update searchable text for a document
    func updateSearchableText(documentId: UUID, text: String) async throws
    
    /// Get total storage size used
    func getTotalStorageSize() async throws -> Int64
}