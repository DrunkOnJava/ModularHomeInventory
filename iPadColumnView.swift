import SwiftUI
import Core
import SharedUI
import Items

/// iPad-optimized column view for master-detail-detail layout
/// Provides a three-column interface for browsing items
struct iPadColumnView: View {
    @StateObject private var viewModel = iPadColumnViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && geometry.size.width > 1000 {
                // Three column layout for large iPads
                threeColumnLayout
            } else if horizontalSizeClass == .regular {
                // Two column layout for standard iPads
                twoColumnLayout
            } else {
                // Single column for compact width
                singleColumnLayout
            }
        }
    }
    
    // MARK: - Three Column Layout
    
    private var threeColumnLayout: some View {
        HStack(spacing: 0) {
            // Master column - Categories/Collections
            masterColumn
                .frame(width: 280)
                .background(AppColors.surface)
            
            Divider()
            
            // Middle column - Items list
            middleColumn
                .frame(width: 380)
                .background(AppColors.background)
            
            Divider()
            
            // Detail column - Item details
            detailColumn
                .frame(maxWidth: .infinity)
                .background(AppColors.background)
        }
    }
    
    // MARK: - Two Column Layout
    
    private var twoColumnLayout: some View {
        NavigationSplitView {
            // Combined master/middle column
            VStack(spacing: 0) {
                Picker("View", selection: $viewModel.masterViewMode) {
                    Text("Categories").tag(MasterViewMode.categories)
                    Text("Collections").tag(MasterViewMode.collections)
                    Text("Locations").tag(MasterViewMode.locations)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                masterContent
            }
            .navigationTitle("Browse")
        } detail: {
            if let selectedItem = viewModel.selectedItem {
                ItemDetailPlaceholder(item: selectedItem)
                    .id(selectedItem.id)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "shippingbox",
                    description: Text("Choose an item from the list to view its details")
                )
            }
        }
    }
    
    // MARK: - Single Column Layout
    
    private var singleColumnLayout: some View {
        NavigationStack {
            ItemsListView(selectedItem: $viewModel.selectedItem)
        }
    }
    
    // MARK: - Column Components
    
    private var masterColumn: some View {
        VStack(spacing: 0) {
            // View mode picker
            Picker("View", selection: $viewModel.masterViewMode) {
                Text("Categories").tag(MasterViewMode.categories)
                Text("Collections").tag(MasterViewMode.collections)
                Text("Locations").tag(MasterViewMode.locations)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Content
            masterContent
        }
    }
    
    @ViewBuilder
    private var masterContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch viewModel.masterViewMode {
                case .categories:
                    ForEach(viewModel.categories) { category in
                        CategoryRow(
                            category: category,
                            isSelected: viewModel.selectedCategory?.id == category.id,
                            itemCount: viewModel.itemCounts[category.id] ?? 0
                        )
                        .onTapGesture {
                            viewModel.selectCategory(category)
                        }
                    }
                    
                case .collections:
                    ForEach(viewModel.collections) { collection in
                        CollectionRow(
                            collection: collection,
                            isSelected: viewModel.selectedCollection?.id == collection.id
                        )
                        .onTapGesture {
                            viewModel.selectCollection(collection)
                        }
                    }
                    
                case .locations:
                    ForEach(viewModel.locations) { location in
                        LocationRow(
                            location: location,
                            isSelected: viewModel.selectedLocation?.id == location.id,
                            itemCount: viewModel.locationItemCounts[location.id] ?? 0
                        )
                        .onTapGesture {
                            viewModel.selectLocation(location)
                        }
                    }
                }
            }
        }
    }
    
    private var middleColumn: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.middleColumnTitle)
                    .textStyle(.headlineMedium)
                
                Spacer()
                
                Text("\(viewModel.filteredItems.count) items")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding()
            
            Divider()
            
            // Items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredItems) { item in
                        ItemCompactRow(
                            item: item,
                            isSelected: viewModel.selectedItem?.id == item.id
                        )
                        .onTapGesture {
                            viewModel.selectItem(item)
                        }
                    }
                }
            }
        }
    }
    
    private var detailColumn: some View {
        Group {
            if let selectedItem = viewModel.selectedItem {
                ItemDetailPlaceholder(item: selectedItem)
                    .id(selectedItem.id)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "shippingbox",
                    description: Text("Choose an item from the list to view its details")
                )
            }
        }
    }
}

