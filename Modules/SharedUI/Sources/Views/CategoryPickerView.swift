//
//  CategoryPickerView.swift
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
//  Testing: Modules/SharedUI/Tests/SharedUITests/CategoryPickerViewTests.swift
//
//  Description: A picker view for selecting categories with subcategory support and hierarchical navigation
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// A picker view for selecting categories with subcategory support
/// Swift 5.9 - No Swift 6 features
public struct CategoryPickerView: View {
    @Binding var selectedCategoryId: UUID
    let categoryRepository: any CategoryRepository
    @State private var categories: [ItemCategoryModel] = []
    @State private var subcategories: [UUID: [ItemCategoryModel]] = [:]
    @State private var expandedCategories: Set<UUID> = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedCategoryId: Binding<UUID>, categoryRepository: any CategoryRepository) {
        self._selectedCategoryId = selectedCategoryId
        self.categoryRepository = categoryRepository
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(categories.filter { $0.parentId == nil }) { category in
                    VStack(spacing: 0) {
                        // Parent category row
                        CategoryPickerRow(
                            category: category,
                            isSelected: selectedCategoryId == category.id,
                            hasSubcategories: !(subcategories[category.id]?.isEmpty ?? true),
                            isExpanded: expandedCategories.contains(category.id),
                            level: 0,
                            onSelect: {
                                selectedCategoryId = category.id
                                dismiss()
                            },
                            onToggleExpand: {
                                toggleExpanded(category.id)
                            }
                        )
                        
                        // Subcategories
                        if expandedCategories.contains(category.id),
                           let subs = subcategories[category.id] {
                            ForEach(subs) { subcategory in
                                CategoryPickerRow(
                                    category: subcategory,
                                    isSelected: selectedCategoryId == subcategory.id,
                                    hasSubcategories: false,
                                    isExpanded: false,
                                    level: 1,
                                    onSelect: {
                                        selectedCategoryId = subcategory.id
                                        dismiss()
                                    },
                                    onToggleExpand: { }
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCategories()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func toggleExpanded(_ categoryId: UUID) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
    }
    
    private func loadCategories() {
        Task {
            isLoading = true
            do {
                let allCategories = try await categoryRepository.fetchAll()
                
                // Sort root categories
                categories = allCategories.sorted { lhs, rhs in
                    // Built-in categories first
                    if lhs.isBuiltIn != rhs.isBuiltIn {
                        return lhs.isBuiltIn
                    }
                    // Then by sort order
                    if lhs.sortOrder != rhs.sortOrder {
                        return lhs.sortOrder < rhs.sortOrder
                    }
                    // Finally by name
                    return lhs.name < rhs.name
                }
                
                // Build subcategory map
                subcategories = [:]
                for category in allCategories {
                    if let parentId = category.parentId {
                        if subcategories[parentId] == nil {
                            subcategories[parentId] = []
                        }
                        subcategories[parentId]?.append(category)
                    }
                }
                
                // Sort subcategories
                for (parentId, subs) in subcategories {
                    subcategories[parentId] = subs.sorted { $0.sortOrder < $1.sortOrder }
                }
                
                // Auto-expand category containing selected item
                for (parentId, subs) in subcategories {
                    if subs.contains(where: { $0.id == selectedCategoryId }) {
                        expandedCategories.insert(parentId)
                    }
                }
            } catch {
                print("Error loading categories: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Category Picker Row
private struct CategoryPickerRow: View {
    let category: ItemCategoryModel
    let isSelected: Bool
    let hasSubcategories: Bool
    let isExpanded: Bool
    let level: Int
    let onSelect: () -> Void
    let onToggleExpand: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppSpacing.sm) {
                // Indentation for subcategories
                if level > 0 {
                    Spacer()
                        .frame(width: CGFloat(level * 20))
                }
                
                // Expand/collapse button
                if hasSubcategories {
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 20)
                }
                
                // Category icon
                Image(systemName: category.icon)
                    .font(level == 0 ? .title3 : .body)
                    .foregroundStyle(Color(category.color))
                    .frame(width: level == 0 ? 40 : 30, height: level == 0 ? 40 : 30)
                    .background(Color(category.color).opacity(0.1))
                    .clipShape(Circle())
                
                // Category name
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(category.name)
                        .textStyle(level == 0 ? .bodyLarge : .bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if category.isBuiltIn && level == 0 {
                        Text("Built-in")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Display View
public struct CategoryDisplayView: View {
    let categoryId: UUID
    let categoryRepository: any CategoryRepository
    @State private var category: ItemCategoryModel?
    @State private var parentCategory: ItemCategoryModel?
    
    public init(categoryId: UUID, categoryRepository: any CategoryRepository) {
        self.categoryId = categoryId
        self.categoryRepository = categoryRepository
    }
    
    public var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let category = category {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(Color(category.color))
                
                if let parent = parentCategory {
                    Text("\(parent.name) › \(category.name)")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    Text(category.name)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .onAppear {
            loadCategory()
        }
        .onChange(of: categoryId) { _ in
            loadCategory()
        }
    }
    
    private func loadCategory() {
        Task {
            do {
                category = try await categoryRepository.fetch(id: categoryId)
                if let parentId = category?.parentId {
                    parentCategory = try await categoryRepository.fetch(id: parentId)
                } else {
                    parentCategory = nil
                }
            } catch {
                print("Error loading category: \(error)")
            }
        }
    }
}