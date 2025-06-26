//
//  ViewOnlyShareView.swift
//  Core
//
//  View for creating and managing view-only sharing links
//

import SwiftUI

public struct ViewOnlyShareView: View {
    @StateObject private var viewOnlyService = ViewOnlyModeService.shared
    @Environment(\.dismiss) private var dismiss
    
    let items: [Item]
    
    @State private var settings = ViewOnlyModeService.ViewOnlySettings()
    @State private var showingGeneratedLink = false
    @State private var generatedLink: ViewOnlyModeService.SharedLink?
    @State private var showingError = false
    @State private var showingCopiedAlert = false
    
    // Password entry
    @State private var passwordEntry = ""
    @State private var confirmPassword = ""
    
    // Expiration
    @State private var hasExpiration = false
    @State private var expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week default
    
    // View limit
    @State private var hasViewLimit = false
    @State private var maxViews = 10
    
    public init(items: [Item]) {
        self.items = items
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Items Summary
                itemsSummarySection
                
                // Privacy Settings
                privacySettingsSection
                
                // Security Settings
                securitySettingsSection
                
                // Expiration Settings
                expirationSection
                
                // View Limit Settings
                viewLimitSection
                
                // Watermark Settings
                watermarkSection
                
                // Generate Button
                generateSection
            }
            .navigationTitle("Share View-Only")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGeneratedLink) {
                if let link = generatedLink {
                    GeneratedLinkView(link: link, onDismiss: { dismiss() })
                }
            }
            .alert("Sharing Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(viewOnlyService.error?.localizedDescription ?? "An error occurred while generating the share link")
            }
            .alert("Link Copied", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("The sharing link has been copied to your clipboard")
            }
        }
    }
    
    // MARK: - Sections
    
    private var itemsSummarySection: some View {
        Section {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                Text("\(items.count) item\(items.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
            }
            
            if items.count <= 3 {
                ForEach(items.prefix(3)) { item in
                    Text("• \(item.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(items.prefix(2)) { item in
                    Text("• \(item.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("• and \(items.count - 2) more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Items to Share")
        }
    }
    
    private var privacySettingsSection: some View {
        Section {
            Toggle("Allow Photos", isOn: $settings.allowPhotos)
            Toggle("Show Prices", isOn: $settings.allowPrices)
            Toggle("Show Locations", isOn: $settings.allowLocations)
            Toggle("Show Serial Numbers", isOn: $settings.allowSerialNumbers)
            Toggle("Show Receipts", isOn: $settings.allowReceipts)
            Toggle("Show Notes", isOn: $settings.allowNotes)
            Toggle("Show Warranty Info", isOn: $settings.allowWarrantyInfo)
        } header: {
            Text("Privacy Settings")
        } footer: {
            Text("Control what information is visible in the shared view")
        }
    }
    
    private var securitySettingsSection: some View {
        Section {
            Toggle("Require Password", isOn: $settings.requirePassword)
            
            if settings.requirePassword {
                SecureField("Password", text: $passwordEntry)
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                
                if !passwordEntry.isEmpty && passwordEntry != confirmPassword {
                    Label("Passwords don't match", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Security")
        } footer: {
            if settings.requirePassword {
                Text("Recipients will need this password to view the shared items")
            }
        }
    }
    
    private var expirationSection: some View {
        Section {
            Toggle("Set Expiration Date", isOn: $hasExpiration)
            
            if hasExpiration {
                DatePicker(
                    "Expires On",
                    selection: $expirationDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        } header: {
            Text("Expiration")
        } footer: {
            if hasExpiration {
                Text("The link will stop working after this date")
            }
        }
    }
    
    private var viewLimitSection: some View {
        Section {
            Toggle("Limit Number of Views", isOn: $hasViewLimit)
            
            if hasViewLimit {
                Stepper("Max Views: \(maxViews)", value: $maxViews, in: 1...100)
            }
        } header: {
            Text("View Limit")
        } footer: {
            if hasViewLimit {
                Text("The link will stop working after being viewed this many times")
            }
        }
    }
    
    private var watermarkSection: some View {
        Section {
            TextField("Watermark Text (Optional)", text: $settings.watermarkText)
                .textContentType(.none)
        } header: {
            Text("Watermark")
        } footer: {
            Text("This text will appear as a watermark on shared content")
        }
    }
    
    private var generateSection: some View {
        Section {
            Button(action: generateShareLink) {
                if viewOnlyService.isGeneratingLink {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Generating Link...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Generate Share Link", systemImage: "link.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!isValidConfiguration || viewOnlyService.isGeneratingLink)
        }
    }
    
    // MARK: - Validation
    
    private var isValidConfiguration: Bool {
        if settings.requirePassword {
            guard !passwordEntry.isEmpty,
                  passwordEntry == confirmPassword else {
                return false
            }
        }
        return true
    }
    
    // MARK: - Actions
    
    private func generateShareLink() {
        // Update settings
        if settings.requirePassword {
            settings.password = passwordEntry
        }
        
        if hasExpiration {
            settings.expirationDate = expirationDate
        }
        
        if hasViewLimit {
            settings.maxViews = maxViews
        }
        
        Task {
            do {
                let link = try await viewOnlyService.generateShareLink(
                    for: items,
                    settings: settings
                )
                
                await MainActor.run {
                    generatedLink = link
                    showingGeneratedLink = true
                }
            } catch {
                await MainActor.run {
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Generated Link View

private struct GeneratedLinkView: View {
    let link: ViewOnlyModeService.SharedLink
    let onDismiss: () -> Void
    
    @State private var showingShareSheet = false
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Share Link Created!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Link Display
                VStack(spacing: 12) {
                    Text("Share this link:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(link.shareableURL.absoluteString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .onTapGesture {
                            copyToClipboard()
                        }
                }
                .padding(.horizontal)
                
                // Link Details
                VStack(alignment: .leading, spacing: 8) {
                    if let expiresAt = link.expiresAt {
                        Label("Expires: \(expiresAt, style: .relative)", systemImage: "clock")
                            .font(.caption)
                    }
                    
                    if link.settings.requirePassword {
                        Label("Password protected", systemImage: "lock.fill")
                            .font(.caption)
                    }
                    
                    if let maxViews = link.settings.maxViews {
                        Label("Limited to \(maxViews) views", systemImage: "eye")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingShareSheet = true }) {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: copyToClipboard) {
                        Label(copiedToClipboard ? "Copied!" : "Copy Link", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Share Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [link.shareableURL])
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = link.shareableURL.absoluteString
        
        withAnimation {
            copiedToClipboard = true
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ViewOnlyShareView(items: [Item.preview])
}