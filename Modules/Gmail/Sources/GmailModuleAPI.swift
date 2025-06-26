//
//  GmailModuleAPI.swift
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
//  Dependencies: Foundation, SwiftUI, Core
//  Testing: GmailTests/GmailModuleAPITests.swift
//
//  Description: Public API protocol for Gmail module integration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import Core

/// Public API for the Gmail module
public protocol GmailModuleAPI {
    /// Make the main Gmail view
    func makeGmailView() -> AnyView
    
    /// Make the receipt import view
    func makeReceiptImportView() -> AnyView
    
    /// Make the Gmail settings view
    func makeGmailSettingsView() -> AnyView
    
    /// Check if user is authenticated
    var isAuthenticated: Bool { get }
    
    /// Sign out from Gmail
    func signOut()
    
    /// Fetch receipts from Gmail
    func fetchReceipts() async throws -> [Receipt]
}

/// Gmail module error types
public enum GmailError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case parsingError
    case quotaExceeded
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to Gmail"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse email content"
        case .quotaExceeded:
            return "Gmail API quota exceeded. Please try again later"
        case .invalidConfiguration:
            return "Invalid Gmail configuration"
        }
    }
}