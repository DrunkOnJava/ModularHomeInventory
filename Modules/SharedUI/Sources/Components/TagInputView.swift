//
//  TagInputView.swift
//  HomeInventoryModular
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
//  Module: SharedUI
//  Dependencies: SwiftUI, Core
//  Testing: Modules/SharedUI/Tests/SharedUITests/TagInputViewTests.swift
//
//  Description: Tag input component for selecting and managing item tags with search functionality
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

public struct TagInputView: View {
    @Binding var selectedTags: [String]
    @State private var newTag = ""
    @State private var showingTagPicker = false
    @FocusState private var isInputFocused: Bool
    
    let availableTags: [Tag]
    
    public init(selectedTags: Binding<[String]>, availableTags: [Tag] = Tag.previews) {
        self._selectedTags = selectedTags
        self.availableTags = availableTags
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Selected tags
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(selectedTags, id: \.self) { tagName in
                            TagChip(
                                name: tagName,
                                color: colorForTag(tagName),
                                onDelete: { removeTag(tagName) }
                            )
                        }
                    }
                }
            }
            
            // Add tag input
            HStack {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(AppColors.textTertiary)
                        .font(.footnote)
                    
                    TextField("Add tag", text: $newTag)
                        .textInputAutocapitalization(.never)
                        .focused($isInputFocused)
                        .onSubmit {
                            addTag()
                        }
                }
                .appPadding(.horizontal, AppSpacing.sm)
                .appPadding(.vertical, AppSpacing.xs)
                .background(AppColors.surface)
                .cornerRadius(8)
                
                Button(action: { showingTagPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColors.primary)
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerView(
                availableTags: availableTags,
                selectedTags: $selectedTags
            )
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty,
              !selectedTags.contains(trimmedTag) else { return }
        
        selectedTags.append(trimmedTag)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
    
    private func colorForTag(_ tagName: String) -> Color {
        // Try to find a matching tag in available tags
        if let tag = availableTags.first(where: { $0.name == tagName }) {
            return Color.named(tag.color)
        }
        // Generate a consistent color based on the tag name
        let hash = tagName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}

public struct TagChip: View {
    let name: String
    let color: Color
    let onDelete: () -> Void
    
    public init(name: String, color: Color, onDelete: @escaping () -> Void) {
        self.name = name
        self.color = color
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(name)
                .textStyle(.labelSmall)
                .foregroundStyle(.white)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .appPadding(.horizontal, AppSpacing.sm)
        .appPadding(.vertical, AppSpacing.xxs)
        .background(color)
        .cornerRadius(12)
    }
}

struct TagPickerView: View {
    let availableTags: [Tag]
    @Binding var selectedTags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredTags: [Tag] {
        if searchText.isEmpty {
            return availableTags
        }
        return availableTags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTags) { tag in
                    TagPickerRow(
                        tag: tag,
                        isSelected: selectedTags.contains(tag.name),
                        onToggle: { toggleTag(tag) }
                    )
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.name) {
            selectedTags.removeAll { $0 == tag.name }
        } else {
            selectedTags.append(tag.name)
        }
    }
}

struct TagPickerRow: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                HStack(spacing: AppSpacing.sm) {
                    if let icon = tag.icon {
                        Image(systemName: icon)
                            .foregroundStyle(.white)
                            .font(.caption)
                            .frame(width: 24, height: 24)
                            .background(Color.named(tag.color))
                            .cornerRadius(6)
                    }
                    
                    Text(tag.name)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}