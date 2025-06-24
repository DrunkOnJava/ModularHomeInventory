import SwiftUI
import Core
import SharedUI

/// View for displaying storage unit details and items
/// Swift 5.9 - No Swift 6 features
public struct StorageUnitDetailView: View {
    @StateObject private var viewModel: StorageUnitDetailViewModel
    @State private var showingEditUnit = false
    @State private var showingAddItems = false
    @State private var selectedItems: Set<UUID> = []
    @State private var isEditMode = false
    
    public init(
        unit: StorageUnit,
        storageUnitRepository: any StorageUnitRepository,
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) {
        self._viewModel = StateObject(
            wrappedValue: StorageUnitDetailViewModel(
                unit: unit,
                storageUnitRepository: storageUnitRepository,
                itemRepository: itemRepository,
                locationRepository: locationRepository
            )
        )
    }
    
    public var body: some View {
        NavigationView {
            List {
                // Unit Info Header
                Section {
                    VStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: viewModel.unit.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(AppColors.primary)
                                .frame(width: 60, height: 60)
                                .background(AppColors.primaryMuted)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                if let location = viewModel.location {
                                    Label(location.name, systemImage: location.icon)
                                        .textStyle(.labelMedium)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                
                                if let position = viewModel.unit.position {
                                    Text(position)
                                        .textStyle(.bodyMedium)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                
                                if let capacity = viewModel.unit.capacity {
                                    CapacityIndicator(
                                        current: viewModel.unit.currentItemCount,
                                        max: capacity
                                    )
                                } else {
                                    Text("\(viewModel.unit.currentItemCount) items")
                                        .textStyle(.labelMedium)
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if let description = viewModel.unit.description {
                            Text(description)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let dimensions = viewModel.unit.dimensions {
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundStyle(AppColors.textTertiary)
                                Text(dimensions.displayString)
                                    .textStyle(.labelMedium)
                                    .foregroundStyle(AppColors.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                
                // Items Section
                if !viewModel.items.isEmpty {
                    Section {
                        ForEach(viewModel.items) { item in
                            ItemRow(
                                item: item,
                                isSelected: selectedItems.contains(item.id),
                                isEditMode: isEditMode,
                                onTap: {
                                    if isEditMode {
                                        toggleSelection(for: item.id)
                                    }
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text("Items")
                            Spacer()
                            if isEditMode {
                                Button("Done") {
                                    isEditMode = false
                                    selectedItems.removeAll()
                                }
                            } else {
                                Button("Edit") {
                                    isEditMode = true
                                }
                            }
                        }
                    }
                } else if !viewModel.isLoading {
                    Section {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "cube",
                            description: Text("Add items to this storage unit")
                        )
                    }
                }
                
                if viewModel.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Loading items...")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                // Notes
                if let notes = viewModel.unit.notes {
                    Section("Notes") {
                        Text(notes)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle(viewModel.unit.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddItems = true }) {
                            Label("Add Items", systemImage: "plus.square")
                        }
                        
                        Button(action: { showingEditUnit = true }) {
                            Label("Edit Unit", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                if isEditMode && !selectedItems.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            viewModel.removeItems(Array(selectedItems))
                            selectedItems.removeAll()
                            isEditMode = false
                        } label: {
                            Label("Remove \(selectedItems.count) Items", systemImage: "minus.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditUnit) {
                AddEditStorageUnitView(
                    unit: viewModel.unit,
                    storageUnitRepository: viewModel.storageUnitRepository,
                    locationRepository: viewModel.locationRepository,
                    onComplete: { updatedUnit in
                        viewModel.updateUnit(updatedUnit)
                    }
                )
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
    }
    
    private func toggleSelection(for itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
}

// MARK: - Item Row
private struct ItemRow: View {
    let item: Item
    let isSelected: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                }
                
                // Item icon
                Image(systemName: item.category.icon)
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                // Item info
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
                        
                        if item.quantity > 1 {
                            if item.brand != nil {
                                Text("•")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            Text("Qty: \(item.quantity)")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
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

// MARK: - Capacity Indicator
private struct CapacityIndicator: View {
    let current: Int
    let max: Int
    
    private var percentage: Double {
        Double(current) / Double(max)
    }
    
    private var color: Color {
        if percentage >= 0.9 {
            return AppColors.error
        } else if percentage >= 0.7 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack {
                Text("\(current)/\(max) items")
                    .textStyle(.labelMedium)
                    .foregroundStyle(color)
                
                Text("(\(Int(percentage * 100))%)")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - View Model
@MainActor
final class StorageUnitDetailViewModel: ObservableObject {
    @Published var unit: StorageUnit
    @Published var items: [Item] = []
    @Published var location: Location?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let storageUnitRepository: any StorageUnitRepository
    let itemRepository: any ItemRepository
    let locationRepository: any LocationRepository
    
    init(
        unit: StorageUnit,
        storageUnitRepository: any StorageUnitRepository,
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) {
        self.unit = unit
        self.storageUnitRepository = storageUnitRepository
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        
        Task {
            await loadLocation()
        }
    }
    
    func loadLocation() async {
        do {
            location = try await locationRepository.fetch(id: unit.locationId)
        } catch {
            // Ignore error - location is optional
        }
    }
    
    func loadItems() {
        Task {
            isLoading = true
            do {
                let allItems = try await itemRepository.fetchAll()
                items = allItems.filter { $0.storageUnitId == unit.id }
                    .sorted { $0.name < $1.name }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func updateUnit(_ updatedUnit: StorageUnit) {
        unit = updatedUnit
    }
    
    func removeItems(_ itemIds: [UUID]) {
        Task {
            do {
                for itemId in itemIds {
                    if var item = try await itemRepository.fetch(id: itemId) {
                        item.storageUnitId = nil
                        try await itemRepository.save(item)
                    }
                }
                
                // Update item count
                let newCount = max(0, unit.currentItemCount - itemIds.count)
                try await storageUnitRepository.updateItemCount(for: unit.id, count: newCount)
                unit.currentItemCount = newCount
                
                await loadItems()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}