//
//  GmailModule.swift
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
//  Dependencies: Foundation, SwiftUI, Core, GoogleSignIn
//  Testing: GmailTests/GmailModuleTests.swift
//
//  Description: Main Gmail module implementation with Google Sign-In integration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import Core
import GoogleSignIn

/// Main Gmail module implementation
public final class GmailModule: ObservableObject, GmailModuleAPI {
    @Published public var isAuthenticated: Bool = false
    
    private let authService: GmailAuthService
    private let gmailAPI: SimpleGmailAPI
    let bridge: GmailBridge
    
    public init() {
        // Configure Google Sign-In if not already configured
        if GIDSignIn.sharedInstance.configuration == nil {
            if let path = Bundle.module.path(forResource: "GoogleServices", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let clientId = plist["CLIENT_ID"] as? String {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
                print("[GmailModule] Google Sign-In configured with client ID: \(clientId)")
            } else {
                print("[GmailModule] Warning: GoogleServices.plist not found in module bundle")
            }
        }
        
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
        return emails.compactMap { email -> Receipt? in
            guard let receiptInfo = email.receiptInfo else { return nil }
            
            return Receipt(
                id: UUID(),
                storeName: receiptInfo.retailer,
                date: email.date,
                totalAmount: Decimal(receiptInfo.totalAmount ?? 0),
                itemIds: [],
                imageData: nil,
                rawText: email.body,
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