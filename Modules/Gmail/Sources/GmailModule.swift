// GmailModule.swift
// Gmail Module Implementation
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6

import Foundation
import SwiftUI
import Core
import GoogleSignIn

/// Errors that can occur during Gmail operations
public enum GmailError: LocalizedError {
    case notAuthenticated
    case fetchFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to Gmail to access your receipts"
        case .fetchFailed(let message):
            return "Failed to fetch receipts: \(message)"
        }
    }
}

/// Main Gmail module implementation
public final class GmailModule: ObservableObject, GmailModuleAPI {
    @Published public var isAuthenticated: Bool = false
    
    private let authService: GmailAuthService
    private let gmailAPI: SimpleGmailAPI
    let bridge: GmailBridge
    
    public init() {
        self.bridge = GmailBridge()
        self.authService = bridge.authService
        self.gmailAPI = bridge.gmailAPI
        
        // Set up authentication state observation
        setupAuthObservation()
    }
    
    private func setupAuthObservation() {
        // Check initial auth state
        if let user = GIDSignIn.sharedInstance.currentUser {
            isAuthenticated = user.grantedScopes?.contains("https://www.googleapis.com/auth/gmail.readonly") ?? false
        }
        
        // Restore previous sign-in if available
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = user.grantedScopes?.contains("https://www.googleapis.com/auth/gmail.readonly") ?? false
                }
            }
        }
    }
    
    // MARK: - GmailModuleAPI
    
    public func makeGmailView() -> AnyView {
        AnyView(
            IntegratedGmailView()
                .environmentObject(bridge)
        )
    }
    
    public func makeReceiptImportView() -> AnyView {
        AnyView(
            GmailReceiptsView()
                .environmentObject(bridge)
        )
    }
    
    public func makeGmailSettingsView() -> AnyView {
        AnyView(
            GmailSettingsView()
                .environmentObject(self)
        )
    }
    
    public func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        bridge.signOut()
    }
    
    public func fetchReceipts() async throws -> [Receipt] {
        guard isAuthenticated else {
            throw GmailError.notAuthenticated
        }
        
        // Fetch emails
        let emails = try await bridge.fetchReceiptEmails()
        
        // Convert to Core.Receipt model
        return emails.compactMap { email in
            guard let receiptInfo = email.receiptInfo else { return nil }
            
            return Receipt(
                id: UUID(),
                retailer: receiptInfo.retailer,
                purchaseDate: email.date,
                totalAmount: receiptInfo.totalAmount ?? 0,
                itemCount: receiptInfo.items?.count ?? 0,
                category: categorizeRetailer(receiptInfo.retailer),
                storageService: "Gmail",
                storagePath: email.id,
                notes: "Order #\(receiptInfo.orderNumber ?? "")",
                ocrText: email.body,
                confidence: receiptInfo.confidence,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    private func categorizeRetailer(_ retailer: String) -> String {
        switch retailer.lowercased() {
        case _ where retailer.contains("amazon"):
            return "Online Shopping"
        case _ where retailer.contains("walmart"), _ where retailer.contains("target"):
            return "General Retail"
        case _ where retailer.contains("cvs"), _ where retailer.contains("walgreens"):
            return "Pharmacy"
        case _ where retailer.contains("uber"), _ where retailer.contains("lyft"):
            return "Transportation"
        case _ where retailer.contains("doordash"), _ where retailer.contains("grubhub"):
            return "Food Delivery"
        case _ where retailer.contains("netflix"), _ where retailer.contains("spotify"):
            return "Subscriptions"
        default:
            return "Other"
        }
    }
}

// MARK: - Gmail Settings View

struct GmailSettingsView: View {
    @EnvironmentObject var module: GmailModule
    @State private var showingSignIn = false
    
    var body: some View {
        List {
            Section {
                if module.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected to Gmail")
                        Spacer()
                    }
                    
                    Button(action: {
                        module.signOut()
                    }) {
                        Label("Sign Out", systemImage: "arrow.left.circle")
                            .foregroundColor(.red)
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Not Connected")
                        Spacer()
                    }
                    
                    Button(action: {
                        showingSignIn = true
                    }) {
                        Label("Connect Gmail", systemImage: "envelope.circle")
                    }
                }
            } header: {
                Text("Gmail Account")
            }
            
            Section {
                HStack {
                    Text("Permissions")
                    Spacer()
                    Text("Read-only access")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Scope")
                    Spacer()
                    Text("Email receipts")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Access Information")
            } footer: {
                Text("Home Inventory only reads receipt and purchase emails. Your personal emails remain private.")
            }
        }
        .navigationTitle("Gmail Settings")
        .sheet(isPresented: $showingSignIn) {
            SignInView()
                .environmentObject(module.bridge)
        }
    }
}