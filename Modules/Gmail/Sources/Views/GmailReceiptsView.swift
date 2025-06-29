//
//  GmailReceiptsView.swift
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
//  Dependencies: SwiftUI, GoogleSignIn
//  Testing: GmailTests/GmailReceiptsViewTests.swift
//
//  Description: Main view for displaying and managing Gmail receipts with search and filtering
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import GoogleSignIn

/// Main view for Gmail receipts using the old implementation
public struct GmailReceiptsView: View {
    @EnvironmentObject var bridge: GmailBridge
    @State private var selectedEmail: EmailMessage?
    @State private var searchText = ""
    @State private var showingSuccessMessage = false
    @State private var hasShownInitialFetch = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if bridge.authService.isAuthenticated {
                    receiptListView
                } else {
                    signInView
                }
            }
            .navigationTitle("Gmail Receipts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if bridge.authService.isAuthenticated {
                        Button("Sign Out") {
                            bridge.signOut()
                        }
                    }
                }
            }
            .onAppear {
                bridge.configure()
            }
            .onChange(of: bridge.authService.isAuthenticated) { oldValue, newValue in
                if !oldValue && newValue {
                    // User just authenticated
                    showingSuccessMessage = true
                    
                    // Fetch emails after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        bridge.fetchReceipts()
                    }
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingSuccessMessage = false
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showingSuccessMessage {
                successBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingSuccessMessage)
            }
        }
    }
    
    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Successfully connected to Gmail!")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Fetching your receipts...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.top, 50) // Account for status bar
    }
    
    private var signInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Sign in with Google")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Access your Gmail receipts and subscriptions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SignInButton(bridge: bridge)
            
            if let error = bridge.authService.error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
    
    private var receiptListView: some View {
        Group {
            if bridge.isLoading {
                ProgressView("Loading receipts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bridge.emails.isEmpty {
                emptyStateView
            } else {
                emailList
            }
        }
        .searchable(text: $searchText)
        .refreshable {
            bridge.fetchReceipts()
        }
        .onAppear {
            if bridge.emails.isEmpty {
                bridge.fetchReceipts()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No receipts found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Pull to refresh or check your Gmail for receipts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                bridge.fetchReceipts()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var emailList: some View {
        List {
            ForEach(filteredEmails) { email in
                EmailRowView(email: email)
                    .onTapGesture {
                        selectedEmail = email
                    }
            }
        }
        .sheet(item: $selectedEmail) { email in
            EmailDetailSheet(email: email)
        }
    }
    
    private var filteredEmails: [EmailMessage] {
        if searchText.isEmpty {
            return bridge.emails
        } else {
            return bridge.emails.filter { email in
                email.subject.localizedCaseInsensitiveContains(searchText) ||
                email.from.localizedCaseInsensitiveContains(searchText) ||
                (email.receiptInfo?.retailer.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
}

// MARK: - Email Row View

struct EmailRowView: View {
    let email: EmailMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(email.receiptInfo?.retailer ?? extractRetailer(from: email.from))
                        .font(.headline)
                    
                    Text(email.subject)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let amount = email.receiptInfo?.totalAmount {
                        Text("$\(String(format: "%.2f", amount))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Text(email.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(email.snippet)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private func extractRetailer(from: String) -> String {
        if let nameEnd = from.firstIndex(of: "<") {
            return String(from[..<nameEnd]).trimmingCharacters(in: .whitespaces)
        }
        return from
    }
}

// MARK: - Email Detail Sheet

struct EmailDetailSheet: View {
    let email: EmailMessage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(email.receiptInfo?.retailer ?? "Receipt")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(email.subject)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(email.from, systemImage: "envelope")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(email.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Receipt Info
                    if let receipt = email.receiptInfo {
                        VStack(alignment: .leading, spacing: 12) {
                            if let orderNumber = receipt.orderNumber {
                                HStack {
                                    Text("Order #")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(orderNumber)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let total = receipt.totalAmount {
                                HStack {
                                    Text("Total")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", total))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if !receipt.items.isEmpty {
                                Divider()
                                
                                Text("Items")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                ForEach(receipt.items, id: \.name) { item in
                                    HStack {
                                        Text(item.name)
                                            .lineLimit(2)
                                        Spacer()
                                        if let price = item.price {
                                            Text("$\(String(format: "%.2f", price))")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Email Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Content")
                            .font(.headline)
                        
                        Text(email.body)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sign In Button

struct SignInButton: UIViewRepresentable {
    let bridge: GmailBridge
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Sign In with Google", for: .normal)
        button.setImage(UIImage(systemName: "person.circle"), for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.addTarget(context.coordinator, action: #selector(Coordinator.signIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(bridge: bridge)
    }
    
    class Coordinator: NSObject {
        let bridge: GmailBridge
        
        init(bridge: GmailBridge) {
            self.bridge = bridge
        }
        
        @objc func signIn() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("Could not find root view controller")
                return
            }
            
            bridge.signIn(presentingViewController: rootViewController)
        }
    }
}
