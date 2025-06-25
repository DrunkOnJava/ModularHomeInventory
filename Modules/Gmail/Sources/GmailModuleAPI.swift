// GmailModuleAPI.swift
// Gmail Module Public API
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6

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