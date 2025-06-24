import SwiftUI
import Core
import SharedUI

/// View for adding items to a collection
/// Swift 5.9 - No Swift 6 features
struct AddItemsToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddItemsToCollectionViewModel
    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    
    init(
        collection: Collection,
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onComplete: @escaping () -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: AddItemsToCollectionViewModel(
                collection: collection,
                collectionRepository: collectionRepository,
                itemRepository: itemRepository,
                onComplete: onComplete
            )
        )
    }
    
    var filteredItems: [Item] {
        var items = viewModel.availableItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.model?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        return items.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Search and filter section
                    searchAndFilterSection
                    
                    Divider()
                    
                    // Items list or empty state
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        itemsList
                    }
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var searchAndFilterSection: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textSecondary)
                TextField("Search items", text: $searchText)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal)
            .padding(.vertical, AppSpacing.sm)
            
            // Category filter
            categoryFilterChips
        }
    }
    
    @ViewBuilder
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // All items chip
                CategoryChipView(
                    title: "All",
                    icon: "square.grid.2x2",
                    count: viewModel.availableItems.count,
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // Category chips
                ForEach(ItemCategory.allCases, id: \.self) { (category: ItemCategory) in
                    let count = viewModel.availableItems.filter { $0.category == category }.count
                    if count > 0 {
                        CategoryChipView(
                            title: category.displayName,
                            icon: category.icon,
                            count: count,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, AppSpacing.sm)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        Spacer()
        VStack(spacing: AppSpacing.md) {
            Image(systemName: searchText.isEmpty ? "square.stack" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)
            
            Text(searchText.isEmpty ? "No Items Available" : "No Results")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(searchText.isEmpty ? "All items are already in this collection" : "Try a different search term")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        Spacer()
    }
    
    @ViewBuilder
    private var itemsList: some View {
        List {
            ForEach(filteredItems) { item in
                ItemSelectionRow(
                    item: item,
                    isSelected: viewModel.selectedItemIds.contains(item.id),
                    onToggle: { viewModel.toggleItem(item.id) }
                )
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        ProgressView("Adding items...")
            .padding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(radius: 4)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Add") {
                viewModel.addSelectedItems()
            }
            .disabled(viewModel.selectedItemIds.isEmpty || viewModel.isLoading)
        }
        
        if !viewModel.selectedItemIds.isEmpty {
            ToolbarItem(placement: .bottomBar) {
                Text("\(viewModel.selectedItemIds.count) selected")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Item Selection Row
private struct ItemSelectionRow: View {
    let item: Item
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                
                Image(systemName: item.category.icon)
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.xs) {
                        if let brand = item.brand {
                            Text(brand)
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Text(item.category.displayName)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model
@MainActor
final class AddItemsToCollectionViewModel: ObservableObject {
    @Published var availableItems: [Item] = []
    @Published var selectedItemIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let collection: Collection
    let collectionRepository: any CollectionRepository
    let itemRepository: any ItemRepository
    let onComplete: () -> Void
    
    init(
        collection: Collection,
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onComplete: @escaping () -> Void
    ) {
        self.collection = collection
        self.collectionRepository = collectionRepository
        self.itemRepository = itemRepository
        self.onComplete = onComplete
        
        loadAvailableItems()
    }
    
    private func loadAvailableItems() {
        Task {
            isLoading = true
            do {
                let allItems = try await itemRepository.fetchAll()
                // Filter out items already in the collection
                availableItems = allItems.filter { !collection.itemIds.contains($0.id) }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func toggleItem(_ itemId: UUID) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }
    
    func addSelectedItems() {
        Task {
            isLoading = true
            do {
                for itemId in selectedItemIds {
                    try await collectionRepository.addItem(itemId, to: collection.id)
                }
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Category Chip View
private struct CategoryChipView: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .textStyle(.labelMedium)
                
                Text("(\(count))")
                    .textStyle(.labelSmall)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.primary : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}