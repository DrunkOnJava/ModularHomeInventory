import Foundation
import SwiftUI
import Core
import SharedUI
import Combine

@MainActor
final class ItemsListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var items: [Item] = []
    @Published var filteredItems: [Item] = []
    @Published var searchText = ""
    @Published var selectedCategory: ItemCategory?
    @Published var selectedLocation: Location?
    @Published var sortOption: SortOption = .dateModified
    @Published var isLoading = false
    @Published var error: Error?
    @Published var activeFilters = ItemFilters.empty
    @Published var showingAdvancedFilters = false
    
    // MARK: - Computed Properties
    var totalValue: Decimal {
        filteredItems.reduce(Decimal.zero) { sum, item in
            sum + (item.value ?? 0) * Decimal(item.quantity)
        }
    }
    
    var itemCount: Int {
        filteredItems.count
    }
    
    var locations: [Location] = []
    
    // MARK: - Dependencies
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    weak var itemsModule: ItemsModuleAPI?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable {
        case dateModified = "Date Modified"
        case name = "Name"
        case value = "Value"
        case category = "Category"
        
        var icon: String {
            switch self {
            case .dateModified: return "calendar"
            case .name: return "textformat"
            case .value: return "dollarsign.circle"
            case .category: return "square.grid.2x2"
            }
        }
    }
    
    // MARK: - Initialization
    init(itemRepository: any ItemRepository, locationRepository: any LocationRepository) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        setupBindings()
        Task { await loadData() }
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Search and filter changes
        Publishers.CombineLatest3($searchText, $selectedCategory, $selectedLocation)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Sort option changes
        $sortOption
            .sink { [weak self] _ in
                self?.sortItems()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load items and locations in parallel
            async let itemsTask = itemRepository.fetchAll()
            async let locationsTask = locationRepository.fetchAll()
            
            let (loadedItems, loadedLocations) = try await (itemsTask, locationsTask)
            
            items = loadedItems
            locations = loadedLocations
            applyFilters()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Filtering and Sorting
    private func applyFilters() {
        var filtered = items
        
        // Apply advanced filters if any are active
        if !activeFilters.isEmpty {
            filtered = applyAdvancedFilters(to: filtered)
        } else {
            // Fall back to simple filters
            // Search filter
            if !searchText.isEmpty {
                filtered = filtered.filter { item in
                    item.name.localizedCaseInsensitiveContains(searchText) ||
                    (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                }
            }
            
            // Category filter
            if let category = selectedCategory {
                filtered = filtered.filter { $0.category == category }
            }
            
            // Location filter
            if let location = selectedLocation {
                filtered = filtered.filter { $0.locationId == location.id }
            }
        }
        
        filteredItems = filtered
        sortItems()
    }
    
    private func applyAdvancedFilters(to items: [Item]) -> [Item] {
        var filtered = items
        
        // Search text
        if let searchText = activeFilters.searchText, !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Categories
        if let categories = activeFilters.categories, !categories.isEmpty {
            filtered = filtered.filter { categories.contains($0.category) }
        }
        
        // Price range
        if let minPrice = activeFilters.minPrice {
            filtered = filtered.filter { ($0.value ?? 0) >= minPrice }
        }
        if let maxPrice = activeFilters.maxPrice {
            filtered = filtered.filter { ($0.value ?? 0) <= maxPrice }
        }
        
        // Date range
        if let startDate = activeFilters.startDate {
            filtered = filtered.filter { $0.purchaseDate ?? Date() >= startDate }
        }
        if let endDate = activeFilters.endDate {
            filtered = filtered.filter { $0.purchaseDate ?? Date() <= endDate }
        }
        
        // Locations
        if let locationIds = activeFilters.locationIds, !locationIds.isEmpty {
            filtered = filtered.filter { item in
                guard let locationId = item.locationId else { return false }
                return locationIds.contains(locationId)
            }
        }
        
        // Tags
        if let tagIds = activeFilters.tagIds, !tagIds.isEmpty {
            // TODO: Update when tags are properly implemented with IDs
            filtered = filtered.filter { item in
                !item.tags.isEmpty // Placeholder until tag IDs are implemented
            }
        }
        
        // Additional filters
        if activeFilters.hasPhotos == true {
            filtered = filtered.filter { !$0.imageIds.isEmpty }
        }
        
        if activeFilters.hasReceipt == true {
            // TODO: Implement when receipt linking is added
        }
        
        if activeFilters.hasWarranty == true {
            filtered = filtered.filter { $0.warrantyId != nil }
        }
        
        if activeFilters.isFavorite == true {
            // TODO: Implement when favorite flag is added to Item model
        }
        
        return filtered
    }
    
    private func sortItems() {
        switch sortOption {
        case .dateModified:
            filteredItems.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            filteredItems.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .value:
            filteredItems.sort { ($0.value ?? 0) > ($1.value ?? 0) }
        case .category:
            filteredItems.sort { $0.category.rawValue < $1.category.rawValue }
        }
    }
    
    // MARK: - Filter Actions
    func applyAdvancedFilters(_ filters: ItemFilters) {
        activeFilters = filters
        // Clear simple filters when using advanced filters
        searchText = ""
        selectedCategory = nil
        selectedLocation = nil
        applyFilters()
    }
    
    func clearAllFilters() {
        activeFilters = .empty
        searchText = ""
        selectedCategory = nil
        selectedLocation = nil
        applyFilters()
    }
    
    func removeFilter(_ filterType: FilterChipsView.FilterType) {
        switch filterType {
        case .search:
            activeFilters.searchText = nil
        case .category(let category):
            activeFilters.categories?.removeAll { $0 == category }
            if activeFilters.categories?.isEmpty == true {
                activeFilters.categories = nil
            }
        case .priceRange:
            activeFilters.minPrice = nil
            activeFilters.maxPrice = nil
        case .dateRange:
            activeFilters.startDate = nil
            activeFilters.endDate = nil
        case .location(let locationId):
            activeFilters.locationIds?.removeAll { $0 == locationId }
            if activeFilters.locationIds?.isEmpty == true {
                activeFilters.locationIds = nil
            }
        case .tag(let tagId):
            activeFilters.tagIds?.removeAll { $0 == tagId }
            if activeFilters.tagIds?.isEmpty == true {
                activeFilters.tagIds = nil
            }
        case .hasPhotos:
            activeFilters.hasPhotos = nil
        case .hasReceipt:
            activeFilters.hasReceipt = nil
        case .hasWarranty:
            activeFilters.hasWarranty = nil
        case .isFavorite:
            activeFilters.isFavorite = nil
        }
        applyFilters()
    }
    
    // MARK: - Actions
    func deleteItem(_ item: Item) async {
        do {
            try await itemRepository.delete(item)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    func duplicateItem(_ item: Item) async {
        do {
            // Create a copy of the item with a new ID and name
            let duplicatedItem = Item(
                id: UUID(),
                name: "\(item.name) (Copy)",
                brand: item.brand,
                model: item.model,
                category: item.category,
                condition: item.condition,
                quantity: item.quantity,
                value: item.value,
                purchasePrice: item.purchasePrice,
                purchaseDate: item.purchaseDate,
                notes: item.notes,
                barcode: nil, // Don't duplicate barcode as it should be unique
                serialNumber: nil, // Don't duplicate serial number as it should be unique
                tags: item.tags,
                imageIds: [], // Don't duplicate images initially
                locationId: item.locationId,
                warrantyId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await itemRepository.save(duplicatedItem)
            await loadData()
        } catch {
            self.error = error
        }
    }
    
    func refresh() async {
        await loadData()
    }
    
    // MARK: - View Creation
    func makeAddItemView() -> AnyView? {
        itemsModule?.makeAddItemView { [weak self] newItem in
            Task { @MainActor in
                await self?.loadData()
            }
        }
    }
    
    func makeItemDetailView(for item: Item) -> AnyView? {
        itemsModule?.makeItemDetailView(item: item)
    }
    
    func makeBatchScannerView() -> AnyView? {
        // This will be handled differently to avoid circular dependency
        return nil
    }
}