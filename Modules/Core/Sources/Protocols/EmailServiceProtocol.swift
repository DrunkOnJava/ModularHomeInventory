//
//  EmailServiceProtocol.swift
//  HomeInventoryModular
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
//  Testing: Modules/Core/Tests/CoreTests/EmailServiceProtocolTests.swift
//
//  Description: Protocol definition for email parsing services with support structures for receipt extraction
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Protocol for email parsing service
/// Swift 5.9 - No Swift 6 features
public protocol EmailServiceProtocol {
    /// Fetch emails from a specific sender or matching criteria
    func fetchEmails(from sender: String?, matching criteria: String?) async throws -> [EmailMessage]
    
    /// Parse email content to extract receipt information
    func parseReceiptFromEmail(_ email: EmailMessage) async throws -> ParsedEmailReceipt?
}

/// Email message structure
public struct EmailMessage {
    public let id: String
    public let subject: String
    public let sender: String
    public let recipient: String
    public let date: Date
    public let body: String
    public let attachments: [EmailAttachment]
    
    public init(
        id: String,
        subject: String,
        sender: String,
        recipient: String,
        date: Date,
        body: String,
        attachments: [EmailAttachment] = []
    ) {
        self.id = id
        self.subject = subject
        self.sender = sender
        self.recipient = recipient
        self.date = date
        self.body = body
        self.attachments = attachments
    }
}

/// Email attachment structure
public struct EmailAttachment {
    public let name: String
    public let mimeType: String
    public let data: Data
    
    public init(name: String, mimeType: String, data: Data) {
        self.name = name
        self.mimeType = mimeType
        self.data = data
    }
}

/// Parsed receipt from email
public struct ParsedEmailReceipt {
    public let storeName: String
    public let date: Date
    public let totalAmount: Decimal
    public let confidence: Double
    public let rawData: String
    
    public init(
        storeName: String,
        date: Date,
        totalAmount: Decimal,
        confidence: Double,
        rawData: String
    ) {
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.confidence = confidence
        self.rawData = rawData
    }
}