//
//  ImportPreviewView.swift
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
//  Dependencies: SwiftUI, Core
//  Testing: GmailTests/ImportPreviewViewTests.swift
//
//  Description: Preview and confirm emails before importing as receipts
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// View for previewing and selecting emails to import as receipts
public struct ImportPreviewView: View {
    @EnvironmentObject var bridge: GmailBridge
    @State private var selectedEmails: Set<String> = []
    @State private var isProcessing = false
    @State private var showingImportConfirmation = false
    @State private var importedCount = 0
    @State private var searchText = ""
    @State private var filterConfidenceThreshold: Double = 0.7
    @State private var showOnlyReceipts = true
    
    private let classifier = EmailClassifier()
    
    var filteredEmails: [EmailMessage] {
        bridge.gmailAPI.emails.filter { email in
            let classification = classifier.classify(email)
            
            // Apply confidence filter
            if showOnlyReceipts && classification.confidence < filterConfidenceThreshold {
                return false
            }
            
            // Apply search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return email.subject.lowercased().contains(searchLower) ||
                       email.from.lowercased().contains(searchLower) ||
                       email.snippet.lowercased().contains(searchLower)
            }
            
            return true
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter controls
                VStack(spacing: 12) {
                    HStack {
                        Label("Show Receipts Only", systemImage: "doc.text.magnifyingglass")
                            .font(.subheadline)
                        Toggle("", isOn: $showOnlyReceipts)
                            .labelsHidden()
                    }
                    
                    if showOnlyReceipts {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Confidence Threshold")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(filterConfidenceThreshold * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $filterConfidenceThreshold, in: 0.5...1.0, step: 0.05)
                                .tint(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Email list
                if filteredEmails.isEmpty {
                    ContentUnavailableView(
                        "No Emails Found",
                        systemImage: "envelope.open",
                        description: Text("No emails match your current filters")
                    )
                } else {
                    List(filteredEmails, id: \.id) { email in
                        EmailPreviewRow(
                            email: email,
                            classification: classifier.classify(email),
                            isSelected: selectedEmails.contains(email.id),
                            onToggle: { toggleSelection(email.id) }
                        )
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchText, prompt: "Search emails")
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Dismiss view
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedEmails.isEmpty {
                        Button("Select All") {
                            selectAll()
                        }
                    } else {
                        Button("Import (\(selectedEmails.count))") {
                            showingImportConfirmation = true
                        }
                        .bold()
                    }
                }
            }
            .confirmationDialog(
                "Import Selected Emails?",
                isPresented: $showingImportConfirmation,
                titleVisibility: .visible
            ) {
                Button("Import \(selectedEmails.count) Receipt\(selectedEmails.count == 1 ? "" : "s")") {
                    importSelectedEmails()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will create receipts from the selected emails. You can review and edit them later.")
            }
            .overlay {
                if isProcessing {
                    ProcessingOverlay(message: "Importing receipts...")
                }
            }
        }
    }
    
    private func toggleSelection(_ emailId: String) {
        if selectedEmails.contains(emailId) {
            selectedEmails.remove(emailId)
        } else {
            selectedEmails.insert(emailId)
        }
    }
    
    private func selectAll() {
        selectedEmails = Set(filteredEmails.map { $0.id })
    }
    
    private func importSelectedEmails() {
        isProcessing = true
        importedCount = 0
        
        Task {
            for emailId in selectedEmails {
                if let email = filteredEmails.first(where: { $0.id == emailId }) {
                    let classification = classifier.classify(email)
                    if let extractedData = classification.extractedData {
                        // Create receipt from extracted data
                        // This would typically call a service to save the receipt
                        importedCount += 1
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
                // Show success message or navigate back
            }
        }
    }
}

// MARK: - Email Preview Row

struct EmailPreviewRow: View {
    let email: EmailMessage
    let classification: EmailClassifier.ClassificationResult
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
                .onTapGesture {
                    onToggle()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text(extractRetailerName())
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let amount = classification.extractedData?.totalAmount {
                        Text("$\(amount)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                
                // Subject
                Text(email.subject)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Date and confidence
                HStack {
                    Text(email.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ConfidenceBadge(confidence: classification.confidence)
                }
                
                // Preview snippet
                if !email.snippet.isEmpty {
                    Text(email.snippet)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    private func extractRetailerName() -> String {
        if let retailer = classification.extractedData?.retailer {
            return retailer
        }
        
        // Extract from sender
        let sender = email.from
        if let start = sender.firstIndex(of: "<"),
           let end = sender.firstIndex(of: "@") {
            let domain = String(sender[sender.index(after: start)..<end])
            return domain.capitalized
        }
        
        return sender.components(separatedBy: " ").first ?? "Unknown"
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double
    
    var color: Color {
        switch confidence {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield.fill")
                .font(.caption2)
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
}