// MARK: - View Model

class iPadColumnViewModel: ObservableObject {
    @Published var masterViewMode: MasterViewMode = .categories
    @Published var categories: [ItemCategory] = []
    @Published var collections: [Collection] = []
    @Published var locations: [Location] = []
    @Published var selectedCategory: ItemCategory?
    @Published var selectedCollection: Collection?
    @Published var selectedLocation: Location?
    @Published var filteredItems: [Item] = []
    @Published var selectedItem: Item?
    @Published var itemCounts: [UUID: Int] = [:]
    @Published var locationItemCounts: [UUID: Int] = [:]
    
    var middleColumnTitle: String {
        switch masterViewMode {
        case .categories:
            return selectedCategory?.name ?? "All Items"
        case .collections:
            return selectedCollection?.name ?? "Select Collection"
        case .locations:
            return selectedLocation?.name ?? "Select Location"
        }
    }
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Load categories, collections, locations
        categories = ItemCategory.allCases
        // TODO: Load collections and locations from repositories
    }
    
    func selectCategory(_ category: ItemCategory) {
        selectedCategory = category
        selectedCollection = nil
        selectedLocation = nil
        filterItems()
    }
    
    func selectCollection(_ collection: Collection) {
        selectedCollection = collection
        selectedCategory = nil
        selectedLocation = nil
        filterItems()
    }
    
    func selectLocation(_ location: Location) {
        selectedLocation = location
        selectedCategory = nil
        selectedCollection = nil
        filterItems()
    }
    
    func selectItem(_ item: Item) {
        selectedItem = item
    }
    
    private func filterItems() {
        // TODO: Filter items based on selection
    }
}

enum MasterViewMode {
    case categories
    case collections
    case locations
}

// MARK: - Row Components

struct CategoryRow: View {
    let category: ItemCategory
    let isSelected: Bool
    let itemCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                
                Text("\(itemCount) items")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
    }
}

struct CollectionRow: View {
    let collection: Collection
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                
                if let description = collection.description {
                    Text(description)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
    }
}

struct LocationRow: View {
    let location: Location
    let isSelected: Bool
    let itemCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: location.icon ?? "location.fill")
                .font(.title3)
                .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                
                Text("\(itemCount) items")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
    }
}

struct ItemCompactRow: View {
    let item: Item
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Thumbnail
            if let firstPhoto = item.photos.first {
                AsyncImage(url: URL(string: firstPhoto)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surface)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(AppColors.surface)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(AppColors.textTertiary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    if let brand = item.brand {
                        Text(brand)
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if let price = item.purchasePrice {
                        Text(price, format: .currency(code: item.currency))
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
    }
}

// MARK: - Placeholder Views

struct ItemDetailPlaceholder: View {
    let item: Item
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                Text(item.name)
                    .textStyle(.displayMedium)
                
                // Basic info
                HStack {
                    if let brand = item.brand {
                        Label(brand, systemImage: "tag")
                    }
                    if let model = item.model {
                        Label(model, systemImage: "number")
                    }
                }
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                
                // Photos
                if !item.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.photos, id: \.self) { photo in
                                if let url = URL(string: photo) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(AppColors.surface)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(AppCornerRadius.medium)
                                }
                            }
                        }
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let price = item.purchasePrice {
                        HStack {
                            Text("Purchase Price")
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(price, format: .currency(code: item.currency))
                        }
                    }
                    
                    if let location = item.location {
                        HStack {
                            Text("Location")
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(location.name)
                        }
                    }
                    
                    HStack {
                        Text("Category")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text(item.category.displayName)
                    }
                }
                .textStyle(.bodyMedium)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ItemsListPlaceholder: View {
    @Binding var selectedItem: Item?
    
    var body: some View {
        List {
            Text("Items list placeholder")
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

#Preview {
    iPadColumnView()
}