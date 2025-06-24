import SwiftUI
import Core
import SharedUI

struct ItemsListView: View {
    @StateObject private var viewModel: ItemsListViewModel
    @State private var showingAddItem = false
    @State private var selectedItem: Item?
    @State private var showingItemDetail = false
    @State private var selectedSegment = 0 // 0 = Items, 1 = Receipts
    
    private let onSearchTapped: (() -> Void)?
    private let onBarcodeSearchTapped: (() -> Void)?
    
    init(viewModel: ItemsListViewModel, onSearchTapped: (() -> Void)? = nil, onBarcodeSearchTapped: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSearchTapped = onSearchTapped
        self.onBarcodeSearchTapped = onBarcodeSearchTapped
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("View", selection: $selectedSegment) {
                    Text("Items").tag(0)
                    Text("Receipts").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .appPadding()
                .background(AppColors.secondaryBackground)
                
                // Content based on selection
                if selectedSegment == 0 {
                    // Items view
                    ZStack {
                        if viewModel.items.isEmpty && !viewModel.isLoading {
                            emptyStateView
                        } else {
                            itemsListContent
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.3))
                        }
                    }
                } else {
                    // Receipts view
                    if let receiptsView = viewModel.makeReceiptsListView() {
                        receiptsView
                            .background(AppColors.background)
                    }
                }
            }
            .navigationTitle(selectedSegment == 0 ? "Items" : "Receipts")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if let onBarcodeSearchTapped = onBarcodeSearchTapped {
                        Button(action: onBarcodeSearchTapped) {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                    
                    if let onSearchTapped = onSearchTapped {
                        Button(action: onSearchTapped) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
                    Button(action: { 
                        if selectedSegment == 0 {
                            showingAddItem = true
                        } else {
                            viewModel.showingAddReceipt = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                if let addView = viewModel.makeAddItemView() {
                    addView
                }
            }
            .sheet(item: $selectedItem) { item in
                NavigationView {
                    if let detailView = viewModel.makeItemDetailView(for: item) {
                        detailView
                    }
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "shippingbox")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Items Yet")
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Tap the + button to add your first item")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(title: "Add First Item") {
                showingAddItem = true
            }
            .frame(maxWidth: 200)
        }
        .appPadding(.all, AppSpacing.xl)
    }
    
    private var itemsListContent: some View {
        VStack(spacing: 0) {
            // Header with stats
            statsHeader
                .appPadding()
                .background(AppColors.secondaryBackground)
            
            // Filter bar
            filterBar
                .appPadding(.horizontal)
                .appPadding(.vertical, AppSpacing.sm)
            
            // Items list
            List {
                ForEach(viewModel.filteredItems) { item in
                    ItemRowView(item: item)
                        .listRowBackground(AppColors.surface)
                        .listRowSeparator(.visible)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteItem(item)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                Task {
                                    await viewModel.duplicateItem(item)
                                }
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(AppColors.primary)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(viewModel.itemCount)")
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Items")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(viewModel.totalValue, format: .currency(code: "USD"))
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.primary)
                Text("Total Value")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
    
    private var filterBar: some View {
        VStack(spacing: 0) {
            // Filter chips
            FilterChipsView(
                filters: viewModel.activeFilters,
                onRemove: viewModel.removeFilter,
                onShowFilters: {
                    viewModel.showingAdvancedFilters = true
                }
            )
            
            // Sort option
            HStack {
                Menu {
                    ForEach(ItemsListViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(viewModel.sortOption.rawValue)
                            .textStyle(.labelSmall)
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }
                .appPadding(.horizontal)
                .appPadding(.top, AppSpacing.sm)
                
                Spacer()
            }
        }
        .sheet(isPresented: $viewModel.showingAdvancedFilters) {
            AdvancedFiltersView(
                currentFilters: viewModel.activeFilters,
                onApply: viewModel.applyAdvancedFilters
            )
        }
    }
}

// MARK: - Supporting Views

struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 44, height: 44)
                .background(AppColors.primaryMuted)
                .cornerRadius(AppCornerRadius.small)
            
            // Details
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    if let brand = item.brand {
                        Text(brand)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Value
            if let value = item.value {
                Text(value, format: .currency(code: "USD"))
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .appPadding(.horizontal, AppSpacing.sm)
                .appPadding(.vertical, AppSpacing.xs)
                .background(isSelected ? AppColors.primary : AppColors.surface)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .cornerRadius(8)
        }
    }
}