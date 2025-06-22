import Foundation
import SwiftUI
import Core
import Combine

/// View model for advanced filters
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class AdvancedFiltersViewModel: ObservableObject {
    // Search
    @Published var searchText = ""
    
    // Categories
    @Published var selectedCategories = Set<ItemCategory>()
    
    // Price Range
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 10000
    
    // Date Range
    @Published var useDateFilter = false
    @Published var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate = Date()
    
    // Locations
    @Published var selectedLocations = Set<UUID>()
    @Published var locations: [Location] = []
    
    // Tags
    @Published var selectedTags = Set<UUID>()
    @Published var tags: [Tag] = []
    
    // Additional Filters
    @Published var hasPhotos = false
    @Published var hasReceipt = false
    @Published var hasWarranty = false
    @Published var isFavorite = false
    
    private let onApply: (ItemFilters) -> Void
    private var cancellables = Set<AnyCancellable>()
    
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if !selectedCategories.isEmpty { count += 1 }
        if minPrice > 0 || maxPrice < 10000 { count += 1 }
        if useDateFilter { count += 1 }
        if !selectedLocations.isEmpty { count += 1 }
        if !selectedTags.isEmpty { count += 1 }
        if hasPhotos { count += 1 }
        if hasReceipt { count += 1 }
        if hasWarranty { count += 1 }
        if isFavorite { count += 1 }
        return count
    }
    
    let quickPriceRanges = [
        (label: "Under $50", min: 0.0, max: 50.0),
        (label: "$50-$100", min: 50.0, max: 100.0),
        (label: "$100-$500", min: 100.0, max: 500.0),
        (label: "$500-$1000", min: 500.0, max: 1000.0),
        (label: "Over $1000", min: 1000.0, max: 10000.0)
    ]
    
    let quickDateRanges = [
        (label: "Today", days: 0),
        (label: "This Week", days: 7),
        (label: "This Month", days: 30),
        (label: "Last 3 Months", days: 90),
        (label: "This Year", days: 365)
    ]
    
    public init(
        currentFilters: ItemFilters,
        onApply: @escaping (ItemFilters) -> Void
    ) {
        self.onApply = onApply
        
        // Initialize from current filters
        self.searchText = currentFilters.searchText ?? ""
        self.selectedCategories = Set(currentFilters.categories ?? [])
        self.minPrice = currentFilters.minPrice.map { Double(truncating: $0 as NSNumber) } ?? 0
        self.maxPrice = currentFilters.maxPrice.map { Double(truncating: $0 as NSNumber) } ?? 10000
        self.useDateFilter = currentFilters.startDate != nil
        if let start = currentFilters.startDate {
            self.startDate = start
        }
        if let end = currentFilters.endDate {
            self.endDate = end
        }
        self.selectedLocations = Set(currentFilters.locationIds ?? [])
        self.selectedTags = Set(currentFilters.tagIds ?? [])
        self.hasPhotos = currentFilters.hasPhotos ?? false
        self.hasReceipt = currentFilters.hasReceipt ?? false
        self.hasWarranty = currentFilters.hasWarranty ?? false
        self.isFavorite = currentFilters.isFavorite ?? false
        
        // Load locations and tags
        loadLocationAndTags()
    }
    
    func toggleCategory(_ category: ItemCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func toggleLocation(_ locationId: UUID) {
        if selectedLocations.contains(locationId) {
            selectedLocations.remove(locationId)
        } else {
            selectedLocations.insert(locationId)
        }
    }
    
    func applyPriceRange(_ range: (label: String, min: Double, max: Double)) {
        minPrice = range.min
        maxPrice = range.max
    }
    
    func applyDateRange(_ range: (label: String, days: Int)) {
        useDateFilter = true
        endDate = Date()
        startDate = Calendar.current.date(byAdding: .day, value: -range.days, to: endDate) ?? endDate
    }
    
    func isDateRangeActive(_ range: (label: String, days: Int)) -> Bool {
        guard useDateFilter else { return false }
        let expectedStart = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let calendar = Calendar.current
        return calendar.isDate(startDate, inSameDayAs: expectedStart) && calendar.isDate(endDate, inSameDayAs: Date())
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedCategories.removeAll()
        minPrice = 0
        maxPrice = 10000
        useDateFilter = false
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
        selectedLocations.removeAll()
        selectedTags.removeAll()
        hasPhotos = false
        hasReceipt = false
        hasWarranty = false
        isFavorite = false
    }
    
    func applyFilters() {
        let filters = ItemFilters(
            searchText: searchText.isEmpty ? nil : searchText,
            categories: selectedCategories.isEmpty ? nil : Array(selectedCategories),
            minPrice: minPrice > 0 ? Decimal(minPrice) : nil,
            maxPrice: maxPrice < 10000 ? Decimal(maxPrice) : nil,
            startDate: useDateFilter ? startDate : nil,
            endDate: useDateFilter ? endDate : nil,
            locationIds: selectedLocations.isEmpty ? nil : Array(selectedLocations),
            tagIds: selectedTags.isEmpty ? nil : Array(selectedTags),
            hasPhotos: hasPhotos ? true : nil,
            hasReceipt: hasReceipt ? true : nil,
            hasWarranty: hasWarranty ? true : nil,
            isFavorite: isFavorite ? true : nil
        )
        
        onApply(filters)
    }
    
    private func loadLocationAndTags() {
        // In a real app, these would be loaded from repositories
        // For now, using preview data
        locations = Location.previews
        tags = Tag.previews
    }
}

/// Item filters model
public struct ItemFilters: Equatable {
    public var searchText: String?
    public var categories: [ItemCategory]?
    public var minPrice: Decimal?
    public var maxPrice: Decimal?
    public var startDate: Date?
    public var endDate: Date?
    public var locationIds: [UUID]?
    public var tagIds: [UUID]?
    public var hasPhotos: Bool?
    public var hasReceipt: Bool?
    public var hasWarranty: Bool?
    public var isFavorite: Bool?
    
    public init(
        searchText: String? = nil,
        categories: [ItemCategory]? = nil,
        minPrice: Decimal? = nil,
        maxPrice: Decimal? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        locationIds: [UUID]? = nil,
        tagIds: [UUID]? = nil,
        hasPhotos: Bool? = nil,
        hasReceipt: Bool? = nil,
        hasWarranty: Bool? = nil,
        isFavorite: Bool? = nil
    ) {
        self.searchText = searchText
        self.categories = categories
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.startDate = startDate
        self.endDate = endDate
        self.locationIds = locationIds
        self.tagIds = tagIds
        self.hasPhotos = hasPhotos
        self.hasReceipt = hasReceipt
        self.hasWarranty = hasWarranty
        self.isFavorite = isFavorite
    }
    
    public static let empty = ItemFilters()
    
    public var isEmpty: Bool {
        searchText == nil &&
        categories == nil &&
        minPrice == nil &&
        maxPrice == nil &&
        startDate == nil &&
        endDate == nil &&
        locationIds == nil &&
        tagIds == nil &&
        hasPhotos == nil &&
        hasReceipt == nil &&
        hasWarranty == nil &&
        isFavorite == nil
    }
    
    public var activeCount: Int {
        var count = 0
        if searchText != nil { count += 1 }
        if categories != nil { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if startDate != nil || endDate != nil { count += 1 }
        if locationIds != nil { count += 1 }
        if tagIds != nil { count += 1 }
        if hasPhotos != nil { count += 1 }
        if hasReceipt != nil { count += 1 }
        if hasWarranty != nil { count += 1 }
        if isFavorite != nil { count += 1 }
        return count
    }
}