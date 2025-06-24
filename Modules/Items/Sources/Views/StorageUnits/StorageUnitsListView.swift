import SwiftUI
import Core
import SharedUI
import Combine

/// View for displaying and managing storage units
/// Swift 5.9 - No Swift 6 features
public struct StorageUnitsListView: View {
    @StateObject private var viewModel: StorageUnitsListViewModel
    @State private var showingAddUnit = false
    @State private var selectedUnit: StorageUnit?
    @State private var showingDeleteAlert = false
    @State private var unitToDelete: StorageUnit?
    @State private var selectedLocation: Location?
    
    public init(
        storageUnitRepository: any StorageUnitRepository,
        locationRepository: any LocationRepository,
        itemRepository: any ItemRepository
    ) {
        self._viewModel = StateObject(
            wrappedValue: StorageUnitsListViewModel(
                storageUnitRepository: storageUnitRepository,
                locationRepository: locationRepository,
                itemRepository: itemRepository
            )
        )
    }
    
    public var body: some View {
        List {
            // Location filter
            if !viewModel.locations.isEmpty {
                Section {
                    Menu {
                        Button("All Locations") {
                            selectedLocation = nil
                            viewModel.filterByLocation(nil)
                        }
                        ForEach(viewModel.locations) { location in
                            Button(action: {
                                selectedLocation = location
                                viewModel.filterByLocation(location.id)
                            }) {
                                Label(location.name, systemImage: location.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedLocation?.icon ?? "location")
                                .foregroundStyle(AppColors.primary)
                            Text(selectedLocation?.name ?? "All Locations")
                                .textStyle(.bodyMedium)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }
            }
            
            // Storage units
            if !viewModel.filteredUnits.isEmpty {
                ForEach(viewModel.filteredUnits) { unit in
                    StorageUnitRow(
                        unit: unit,
                        location: viewModel.locations.first { $0.id == unit.locationId },
                        onTap: {
                            selectedUnit = unit
                        },
                        onEdit: {
                            selectedUnit = unit
                        },
                        onDelete: {
                            unitToDelete = unit
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Loading storage units...")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            } else if viewModel.filteredUnits.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Storage Units",
                        systemImage: "shippingbox",
                        description: Text("Create storage units to organize items within locations")
                    )
                }
            }
        }
        .navigationTitle("Storage Units")
        .searchable(text: $viewModel.searchText, prompt: "Search storage units...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddUnit = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddUnit) {
            AddEditStorageUnitView(
                storageUnitRepository: viewModel.storageUnitRepository,
                locationRepository: viewModel.locationRepository,
                selectedLocationId: selectedLocation?.id,
                onComplete: { _ in
                    viewModel.loadData()
                }
            )
        }
        .sheet(item: $selectedUnit) { unit in
            StorageUnitDetailView(
                unit: unit,
                storageUnitRepository: viewModel.storageUnitRepository,
                itemRepository: viewModel.itemRepository,
                locationRepository: viewModel.locationRepository
            )
        }
        .alert("Delete Storage Unit?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let unit = unitToDelete {
                    viewModel.deleteUnit(unit)
                }
            }
        } message: {
            if let unit = unitToDelete {
                Text("Are you sure you want to delete '\(unit.name)'? Items in this unit will remain in the location.")
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Storage Unit Row
private struct StorageUnitRow: View {
    let unit: StorageUnit
    let location: Location?
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                Image(systemName: unit.type.icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primaryMuted)
                    .cornerRadius(AppCornerRadius.small)
                
                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(unit.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        if let location = location {
                            Label(location.name, systemImage: location.icon)
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        if let capacity = unit.capacity {
                            Text("•")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            HStack(spacing: 2) {
                                Text("\(unit.currentItemCount)/\(capacity)")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(capacityColor(current: unit.currentItemCount, max: capacity))
                            }
                        } else {
                            Text("•")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            Text("\(unit.currentItemCount) items")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppColors.primary)
        }
    }
    
    private func capacityColor(current: Int, max: Int) -> Color {
        let percentage = Double(current) / Double(max)
        if percentage >= 0.9 {
            return AppColors.error
        } else if percentage >= 0.7 {
            return AppColors.warning
        } else {
            return AppColors.textSecondary
        }
    }
}

// MARK: - View Model
@MainActor
final class StorageUnitsListViewModel: ObservableObject {
    @Published var storageUnits: [StorageUnit] = []
    @Published var filteredUnits: [StorageUnit] = []
    @Published var locations: [Location] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let storageUnitRepository: any StorageUnitRepository
    let locationRepository: any LocationRepository
    let itemRepository: any ItemRepository
    
    init(
        storageUnitRepository: any StorageUnitRepository,
        locationRepository: any LocationRepository,
        itemRepository: any ItemRepository
    ) {
        self.storageUnitRepository = storageUnitRepository
        self.locationRepository = locationRepository
        self.itemRepository = itemRepository
        
        // Setup search binding
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterUnits()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var selectedLocationId: UUID?
    
    func loadData() {
        Task {
            isLoading = true
            do {
                async let unitsTask = storageUnitRepository.fetchAll()
                async let locationsTask = locationRepository.fetchAll()
                
                let (units, locs) = try await (unitsTask, locationsTask)
                storageUnits = units
                locations = locs
                filterUnits()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func filterByLocation(_ locationId: UUID?) {
        selectedLocationId = locationId
        filterUnits()
    }
    
    private func filterUnits() {
        var filtered = storageUnits
        
        // Location filter
        if let locationId = selectedLocationId {
            filtered = filtered.filter { $0.locationId == locationId }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { unit in
                unit.name.localizedCaseInsensitiveContains(searchText) ||
                (unit.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (unit.position?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        filteredUnits = filtered.sorted { $0.name < $1.name }
    }
    
    func deleteUnit(_ unit: StorageUnit) {
        Task {
            do {
                try await storageUnitRepository.delete(unit)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}