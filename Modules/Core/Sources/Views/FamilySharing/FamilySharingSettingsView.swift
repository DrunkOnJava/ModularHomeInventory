//
//  FamilySharingSettingsView.swift
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
//  Dependencies: SwiftUI
//  Testing: CoreTests/FamilySharingSettingsViewTests.swift
//
//  Description: Settings view for configuring family sharing options with item visibility controls and notification preferences
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct FamilySharingSettingsView: View {
    @ObservedObject var sharingService: FamilySharingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var settings = FamilySharingService.ShareSettings()
    @State private var showingItemVisibilityPicker = false
    @State private var selectedCategories: Set<ItemCategory> = []
    @State private var selectedTags: Set<String> = []
    @State private var hasChanges = false
    @State private var isSaving = false
    
    public var body: some View {
        NavigationView {
            Form {
                // Family Name
                Section {
                    TextField("Family Name", text: $settings.familyName)
                        .onChange(of: settings.familyName) { _ in hasChanges = true }
                } header: {
                    Text("Family Name")
                } footer: {
                    Text("This name is visible to all family members")
                }
                
                // Sharing Options
                Section {
                    Toggle("Auto-accept from Contacts", isOn: $settings.autoAcceptFromContacts)
                        .onChange(of: settings.autoAcceptFromContacts) { _ in hasChanges = true }
                    
                    Toggle("Require Approval for Changes", isOn: $settings.requireApprovalForChanges)
                        .onChange(of: settings.requireApprovalForChanges) { _ in hasChanges = true }
                    
                    Toggle("Allow Guest Viewers", isOn: $settings.allowGuestViewers)
                        .onChange(of: settings.allowGuestViewers) { _ in hasChanges = true }
                } header: {
                    Text("Sharing Options")
                } footer: {
                    Text("Configure how family members can join and interact with shared items")
                }
                
                // Item Visibility
                Section {
                    HStack {
                        Text("Item Visibility")
                        Spacer()
                        Button(action: { showingItemVisibilityPicker = true }) {
                            HStack {
                                Text(settings.itemVisibility.rawValue)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if settings.itemVisibility == .categorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shared Categories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(ItemCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        toggleCategory(category)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if settings.itemVisibility == .tagged {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shared Tags")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Add tags to share items with those tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Tag input would go here
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Shared Items")
                } footer: {
                    Text(itemVisibilityDescription)
                }
                
                // Activity Notifications
                Section {
                    Toggle("Notify on New Items", isOn: .constant(true))
                    Toggle("Notify on Changes", isOn: .constant(true))
                    Toggle("Weekly Summary", isOn: .constant(false))
                } header: {
                    Text("Activity Notifications")
                }
                
                // Data & Privacy
                Section {
                    Button(action: downloadFamilyData) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Download Family Data")
                            Spacer()
                        }
                    }
                    
                    Button(action: showPrivacyInfo) {
                        HStack {
                            Image(systemName: "lock.circle")
                            Text("Privacy Information")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Data & Privacy")
                }
                
                // Danger Zone
                if case .owner = sharingService.shareStatus {
                    Section {
                        Button(action: stopFamilySharing) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Stop Family Sharing")
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("Stopping family sharing will remove access for all members and cannot be undone")
                    }
                }
            }
            .navigationTitle("Family Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .sheet(isPresented: $showingItemVisibilityPicker) {
                ItemVisibilityPicker(selection: $settings.itemVisibility)
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var itemVisibilityDescription: String {
        switch settings.itemVisibility {
        case .all:
            return "All items in your inventory are shared with family members"
        case .categorized:
            return "Only items in selected categories are shared"
        case .tagged:
            return "Only items with specific tags are shared"
        case .custom:
            return "Advanced sharing rules apply"
        }
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: ItemCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        hasChanges = true
    }
    
    private func saveSettings() {
        isSaving = true
        
        // In real implementation, would save via service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            hasChanges = false
            dismiss()
        }
    }
    
    private func downloadFamilyData() {
        // Implement data export
    }
    
    private func showPrivacyInfo() {
        // Show privacy information
    }
    
    private func stopFamilySharing() {
        // Show confirmation and stop sharing
    }
}

// MARK: - Item Visibility Picker

struct ItemVisibilityPicker: View {
    @Binding var selection: FamilySharingService.ShareSettings.ItemVisibility
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FamilySharingService.ShareSettings.ItemVisibility.allCases, id: \.self) { visibility in
                    Button(action: {
                        selection = visibility
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visibility.rawValue)
                                    .foregroundColor(.primary)
                                Text(description(for: visibility))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selection == visibility {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Item Visibility")
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
    
    private func description(for visibility: FamilySharingService.ShareSettings.ItemVisibility) -> String {
        switch visibility {
        case .all:
            return "Share your entire inventory"
        case .categorized:
            return "Share only specific categories"
        case .tagged:
            return "Share items with specific tags"
        case .custom:
            return "Advanced sharing rules"
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: ItemCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if x + viewSize.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += viewSize.width + spacing
                rowHeight = max(rowHeight, viewSize.height)
                size.width = max(size.width, x - spacing)
            }
            
            size.height = y + rowHeight
        }
    }
}