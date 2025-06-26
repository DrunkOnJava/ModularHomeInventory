//
//  SharedLinksManagementView.swift
//  Core
//
//  View for managing active shared links
//

import SwiftUI

public struct SharedLinksManagementView: View {
    @StateObject private var viewOnlyService = ViewOnlyModeService.shared
    @State private var showingRevokeAlert = false
    @State private var linkToRevoke: ViewOnlyModeService.SharedLink?
    @State private var searchText = ""
    
    private var filteredLinks: [ViewOnlyModeService.SharedLink] {
        if searchText.isEmpty {
            return viewOnlyService.sharedLinks
        } else {
            return viewOnlyService.sharedLinks.filter { link in
                link.shortCode.localizedCaseInsensitiveContains(searchText) ||
                link.itemIds.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var activeLinks: [ViewOnlyModeService.SharedLink] {
        filteredLinks.filter { $0.isActive && ($0.expiresAt == nil || $0.expiresAt! > Date()) }
    }
    
    private var expiredLinks: [ViewOnlyModeService.SharedLink] {
        filteredLinks.filter { !$0.isActive || ($0.expiresAt != nil && $0.expiresAt! <= Date()) }
    }
    
    public var body: some View {
        NavigationView {
            List {
                if !searchText.isEmpty && filteredLinks.isEmpty {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("No shared links match '\(searchText)'")
                    }
                } else {
                    if !activeLinks.isEmpty {
                        activeLinkSection
                    }
                    
                    if !expiredLinks.isEmpty {
                        expiredLinkSection
                    }
                    
                    if viewOnlyService.sharedLinks.isEmpty {
                        ContentUnavailableView {
                            Label("No Shared Links", systemImage: "link.badge.plus")
                        } description: {
                            Text("Create a share link to allow others to view your items")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search links")
            .navigationTitle("Shared Links")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewOnlyService.sharedLinks.isEmpty {
                        EditButton()
                    }
                }
            }
            .alert("Revoke Link?", isPresented: $showingRevokeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Revoke", role: .destructive) {
                    if let link = linkToRevoke {
                        revokeLink(link)
                    }
                }
            } message: {
                Text("This will immediately disable the shared link. Anyone with the link will no longer be able to access the shared items.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var activeLinkSection: some View {
        Section {
            ForEach(activeLinks) { link in
                SharedLinkRow(link: link) {
                    linkToRevoke = link
                    showingRevokeAlert = true
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let link = activeLinks[index]
                    revokeLink(link)
                }
            }
        } header: {
            Label("Active Links (\(activeLinks.count))", systemImage: "link.circle.fill")
        }
    }
    
    private var expiredLinkSection: some View {
        Section {
            ForEach(expiredLinks) { link in
                SharedLinkRow(link: link, isExpired: true) {
                    // No action for expired links
                }
            }
            .onDelete { indexSet in
                // Remove expired links from local storage
                for index in indexSet {
                    let link = expiredLinks[index]
                    if let mainIndex = viewOnlyService.sharedLinks.firstIndex(where: { $0.id == link.id }) {
                        viewOnlyService.sharedLinks.remove(at: mainIndex)
                    }
                }
            }
        } header: {
            Label("Expired Links (\(expiredLinks.count))", systemImage: "link.badge.xmark")
        } footer: {
            Text("Expired links are kept for your records but can be deleted")
        }
    }
    
    // MARK: - Actions
    
    private func revokeLink(_ link: ViewOnlyModeService.SharedLink) {
        Task {
            do {
                try await viewOnlyService.revokeLink(link)
            } catch {
                // Handle error
                print("Failed to revoke link: \(error)")
            }
        }
    }
}

// MARK: - Shared Link Row

private struct SharedLinkRow: View {
    let link: ViewOnlyModeService.SharedLink
    var isExpired: Bool = false
    let onRevoke: () -> Void
    
    @State private var showingCopyAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Link Code and Status
            HStack {
                Text(link.shortCode)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                
                Spacer()
                
                if isExpired {
                    Label("Expired", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Link Details
            HStack(spacing: 16) {
                // Created Date
                Label {
                    Text(link.createdAt, style: .relative)
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Item Count
                Label {
                    Text("\(link.itemIds.count) items")
                } icon: {
                    Image(systemName: "doc.text")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // View Count
                Label {
                    Text("\(link.viewCount) views")
                } icon: {
                    Image(systemName: "eye")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Security Features
            HStack(spacing: 8) {
                if link.settings.requirePassword {
                    Label("Password", systemImage: "lock.fill")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                if let expiresAt = link.expiresAt {
                    Label("Expires \(expiresAt, style: .relative)", systemImage: "clock")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                
                if let maxViews = link.settings.maxViews {
                    Label("\(maxViews - link.viewCount) views left", systemImage: "eye.slash")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }
            
            // Actions
            if !isExpired {
                HStack(spacing: 12) {
                    Button(action: copyLink) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Revoke", action: onRevoke)
                        .font(.caption)
                        .foregroundColor(.red)
                        .buttonStyle(.bordered)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .alert("Link Copied", isPresented: $showingCopyAlert) {
            Button("OK") { }
        } message: {
            Text("The sharing link has been copied to your clipboard")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [link.shareableURL])
        }
    }
    
    private func copyLink() {
        UIPasteboard.general.string = link.shareableURL.absoluteString
        showingCopyAlert = true
    }
}

// MARK: - Preview

#Preview {
    SharedLinksManagementView()
}