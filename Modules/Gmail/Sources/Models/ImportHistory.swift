//
//  ImportHistory.swift
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
//  Testing: GmailTests/ImportHistoryTests.swift
//
//  Description: Models for tracking Gmail import history
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Record of a Gmail import session
public struct ImportSession: Identifiable, Codable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date?
    public let status: ImportStatus
    public let totalEmails: Int
    public let successfulImports: Int
    public let failedImports: Int
    public let importedReceipts: [ImportedReceipt]
    public let errors: [ImportErrorRecord]
    
    public var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    public var successRate: Double {
        guard totalEmails > 0 else { return 0 }
        return Double(successfulImports) / Double(totalEmails)
    }
    
    public init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        status: ImportStatus = .inProgress,
        totalEmails: Int = 0,
        successfulImports: Int = 0,
        failedImports: Int = 0,
        importedReceipts: [ImportedReceipt] = [],
        errors: [ImportErrorRecord] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.totalEmails = totalEmails
        self.successfulImports = successfulImports
        self.failedImports = failedImports
        self.importedReceipts = importedReceipts
        self.errors = errors
    }
}

/// Status of an import session
public enum ImportStatus: String, Codable, CaseIterable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case failed = "Failed"
    
    public var iconName: String {
        switch self {
        case .inProgress:
            return "arrow.clockwise.circle"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .inProgress:
            return "blue"
        case .completed:
            return "green"
        case .cancelled:
            return "orange"
        case .failed:
            return "red"
        }
    }
}

/// Record of an imported receipt
public struct ImportedReceipt: Identifiable, Codable {
    public let id: UUID
    public let emailId: String
    public let emailSubject: String
    public let emailDate: Date
    public let retailer: String
    public let amount: Decimal
    public let confidence: Double
    public let receiptId: UUID
    public let itemCount: Int
    public let importDate: Date
    
    public init(
        id: UUID = UUID(),
        emailId: String,
        emailSubject: String,
        emailDate: Date,
        retailer: String,
        amount: Decimal,
        confidence: Double,
        receiptId: UUID,
        itemCount: Int,
        importDate: Date = Date()
    ) {
        self.id = id
        self.emailId = emailId
        self.emailSubject = emailSubject
        self.emailDate = emailDate
        self.retailer = retailer
        self.amount = amount
        self.confidence = confidence
        self.receiptId = receiptId
        self.itemCount = itemCount
        self.importDate = importDate
    }
}

/// Record of an import error
public struct ImportErrorRecord: Identifiable, Codable {
    public let id: UUID
    public let emailId: String
    public let emailSubject: String
    public let errorType: ImportErrorType
    public let errorMessage: String
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        emailId: String,
        emailSubject: String,
        errorType: ImportErrorType,
        errorMessage: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.emailId = emailId
        self.emailSubject = emailSubject
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.timestamp = timestamp
    }
}

/// Types of import errors
public enum ImportErrorType: String, Codable, CaseIterable {
    case lowConfidence = "Low Confidence"
    case parsingError = "Parsing Error"
    case duplicateReceipt = "Duplicate Receipt"
    case networkError = "Network Error"
    case authenticationError = "Authentication Error"
    case unknown = "Unknown Error"
    
    public var iconName: String {
        switch self {
        case .lowConfidence:
            return "questionmark.circle"
        case .parsingError:
            return "doc.text.magnifyingglass"
        case .duplicateReceipt:
            return "doc.on.doc"
        case .networkError:
            return "wifi.slash"
        case .authenticationError:
            return "lock.circle"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
}

/// Statistics for import history
public struct ImportStatistics {
    public let totalSessions: Int
    public let totalEmailsProcessed: Int
    public let totalReceiptsImported: Int
    public let totalErrors: Int
    public let averageSuccessRate: Double
    public let mostCommonRetailers: [(retailer: String, count: Int)]
    public let importsByMonth: [(month: Date, count: Int)]
    
    public init(sessions: [ImportSession]) {
        self.totalSessions = sessions.count
        self.totalEmailsProcessed = sessions.reduce(0) { $0 + $1.totalEmails }
        self.totalReceiptsImported = sessions.reduce(0) { $0 + $1.successfulImports }
        self.totalErrors = sessions.reduce(0) { $0 + $1.failedImports }
        
        // Calculate average success rate
        let totalSuccess = sessions.reduce(0) { $0 + $1.successfulImports }
        let totalAttempts = sessions.reduce(0) { $0 + $1.totalEmails }
        self.averageSuccessRate = totalAttempts > 0 ? Double(totalSuccess) / Double(totalAttempts) : 0
        
        // Calculate most common retailers
        var retailerCounts: [String: Int] = [:]
        for session in sessions {
            for receipt in session.importedReceipts {
                retailerCounts[receipt.retailer, default: 0] += 1
            }
        }
        self.mostCommonRetailers = retailerCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
        
        // Calculate imports by month
        var monthCounts: [Date: Int] = [:]
        let calendar = Calendar.current
        for session in sessions {
            let monthStart = calendar.dateInterval(of: .month, for: session.startDate)?.start ?? session.startDate
            monthCounts[monthStart, default: 0] += session.successfulImports
        }
        self.importsByMonth = monthCounts
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }
}