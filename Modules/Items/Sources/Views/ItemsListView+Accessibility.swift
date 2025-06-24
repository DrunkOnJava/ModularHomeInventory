import SwiftUI
import Core
import SharedUI

// MARK: - ItemsListView Accessibility Extension

extension ItemsListView {
    /// Apply VoiceOver accessibility to the main view
    func applyAccessibility() -> some View {
        self
            .voiceOverContainer()
            .onAppear {
                if UIAccessibility.isVoiceOverRunning {
                    VoiceOverAnnouncement.announce("Items list loaded with \(viewModel.itemCount) items")
                }
            }
    }
}

// MARK: - Empty State Accessibility

extension ItemsListView {
    var accessibleEmptyStateView: some View {
        emptyStateView
            .voiceOverCombine()
            .voiceOverLabel("No items in your inventory")
            .voiceOverHint("Double tap the add button in the navigation bar to add your first item")
    }
}

// MARK: - Stats Header Accessibility

extension ItemsListView {
    var accessibleStatsHeader: some View {
        statsHeader
            .voiceOverCombine()
            .voiceOverLabel("\(viewModel.itemCount) items in inventory, total value \(viewModel.totalValue.formatted(.currency(code: "USD")))")
            .voiceOverHeader()
    }
}

// MARK: - Filter Bar Accessibility

extension ItemsListView {
    var accessibleFilterBar: some View {
        filterBar
            .voiceOverLabel("Filter and sort options")
            .voiceOverHint("Use to filter items or change sort order")
    }
}

// MARK: - ItemRowView Accessibility Extension

extension ItemRowView {
    /// Apply VoiceOver accessibility to item rows
    func applyAccessibility() -> some View {
        self
            .voiceOverCombine()
            .voiceOverLabel(accessibilityLabel)
            .voiceOverHint("Double tap to view details. Swipe for more actions.")
            .voiceOverActions([
                VoiceOverAction(name: "Share") {
                    // Trigger share action
                    VoiceOverAnnouncement.announce("Share action selected for \(item.name)")
                },
                VoiceOverAction(name: "Duplicate") {
                    // Trigger duplicate action
                    VoiceOverAnnouncement.announce("Duplicate action selected for \(item.name)")
                },
                VoiceOverAction(name: "Delete") {
                    // Trigger delete action
                    VoiceOverAnnouncement.announce("Delete action selected for \(item.name)")
                }
            ])
    }
    
    private var accessibilityLabel: String {
        var components = [item.name]
        
        // Add category
        components.append(item.category.displayName)
        
        // Add quantity if more than 1
        if item.quantity > 1 {
            components.append("\(item.quantity) items")
        }
        
        // Add value if available
        if let value = item.value {
            components.append("valued at \(value.formatted(.currency(code: "USD")))")
        }
        
        // Add location if available (would need to be passed in)
        // if let location = location {
        //     components.append("at \(location)")
        // }
        
        // Add condition
        components.append("Condition: \(item.condition.displayName)")
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Updated ItemRowView with Accessibility

struct AccessibleItemRowView: View {
    let item: Item
    let position: Int
    let total: Int
    let onTap: () -> Void
    let onDelete: () async -> Void
    let onDuplicate: () async -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 48, height: 48)
                .background(AppColors.primaryLight.opacity(0.1))
                .appCornerRadius(.small)
                .voiceOverIgnore() // Icon is decorative
            
            // Item details
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(item.category.displayName)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    if item.quantity > 1 {
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        Text("\(item.quantity)")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Value
            if let value = item.value {
                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    SecureCurrencyText(
                        amount: value,
                        currencyCode: "USD",
                        style: .bodyMedium
                    )
                    .foregroundStyle(AppColors.primary)
                    
                    // Condition badge
                    ConditionBadge(condition: item.condition, size: .small)
                }
            } else {
                // Just condition badge
                ConditionBadge(condition: item.condition, size: .small)
            }
        }
        .voiceOverCombine()
        .voiceOverLabel(accessibilityLabel)
        .voiceOverHint("Double tap to view details")
        .voiceOverListItem(position: position, total: total)
        .voiceOverActions([
            VoiceOverAction(name: "Share") {
                onShare()
                VoiceOverAnnouncement.announce("Sharing \(item.name)")
            },
            VoiceOverAction(name: "Duplicate") {
                Task {
                    await onDuplicate()
                    VoiceOverAnnouncement.announce("Duplicated \(item.name)")
                }
            },
            VoiceOverAction(name: "Delete") {
                Task {
                    await onDelete()
                    VoiceOverAnnouncement.announce("Deleted \(item.name)")
                }
            }
        ])
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var accessibilityLabel: String {
        var components = [item.name]
        
        components.append(item.category.displayName)
        
        if item.quantity > 1 {
            components.append("\(item.quantity) items")
        }
        
        if let value = item.value {
            components.append("valued at \(value.formatted(.currency(code: "USD")))")
        }
        
        components.append("Condition: \(item.condition.displayName)")
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Segmented Control Accessibility

extension ItemsListView {
    var accessibleSegmentedControl: some View {
        Picker("View", selection: $selectedSegment) {
            Text("Items").tag(0)
            Text("Receipts").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .appPadding()
        .background(AppColors.secondaryBackground)
        .voiceOverLabel("View selector")
        .voiceOverValue(selectedSegment == 0 ? "Items selected" : "Receipts selected")
        .voiceOverHint("Swipe up or down to change view")
        .onChange(of: selectedSegment) { newValue in
            let viewName = newValue == 0 ? "Items" : "Receipts"
            VoiceOverAnnouncement.announce("Now showing \(viewName)")
        }
    }
}

// MARK: - Toolbar Accessibility

extension ItemsListView {
    /// Create accessible toolbar items
    func accessibleToolbarItems() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if selectedSegment == 0 {
                // Import/Export menu
                Menu {
                    Button(action: { showingImport = true }) {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: { showingExport = true }) {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .voiceOverLabel("More options")
                        .voiceOverHint("Double tap for import and export options")
                }
            }
            
            if let onBarcodeSearchTapped = onBarcodeSearchTapped {
                Button(action: onBarcodeSearchTapped) {
                    Image(systemName: "barcode.viewfinder")
                        .voiceOverLabel("Barcode search")
                        .voiceOverHint("Double tap to search by barcode")
                }
            }
            
            if let onSearchTapped = onSearchTapped {
                Button(action: onSearchTapped) {
                    Image(systemName: "magnifyingglass")
                        .voiceOverLabel("Search")
                        .voiceOverHint("Double tap to search items")
                }
            }
            
            Button(action: { 
                if selectedSegment == 0 {
                    showingAddItem = true
                    VoiceOverAnnouncement.announce("Opening add item form")
                } else {
                    viewModel.showingAddReceipt = true
                    VoiceOverAnnouncement.announce("Opening add receipt form")
                }
            }) {
                Image(systemName: "plus")
                    .voiceOverLabel(selectedSegment == 0 ? "Add item" : "Add receipt")
                    .voiceOverHint("Double tap to add new \(selectedSegment == 0 ? "item" : "receipt")")
            }
        }
    }
}