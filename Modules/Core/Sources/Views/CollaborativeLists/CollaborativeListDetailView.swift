//
//  CollaborativeListDetailView.swift
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
//  Testing: CoreTests/CollaborativeListDetailViewTests.swift
//
//  Description: Detailed view for managing a collaborative list with item management, filtering, and real-time collaboration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CollaborativeListDetailView: View {
    @State var list: CollaborativeListService.CollaborativeList
    @ObservedObject var listService: CollaborativeListService
    @Environment(\.dismiss) private var dismiss
    
    @State private var newItemTitle = ""
    @State private var showingAddItem = false
    @State private var showingListSettings = false
    @State private var showingCollaborators = false
    @State private var selectedItem: CollaborativeListService.ListItem?
    @State private var searchText = ""
    @State private var showCompleted = true
    @State private var sortOrder: CollaborativeListService.ListSettings.SortOrder = .manual
    @State private var groupBy: CollaborativeListService.ListSettings.GroupBy = .none
    
    @FocusState private var isAddingItem: Bool
    
    private var displayedItems: [CollaborativeListService.ListItem] {
        var items = showCompleted ? list.items : list.items.filter { !$0.isCompleted }
        
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        switch sortOrder {
        case .manual:
            break
        case .alphabetical:
            items.sort { $0.title < $1.title }
        case .priority:
            items.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .dateAdded:
            items.sort { $0.addedDate > $1.addedDate }
        case .assigned:
            items.sort { ($0.assignedTo ?? "") < ($1.assignedTo ?? "") }
        }
        
        return items
    }
    
    private var groupedItems: [(key: String, items: [CollaborativeListService.ListItem])] {
        let items = displayedItems
        
        switch groupBy {
        case .none:
            return [("", items)]
        case .priority:
            let grouped = Dictionary(grouping: items) { $0.priority }
            return grouped.sorted { $0.key.rawValue > $1.key.rawValue }
                .map { (key: $0.key.displayName, items: $0.value) }
        case .assigned:
            let grouped = Dictionary(grouping: items) { $0.assignedTo ?? "Unassigned" }
            return grouped.sorted { $0.key < $1.key }
                .map { (key: $0.key, items: $0.value) }
        case .completed:
            let grouped = Dictionary(grouping: items) { $0.isCompleted }
            return grouped.sorted { !$0.key && $1.key }
                .map { (key: $0.key ? "Completed" : "Active", items: $0.value) }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // List content
            if displayedItems.isEmpty && searchText.isEmpty {
                emptyStateView
            } else {
                listContent
            }
            
            // Add item bar
            addItemBar
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search items")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingListSettings) {
            // ListInfoView(list: $list, listService: listService)
            Text("List Info View") // Placeholder
        }
        .sheet(isPresented: $showingCollaborators) {
            // CollaboratorsView(list: list, listService: listService)
            Text("Collaborators View") // Placeholder
        }
        .sheet(item: $selectedItem) { item in
            // ItemDetailView(item: item, list: list, listService: listService)
            Text("Item Detail View") // Placeholder
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Items Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Add your first item to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { isAddingItem = true }) {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedItems, id: \.key) { group in
                    if !group.key.isEmpty {
                        Section {
                            ForEach(group.items) { item in
                                ItemRow(
                                    item: item,
                                    onToggle: { toggleItem(item) },
                                    onTap: { selectedItem = item }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        } header: {
                            HStack {
                                Text(group.key)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(group.items.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground).opacity(0.95))
                        }
                    } else {
                        ForEach(group.items) { item in
                            ItemRow(
                                item: item,
                                onToggle: { toggleItem(item) },
                                onTap: { selectedItem = item }
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 80)
        }
        .animation(.spring(), value: displayedItems)
    }
    
    // MARK: - Add Item Bar
    
    private var addItemBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Add item...", text: $newItemTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isAddingItem)
                    .onSubmit {
                        addItem()
                    }
                
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newItemTitle.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                // View options
                Section {
                    Button(action: { showCompleted.toggle() }) {
                        Label(
                            showCompleted ? "Hide Completed" : "Show Completed",
                            systemImage: showCompleted ? "eye.slash" : "eye"
                        )
                    }
                    
                    Menu {
                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(CollaborativeListService.ListSettings.SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort By", systemImage: "arrow.up.arrow.down")
                    }
                    
                    Menu {
                        Picker("Group By", selection: $groupBy) {
                            ForEach(CollaborativeListService.ListSettings.GroupBy.allCases, id: \.self) { grouping in
                                Text(grouping.rawValue).tag(grouping)
                            }
                        }
                    } label: {
                        Label("Group By", systemImage: "square.grid.2x2")
                    }
                }
                
                Divider()
                
                // List actions
                Section {
                    Button(action: { showingCollaborators = true }) {
                        Label("Collaborators", systemImage: "person.2")
                    }
                    
                    Button(action: { showingListSettings = true }) {
                        Label("List Info", systemImage: "info.circle")
                    }
                    
                    Button(action: shareList) {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }
                }
                
                Divider()
                
                // Danger zone
                if list.createdBy == "current-user-id" {
                    Button(role: .destructive, action: archiveList) {
                        Label("Archive List", systemImage: "archivebox")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Actions
    
    private func addItem() {
        guard !newItemTitle.isEmpty else { return }
        
        Task {
            try? await listService.addItem(
                to: list,
                title: newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            newItemTitle = ""
        }
    }
    
    private func toggleItem(_ item: CollaborativeListService.ListItem) {
        Task {
            try? await listService.toggleItemCompletion(item, in: list)
        }
    }
    
    private func shareList() {
        // Implement share sheet
    }
    
    private func archiveList() {
        Task {
            list.isArchived = true
            try? await listService.updateList(list)
            dismiss()
        }
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: CollaborativeListService.ListItem
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion toggle
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Item content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.body)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? .secondary : .primary)
                        
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if item.priority != .medium {
                            Label(item.priority.displayName, systemImage: "flag.fill")
                                .font(.caption)
                                .foregroundColor(Color(item.priority.color))
                        }
                        
                        if let assignedTo = item.assignedTo {
                            Label(assignedTo, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if let notes = item.notes, !notes.isEmpty {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Metadata
                VStack(alignment: .trailing, spacing: 2) {
                    if let completedDate = item.completedDate {
                        Text(completedDate.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(item.addedBy)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}