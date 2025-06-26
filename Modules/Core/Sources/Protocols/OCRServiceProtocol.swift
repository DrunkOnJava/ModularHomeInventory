//
//  OCRServiceProtocol.swift
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
//  Dependencies: Foundation, UIKit
//  Testing: Modules/Core/Tests/CoreTests/OCRServiceProtocolTests.swift
//
//  Description: Protocol for OCR text recognition services with receipt parsing capabilities
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Protocol for OCR (Optical Character Recognition) service
/// Swift 5.9 - No Swift 6 features
public protocol OCRServiceProtocol {
    #if canImport(UIKit)
    /// Extract text from an image
    func extractText(from image: UIImage) async throws -> OCRResult
    
    /// Extract structured receipt data from an image
    func extractReceiptData(from image: UIImage) async throws -> OCRReceiptData?
    #endif
}

/// OCR extraction result
public struct OCRResult {
    public let text: String
    public let confidence: Double
    public let language: String?
    public let regions: [OCRTextRegion]
    
    public init(
        text: String,
        confidence: Double,
        language: String? = nil,
        regions: [OCRTextRegion] = []
    ) {
        self.text = text
        self.confidence = confidence
        self.language = language
        self.regions = regions
    }
}

/// Text region identified by OCR
public struct OCRTextRegion {
    public let text: String
    public let confidence: Double
    #if canImport(UIKit)
    public let boundingBox: CGRect
    
    public init(text: String, confidence: Double, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
    #else
    public init(text: String, confidence: Double) {
        self.text = text
        self.confidence = confidence
    }
    #endif
}

/// Structured receipt data from OCR
public struct OCRReceiptData {
    public let storeName: String?
    public let date: Date?
    public let totalAmount: Decimal?
    public let items: [OCRReceiptItem]
    public let confidence: Double
    public let rawText: String
    
    public init(
        storeName: String? = nil,
        date: Date? = nil,
        totalAmount: Decimal? = nil,
        items: [OCRReceiptItem] = [],
        confidence: Double,
        rawText: String
    ) {
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.items = items
        self.confidence = confidence
        self.rawText = rawText
    }
}

/// Individual item from OCR receipt
public struct OCRReceiptItem {
    public let name: String
    public let price: Decimal?
    public let quantity: Int?
    
    public init(name: String, price: Decimal? = nil, quantity: Int? = nil) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}