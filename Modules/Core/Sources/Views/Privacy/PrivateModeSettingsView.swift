//
//  PrivateModeSettingsView.swift
//  Core
//
//  Settings for configuring private mode
//

import SwiftUI

@available(iOS 15.0, *)
public struct PrivateModeSettingsView: View {
    public init() {}
    @StateObject private var privateModeService = PrivateModeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDisableConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingAuthentication = false
    
    public var body: some View {
        NavigationView {
            Form {
                // Private Mode Toggle
                Section {
                    Toggle("Enable Private Mode", isOn: Binding(
                        get: { privateModeService.isPrivateModeEnabled },
                        set: { enabled in
                            if enabled {
                                privateModeService.enablePrivateMode()
                            } else {
                                showingDisableConfirmation = true
                            }
                        }
                    ))
                } footer: {
                    Text("Private mode allows you to hide sensitive items and information from unauthorized viewers")
                }
                
                if privateModeService.isPrivateModeEnabled {
                    // Authentication Settings
                    Section {
                        Toggle("Require Authentication", isOn: Binding(
                            get: { privateModeService.requireAuthenticationToView },
                            set: { privateModeService.updateSettings(requireAuth: $0) }
                        ))
                        
                        HStack {
                            Label("Session Timeout", systemImage: "clock")
                            Spacer()
                            Text(formatTimeout(privateModeService.sessionTimeout))
                                .foregroundColor(.secondary)
                        }
                        
                        if privateModeService.isAuthenticated {
                            HStack {
                                Label("Authenticated", systemImage: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                Spacer()
                                if let authTime = privateModeService.lastAuthenticationTime {
                                    Text(authTime, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Button(action: authenticate) {
                                Label("Authenticate Now", systemImage: "lock.open")
                            }
                        }
                    } header: {
                        Text("Authentication")
                    } footer: {
                        Text("Authentication is required to view private items")
                    }
                    
                    // Privacy Options
                    Section {
                        Toggle("Hide Values in Lists", isOn: Binding(
                            get: { privateModeService.hideValuesInLists },
                            set: { privateModeService.updateSettings(hideValues: $0) }
                        ))
                        
                        Toggle("Blur Photos in Lists", isOn: Binding(
                            get: { privateModeService.blurPhotosInLists },
                            set: { privateModeService.updateSettings(blurPhotos: $0) }
                        ))
                        
                        Toggle("Mask Serial Numbers", isOn: Binding(
                            get: { privateModeService.maskSerialNumbers },
                            set: { privateModeService.updateSettings(maskSerial: $0) }
                        ))
                    } header: {
                        Text("Display Options")
                    } footer: {
                        Text("Choose what information to hide when items are displayed in lists")
                    }
                    
                    // Visibility Settings
                    Section {
                        Toggle("Hide from Search", isOn: Binding(
                            get: { privateModeService.hideFromSearch },
                            set: { privateModeService.updateSettings(hideSearch: $0) }
                        ))
                        
                        Toggle("Hide from Analytics", isOn: Binding(
                            get: { privateModeService.hideFromAnalytics },
                            set: { privateModeService.updateSettings(hideAnalytics: $0) }
                        ))
                        
                        Toggle("Hide from Widgets", isOn: Binding(
                            get: { privateModeService.hideFromWidgets },
                            set: { privateModeService.updateSettings(hideWidgets: $0) }
                        ))
                    } header: {
                        Text("Visibility")
                    } footer: {
                        Text("Control where private items appear in the app")
                    }
                    
                    // Statistics
                    Section {
                        HStack {
                            Label("Private Items", systemImage: "lock.fill")
                            Spacer()
                            Text("\(privateModeService.privateItemIds.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Private Categories", systemImage: "folder.badge.questionmark")
                            Spacer()
                            Text("\(privateModeService.privateCategories.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Private Tags", systemImage: "tag.slash")
                            Spacer()
                            Text("\(privateModeService.privateTags.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        if !privateModeService.privateCategories.isEmpty ||
                           !privateModeService.privateTags.isEmpty {
                            NavigationLink(destination: PrivateCategoriesTagsView()) {
                                Label("Manage Private Categories & Tags", systemImage: "gear")
                            }
                        }
                    } header: {
                        Text("Statistics")
                    }
                }
            }
            .navigationTitle("Private Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Disable Private Mode", isPresented: $showingDisableConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Disable", role: .destructive) {
                    Task {
                        do {
                            try await privateModeService.disablePrivateMode()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to disable private mode? All hidden items will become visible.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func formatTimeout(_ timeout: TimeInterval) -> String {
        let minutes = Int(timeout / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
    
    private func authenticate() {
        Task {
            do {
                try await privateModeService.authenticate()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Private Categories & Tags View

@available(iOS 15.0, *)
struct PrivateCategoriesTagsView: View {
    @StateObject private var privateModeService = PrivateModeService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Type", selection: $selectedTab) {
                Text("Categories").tag(0)
                Text("Tags").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                // Categories list
                List {
                    ForEach(Array(privateModeService.privateCategories), id: \.self) { category in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(category)
                            Spacer()
                        }
                    }
                    .onDelete { indices in
                        for index in indices {
                            let category = Array(privateModeService.privateCategories)[index]
                            privateModeService.removeCategoryFromPrivate(category)
                        }
                    }
                }
            } else {
                // Tags list
                List {
                    ForEach(Array(privateModeService.privateTags), id: \.self) { tag in
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.purple)
                            Text(tag)
                            Spacer()
                        }
                    }
                    .onDelete { indices in
                        for index in indices {
                            let tag = Array(privateModeService.privateTags)[index]
                            privateModeService.removeTagFromPrivate(tag)
                        }
                    }
                }
            }
        }
        .navigationTitle("Private Categories & Tags")
        .navigationBarTitleDisplayMode(.inline)
    }
}