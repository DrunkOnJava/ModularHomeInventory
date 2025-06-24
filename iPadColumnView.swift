import SwiftUI
import Core
import SharedUI

/// Three-column layout for iPad Pro
/// Provides master-detail-inspector interface
struct iPadColumnView: View {
    @StateObject private var viewModel = ColumnViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width > 1200 {
                    threeColumnLayout
                } else if geometry.size.width > 768 {
                    twoColumnLayout
                } else {
                    singleColumnLayout
                }
            }
        }
    }
    
    // MARK: - Three Column Layout
    
    private var threeColumnLayout: some View {
        HStack(spacing: 0) {
            // Master column (categories/collections/locations)
            masterColumn
                .frame(width: 280)
                .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Middle column (items list)
            middleColumn
                .frame(minWidth: 320, maxWidth: 400)
            
            Divider()
            
            // Detail column (item detail)
            detailColumn
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Two Column Layout
    
    private var twoColumnLayout: some View {
        HStack(spacing: 0) {
            // Combined master/middle column
            VStack(spacing: 0) {
                masterColumn
                Divider()
                middleColumn
            }
            .frame(width: 320)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Detail column
            detailColumn
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Single Column Layout
    
    private var singleColumnLayout: some View {
        NavigationStack {
            coordinator.itemsModule.makeItemsListView(
                onSearchTapped: {
                    viewModel.showSearch = true
                },
                onBarcodeSearchTapped: {
                    viewModel.showBarcodeSearch = true
                }
            )
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
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        CategoryRow(
                            category: category,
                            isSelected: viewModel.selectedCategoryEnum == category,
                            itemCount: 0 // Would be calculated from items
                        )
                        .onTapGesture {
                            viewModel.selectedCategoryEnum = category
                        }
                    }
                case .collections:
                    // Collections list would go here
                    Text("Collections")
                        .foregroundStyle(.secondary)
                        .padding()
                case .locations:
                    // Locations list would go here
                    Text("Locations")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
    }
    
    private var middleColumn: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.middleColumnTitle)
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.showAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding()
            
            Divider()
            
            // Items list
            if viewModel.filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "square.grid.2x2",
                    description: Text("Add items to get started")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.filteredItems) { item in
                            ItemRow(
                                item: item,
                                isSelected: viewModel.selectedItem?.id == item.id
                            )
                            .onTapGesture {
                                viewModel.selectedItem = item
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var detailColumn: some View {
        Group {
            if let item = viewModel.selectedItem {
                // Item detail view
                ItemDetailPlaceholder(item: item)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "square.grid.2x2",
                    description: Text("Choose an item from the list to view details")
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var middleColumnTitle: String {
        switch viewModel.masterViewMode {
        case .categories:
            return viewModel.selectedCategoryEnum?.displayName ?? "All Items"
        case .collections:
            return "Collection Items"
        case .locations:
            return "Location Items"
        }
    }
}

// MARK: - View Model

class ColumnViewModel: ObservableObject {
    @Published var masterViewMode = MasterViewMode.categories
    @Published var selectedCategoryEnum: ItemCategory?
    @Published var selectedCollection: UUID?
    @Published var selectedLocation: UUID?
    @Published var selectedItem: Item?
    @Published var showSearch = false
    @Published var showBarcodeSearch = false
    @Published var showAddItem = false
    @Published var searchText = ""
    
    // Mock data for now
    @Published var items: [Item] = Item.previewItems
    @Published var collections: [UUID] = []
    @Published var locations: [UUID] = []
    
    var filteredItems: [Item] {
        items.filter { item in
            // Filter by category
            if let category = selectedCategoryEnum, item.category != category {
                return false
            }
            
            // Filter by search
            if !searchText.isEmpty {
                return item.name.localizedCaseInsensitiveContains(searchText) ||
                       item.brand?.localizedCaseInsensitiveContains(searchText) == true ||
                       item.model?.localizedCaseInsensitiveContains(searchText) == true
            }
            
            return true
        }
    }
    
    var middleColumnTitle: String {
        switch masterViewMode {
        case .categories:
            return selectedCategoryEnum?.displayName ?? "All Items"
        case .collections:
            return "Collection Items"
        case .locations:
            return "Location Items"
        }
    }
}

// MARK: - Supporting Types

enum MasterViewMode {
    case categories
    case collections
    case locations
}

// MARK: - Row Views

struct CategoryRow: View {
    let category: ItemCategory
    let isSelected: Bool
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color(category.color))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(category.displayName)
                .font(.body)
            
            Spacer()
            
            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct ItemRow: View {
    let item: Item
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Item icon
            Image(systemName: item.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(item.category.color))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let model = item.model {
                        Text("• \(model)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
            }
            
            Spacer()
            
            // Price
            if let price = item.purchasePrice {
                Text("$\(price)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Placeholder Views

struct ItemDetailPlaceholder: View {
    let item: Item
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color(item.category.color))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        
                        if let brand = item.brand {
                            Text(brand)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Details
                GroupBox("Details") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailRow(label: "Model", value: item.model ?? "—")
                        DetailRow(label: "Quantity", value: "\(item.quantity)")
                        DetailRow(label: "Condition", value: item.condition.displayName)
                        DetailRow(label: "Purchase Price", value: item.purchasePrice.map { "$\($0)" } ?? "—")
                    }
                }
                
                if let notes = item.notes, !notes.isEmpty {
                    GroupBox("Notes") {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}