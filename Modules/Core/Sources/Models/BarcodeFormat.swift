//
//  BarcodeFormat.swift
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
//  Dependencies: Foundation, AVFoundation
//  Testing: Modules/Core/Tests/CoreTests/BarcodeFormatTests.swift
//
//  Description: Comprehensive barcode format support with metadata and validation utilities
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import AVFoundation

/// Comprehensive barcode format support
/// Swift 5.9 - No Swift 6 features
public struct BarcodeFormat {
    public let metadataObjectType: AVMetadataObject.ObjectType
    public let name: String
    public let description: String
    public let example: String
    public let isCommon: Bool
    
    /// All supported barcode formats
    public static let allFormats: [BarcodeFormat] = [
        // 1D Barcodes - Linear
        BarcodeFormat(
            metadataObjectType: .ean13,
            name: "EAN-13",
            description: "European Article Number, used globally for retail",
            example: "5901234123457",
            isCommon: true
        ),
        BarcodeFormat(
            metadataObjectType: .ean8,
            name: "EAN-8",
            description: "Shortened EAN for small packages",
            example: "96385074",
            isCommon: true
        ),
        BarcodeFormat(
            metadataObjectType: .upce,
            name: "UPC-E",
            description: "Universal Product Code (compressed)",
            example: "01234565",
            isCommon: true
        ),
        BarcodeFormat(
            metadataObjectType: .code39,
            name: "Code 39",
            description: "Used in automotive and defense industries",
            example: "CODE39",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .code39Mod43,
            name: "Code 39 Mod 43",
            description: "Code 39 with check digit",
            example: "CODE39+",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .code93,
            name: "Code 93",
            description: "Compact version of Code 39",
            example: "CODE93",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .code128,
            name: "Code 128",
            description: "High-density barcode for alphanumeric data",
            example: "Code128Example",
            isCommon: true
        ),
        BarcodeFormat(
            metadataObjectType: .interleaved2of5,
            name: "Interleaved 2 of 5",
            description: "Used for shipping containers",
            example: "1234567890",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .itf14,
            name: "ITF-14",
            description: "Used for packaging levels of retail",
            example: "12345678901231",
            isCommon: false
        ),
        
        // 2D Barcodes
        BarcodeFormat(
            metadataObjectType: .qr,
            name: "QR Code",
            description: "Quick Response code, versatile 2D barcode",
            example: "https://example.com",
            isCommon: true
        ),
        BarcodeFormat(
            metadataObjectType: .dataMatrix,
            name: "Data Matrix",
            description: "2D code for small items",
            example: "DataMatrix123",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .pdf417,
            name: "PDF417",
            description: "Used in transport, ID cards, inventory",
            example: "PDF417Data",
            isCommon: false
        ),
        BarcodeFormat(
            metadataObjectType: .aztec,
            name: "Aztec",
            description: "2D code used for tickets and boarding passes",
            example: "AztecData",
            isCommon: false
        )
    ]
    
    /// Get all metadata object types
    public static var allMetadataTypes: [AVMetadataObject.ObjectType] {
        allFormats.map { $0.metadataObjectType }
    }
    
    /// Get common format metadata types
    public static var commonMetadataTypes: [AVMetadataObject.ObjectType] {
        allFormats.filter { $0.isCommon }.map { $0.metadataObjectType }
    }
    
    /// Get format by metadata type
    public static func format(for type: AVMetadataObject.ObjectType) -> BarcodeFormat? {
        allFormats.first { $0.metadataObjectType == type }
    }
    
    /// Validate barcode format
    public static func validate(barcode: String, type: AVMetadataObject.ObjectType) -> Bool {
        switch type {
        case .ean13:
            return validateEAN13(barcode)
        case .ean8:
            return validateEAN8(barcode)
        case .upce:
            return validateUPCE(barcode)
        case .code128:
            return !barcode.isEmpty && barcode.count <= 128
        case .qr:
            return !barcode.isEmpty
        case .code39, .code39Mod43:
            return validateCode39(barcode)
        case .code93:
            return !barcode.isEmpty
        case .interleaved2of5:
            return barcode.allSatisfy { $0.isNumber } && barcode.count % 2 == 0
        case .itf14:
            return barcode.count == 14 && barcode.allSatisfy { $0.isNumber }
        case .dataMatrix, .pdf417, .aztec:
            return !barcode.isEmpty
        default:
            return true
        }
    }
    
    // MARK: - Validation Methods
    
    private static func validateEAN13(_ barcode: String) -> Bool {
        guard barcode.count == 13, barcode.allSatisfy({ $0.isNumber }) else { return false }
        return validateChecksum(barcode)
    }
    
    private static func validateEAN8(_ barcode: String) -> Bool {
        guard barcode.count == 8, barcode.allSatisfy({ $0.isNumber }) else { return false }
        return validateChecksum(barcode)
    }
    
    private static func validateUPCE(_ barcode: String) -> Bool {
        guard barcode.count == 8, barcode.allSatisfy({ $0.isNumber }) else { return false }
        return true // UPC-E has complex expansion rules
    }
    
    private static func validateCode39(_ barcode: String) -> Bool {
        let validChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%"
        return barcode.allSatisfy { validChars.contains($0) }
    }
    
    private static func validateChecksum(_ barcode: String) -> Bool {
        let digits = barcode.compactMap { Int(String($0)) }
        guard digits.count == barcode.count else { return false }
        
        var sum = 0
        for (index, digit) in digits.dropLast().enumerated() {
            sum += digit * (index % 2 == 0 ? 1 : 3)
        }
        
        let checkDigit = (10 - (sum % 10)) % 10
        return checkDigit == digits.last
    }
}

// MARK: - Format Groups
public extension BarcodeFormat {
    enum FormatGroup: String, CaseIterable {
        case retail = "Retail"
        case industrial = "Industrial"
        case twoDimensional = "2D Codes"
        
        public var formats: [BarcodeFormat] {
            switch self {
            case .retail:
                return BarcodeFormat.allFormats.filter { 
                    [.ean13, .ean8, .upce, .code128].contains($0.metadataObjectType)
                }
            case .industrial:
                return BarcodeFormat.allFormats.filter {
                    [.code39, .code39Mod43, .code93, .interleaved2of5, .itf14].contains($0.metadataObjectType)
                }
            case .twoDimensional:
                return BarcodeFormat.allFormats.filter {
                    [.qr, .dataMatrix, .pdf417, .aztec].contains($0.metadataObjectType)
                }
            }
        }
    }
}