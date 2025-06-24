import Foundation
import CoreSpotlight
import Combine

/// Manager for handling Spotlight search integration across the app
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class SpotlightIntegrationManager: ObservableObject {
    public static let shared = SpotlightIntegrationManager()
    
    @Published public var isIndexing = false
    @Published public var indexedItemCount = 0
    @Published public var lastIndexDate: Date?
    
    private let spotlightService = SpotlightService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Repositories
    private var itemRepository: (any ItemRepository)?
    private var locationRepository: (any LocationRepository)?
    
    // Settings
    private let indexingEnabledKey = "spotlight.indexingEnabled"
    private let lastIndexDateKey = "spotlight.lastIndexDate"
    
    public var isIndexingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: indexingEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: indexingEnabledKey)
            if newValue {
                Task { await startIndexing() }
            } else {
                Task { await clearIndex() }
            }
        }
    }
    
    private init() {
        loadLastIndexDate()
        setupNotificationObservers()
    }
    
    // MARK: - Setup
    
    public func configure(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        
        // Start initial indexing if enabled
        if isIndexingEnabled {
            Task { await startIndexing() }
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for item changes
        NotificationCenter.default.publisher(for: .itemAdded)
            .sink { [weak self] notification in
                guard let self = self,
                      self.isIndexingEnabled,
                      let item = notification.object as? Item else { return }
                
                Task {
                    await self.indexItem(item)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .itemUpdated)
            .sink { [weak self] notification in
                guard let self = self,
                      self.isIndexingEnabled,
                      let item = notification.object as? Item else { return }
                
                Task {
                    await self.updateItem(item)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .itemDeleted)
            .sink { [weak self] notification in
                guard let self = self,
                      self.isIndexingEnabled,
                      let itemId = notification.object as? UUID else { return }
                
                Task {
                    await self.removeItem(itemId)
                }
            }
            .store(in: &cancellables)
        
        // Listen for batch operations
        NotificationCenter.default.publisher(for: .itemsBatchUpdated)
            .sink { [weak self] _ in
                guard let self = self, self.isIndexingEnabled else { return }
                
                Task {
                    await self.reindexAll()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Indexing Operations
    
    public func startIndexing() async {
        guard let itemRepository = itemRepository,
              let locationRepository = locationRepository else { return }
        
        isIndexing = true
        
        do {
            try await spotlightService.reindexAllItems(
                itemRepository: itemRepository,
                locationRepository: locationRepository
            )
            
            let items = try await itemRepository.fetchAll()
            indexedItemCount = items.count
            lastIndexDate = Date()
            saveLastIndexDate()
            
        } catch {
            print("Failed to index items: \(error)")
        }
        
        isIndexing = false
    }
    
    public func reindexAll() async {
        await startIndexing()
    }
    
    public func clearIndex() async {
        do {
            try await spotlightService.clearIndex()
            indexedItemCount = 0
            lastIndexDate = nil
            saveLastIndexDate()
        } catch {
            print("Failed to clear index: \(error)")
        }
    }
    
    // MARK: - Individual Item Operations
    
    private func indexItem(_ item: Item) async {
        guard let locationRepository = locationRepository else { return }
        
        do {
            var location: Location?
            if let locationId = item.locationId {
                location = try await locationRepository.fetch(id: locationId)
            }
            
            try await spotlightService.indexItem(item, location: location)
            indexedItemCount += 1
            
        } catch {
            print("Failed to index item: \(error)")
        }
    }
    
    private func updateItem(_ item: Item) async {
        guard let locationRepository = locationRepository else { return }
        
        do {
            var location: Location?
            if let locationId = item.locationId {
                location = try await locationRepository.fetch(id: locationId)
            }
            
            try await spotlightService.updateItem(item, location: location)
            
        } catch {
            print("Failed to update item in index: \(error)")
        }
    }
    
    private func removeItem(_ itemId: UUID) async {
        do {
            try await spotlightService.removeItem(id: itemId)
            indexedItemCount = max(0, indexedItemCount - 1)
            
        } catch {
            print("Failed to remove item from index: \(error)")
        }
    }
    
    // MARK: - Batch Operations
    
    public func indexItems(_ items: [Item]) async {
        guard let locationRepository = locationRepository else { return }
        
        do {
            let locations = try await locationRepository.fetchAll()
            let locationLookup = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
            
            try await spotlightService.indexItems(items, locationLookup: locationLookup)
            indexedItemCount += items.count
            
        } catch {
            print("Failed to index items: \(error)")
        }
    }
    
    public func removeItems(_ itemIds: [UUID]) async {
        do {
            try await spotlightService.removeItems(ids: itemIds)
            indexedItemCount = max(0, indexedItemCount - itemIds.count)
            
        } catch {
            print("Failed to remove items from index: \(error)")
        }
    }
    
    // MARK: - User Activity Handling
    
    public func handleUserActivity(_ userActivity: NSUserActivity) async -> Item? {
        guard let itemRepository = itemRepository else { return nil }
        
        do {
            return try await spotlightService.handleUserActivity(
                userActivity,
                itemRepository: itemRepository
            )
        } catch {
            print("Failed to handle user activity: \(error)")
            return nil
        }
    }
    
    // MARK: - Persistence
    
    private func loadLastIndexDate() {
        if let timestamp = UserDefaults.standard.object(forKey: lastIndexDateKey) as? TimeInterval {
            lastIndexDate = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    private func saveLastIndexDate() {
        if let date = lastIndexDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastIndexDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastIndexDateKey)
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let itemAdded = Notification.Name("SpotlightIntegration.itemAdded")
    static let itemUpdated = Notification.Name("SpotlightIntegration.itemUpdated")
    static let itemDeleted = Notification.Name("SpotlightIntegration.itemDeleted")
    static let itemsBatchUpdated = Notification.Name("SpotlightIntegration.itemsBatchUpdated")
}