import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

/// Service for integrating with iOS Spotlight Search
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class SpotlightService: ObservableObject {
    public static let shared = SpotlightService()
    
    private let spotlightIndex = CSSearchableIndex.default()
    private let domainIdentifier = "com.homeinventory.items"
    
    // Activity types
    public static let viewItemActivityType = "com.homeinventory.viewItem"
    public static let searchItemsActivityType = "com.homeinventory.searchItems"
    
    private init() {
        setupActivityTypes()
    }
    
    // MARK: - Setup
    
    private func setupActivityTypes() {
        // Register activity types for handoff
        let viewItemActivity = NSUserActivity(activityType: Self.viewItemActivityType)
        viewItemActivity.isEligibleForSearch = true
        viewItemActivity.isEligibleForHandoff = true
        viewItemActivity.isEligibleForPublicIndexing = false
        
        let searchActivity = NSUserActivity(activityType: Self.searchItemsActivityType)
        searchActivity.isEligibleForSearch = true
        searchActivity.isEligibleForHandoff = true
        searchActivity.isEligibleForPublicIndexing = false
    }
    
    // MARK: - Indexing Items
    
    /// Index a single item for Spotlight search
    public func indexItem(_ item: Item, location: Location? = nil) async throws {
        let searchableItem = createSearchableItem(for: item, location: location)
        try await spotlightIndex.indexSearchableItems([searchableItem])
    }
    
    /// Index multiple items for Spotlight search
    public func indexItems(_ items: [Item], locationLookup: [UUID: Location] = [:]) async throws {
        let searchableItems = items.map { item in
            createSearchableItem(for: item, location: locationLookup[item.locationId ?? UUID()])
        }
        
        // Index in batches to avoid memory issues
        let batchSize = 100
        for i in stride(from: 0, to: searchableItems.count, by: batchSize) {
            let batch = Array(searchableItems[i..<min(i + batchSize, searchableItems.count)])
            try await spotlightIndex.indexSearchableItems(batch)
        }
    }
    
    /// Remove an item from Spotlight index
    public func removeItem(id: UUID) async throws {
        try await spotlightIndex.deleteSearchableItems(withIdentifiers: [id.uuidString])
    }
    
    /// Remove multiple items from Spotlight index
    public func removeItems(ids: [UUID]) async throws {
        let identifiers = ids.map { $0.uuidString }
        try await spotlightIndex.deleteSearchableItems(withIdentifiers: identifiers)
    }
    
    /// Clear all indexed items
    public func clearIndex() async throws {
        try await spotlightIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
    }
    
    /// Reindex all items
    public func reindexAllItems(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) async throws {
        // Clear existing index
        try await clearIndex()
        
        // Fetch all items and locations
        let items = try await itemRepository.fetchAll()
        let locations = try await locationRepository.fetchAll()
        let locationLookup = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        
        // Index all items
        try await indexItems(items, locationLookup: locationLookup)
    }
    
    // MARK: - Create Searchable Item
    
    private func createSearchableItem(for item: Item, location: Location?) -> CSSearchableItem {
        // Create attribute set
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        
        // Basic attributes
        attributeSet.title = item.name
        attributeSet.contentDescription = createDescription(for: item, location: location)
        
        // Additional searchable content
        var keywords = [item.name, item.category.rawValue]
        
        if let brand = item.brand {
            keywords.append(brand)
            attributeSet.organizationName = brand
        }
        
        if let model = item.model {
            keywords.append(model)
            attributeSet.identifier = model
        }
        
        if let barcode = item.barcode {
            keywords.append(barcode)
        }
        
        if let serialNumber = item.serialNumber {
            keywords.append(serialNumber)
        }
        
        if let location = location {
            keywords.append(location.name)
            attributeSet.namedLocation = location.name
        }
        
        // Add tags
        keywords.append(contentsOf: item.tags)
        
        // Add notes if available
        if let notes = item.notes, !notes.isEmpty {
            attributeSet.comment = notes
        }
        
        // Set keywords
        attributeSet.keywords = keywords
        
        // Set dates
        attributeSet.metadataModificationDate = item.updatedAt
        
        // Set price if available
        if let price = item.value {
            attributeSet.information = "Value: \(price.formatted(.currency(code: "USD")))"
        }
        
        // Thumbnail (would be set if we had image data)
        // attributeSet.thumbnailData = thumbnailData
        
        // Create searchable item
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        
        // Set expiration (never expire)
        searchableItem.expirationDate = Date.distantFuture
        
        return searchableItem
    }
    
    private func createDescription(for item: Item, location: Location?) -> String {
        var components: [String] = []
        
        // Category
        components.append(item.category.rawValue)
        
        // Location
        if let location = location {
            components.append("at \(location.name)")
        }
        
        // Quantity
        if item.quantity > 1 {
            components.append("Quantity: \(item.quantity)")
        }
        
        // Condition
        components.append("Condition: \(item.condition.displayName)")
        
        // Purchase date
        if let purchaseDate = item.purchaseDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            components.append("Purchased: \(formatter.string(from: purchaseDate))")
        }
        
        return components.joined(separator: " • ")
    }
    
    // MARK: - Handle User Activity
    
    /// Create a user activity for viewing an item
    public func createViewItemActivity(for item: Item) -> NSUserActivity {
        let activity = NSUserActivity(activityType: Self.viewItemActivityType)
        
        activity.title = "View \(item.name)"
        activity.userInfo = ["itemId": item.id.uuidString]
        
        // Set search attributes
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = item.name
        attributes.contentDescription = "View details for \(item.name)"
        
        activity.contentAttributeSet = attributes
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = false
        
        // Add keywords for Siri suggestions
        activity.keywords = Set([item.name, item.category.rawValue])
        
        return activity
    }
    
    /// Handle continuing a user activity
    public func handleUserActivity(
        _ userActivity: NSUserActivity,
        itemRepository: any ItemRepository
    ) async throws -> Item? {
        switch userActivity.activityType {
        case Self.viewItemActivityType:
            // Handle view item activity
            if let itemIdString = userActivity.userInfo?["itemId"] as? String,
               let itemId = UUID(uuidString: itemIdString) {
                return try await itemRepository.fetch(id: itemId)
            }
            
        case CSSearchableItemActionType:
            // Handle Spotlight search result tap
            if let itemIdString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
               let itemId = UUID(uuidString: itemIdString) {
                return try await itemRepository.fetch(id: itemId)
            }
            
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Spotlight Maintenance
    
    /// Update searchable item when item is modified
    public func updateItem(_ item: Item, location: Location? = nil) async throws {
        // Reindex the item (this will update existing entry)
        try await indexItem(item, location: location)
    }
    
    /// Batch update items
    public func updateItems(_ items: [Item], locationLookup: [UUID: Location] = [:]) async throws {
        try await indexItems(items, locationLookup: locationLookup)
    }
}

// MARK: - Spotlight Query

public extension SpotlightService {
    /// Search for items in Spotlight
    func searchItems(query: String) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            var allItems: [String] = []
            
            let searchQuery = CSSearchQuery(
                queryString: query,
                attributes: ["title", "contentDescription", "keywords"]
            )
            
            searchQuery.foundItemsHandler = { items in
                allItems.append(contentsOf: items)
            }
            
            searchQuery.completionHandler = { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: allItems)
                }
            }
            
            searchQuery.start()
        }
    }
}

// MARK: - Convenience Extensions

public extension Item {
    /// Create a searchable item for this item
    func toSearchableItem(location: Location? = nil) -> CSSearchableItem {
        SpotlightService.shared.createSearchableItem(for: self, location: location)
    }
}