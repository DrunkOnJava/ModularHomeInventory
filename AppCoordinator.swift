import SwiftUI
import Core
import SharedUI
import Items
import BarcodeScanner
import AppSettings
import Receipts
import Sync
import Premium
import Onboarding
import Combine


@MainActor
final class AppCoordinator: ObservableObject {
    // Module instances
    private(set) var itemsModule: Items.ItemsModuleAPI!
    private(set) var scannerModule: BarcodeScanner.ScannerModuleAPI!
    private(set) var settingsModule: SettingsModuleAPI!
    private(set) var receiptsModule: Receipts.ReceiptsModuleAPI!
    private(set) var syncModule: Sync.SyncModuleAPI!
    private(set) var premiumModule: Premium.PremiumModuleAPI!
    private(set) var onboardingModule: Onboarding.OnboardingModuleAPI!
    
    // Mock repositories (temporary - will be replaced with real implementations)
    private let itemRepository = MockItemRepository()
    private let locationRepository = MockLocationRepository()
    private let itemTemplateRepository = MockItemTemplateRepository()
    private let receiptRepository = MockReceiptRepository()
    private let emailService = MockEmailService()
    private let ocrService = MockOCRService()
    
    init() {
        setupModules()
    }
    
    private func setupModules() {
        // Initialize Settings module first to get settings storage
        let settingsStorage = Core.UserDefaultsSettingsStorage()
        let settingsDependencies = SettingsModuleDependencies(
            settingsStorage: settingsStorage,
            itemRepository: itemRepository,
            receiptRepository: receiptRepository,
            locationRepository: locationRepository
        )
        settingsModule = SettingsModule(dependencies: settingsDependencies)
        
        // Create scan history repository
        let scanHistoryRepository = Core.DefaultScanHistoryRepository()
        
        // Create offline scan queue repository
        let offlineScanQueueRepository = Core.DefaultOfflineScanQueueRepository()
        
        // Create network monitor
        let networkMonitor = NetworkMonitor.shared
        
        // Create barcode lookup service (moved up from below)
        let barcodeLookupService = DefaultBarcodeLookupService()
        
        // Initialize Scanner module with settings storage
        let scannerDependencies = BarcodeScanner.ScannerModuleDependencies(
            itemRepository: itemRepository,
            itemTemplateRepository: itemTemplateRepository,
            settingsStorage: settingsStorage,
            scanHistoryRepository: scanHistoryRepository,
            offlineScanQueueRepository: offlineScanQueueRepository,
            barcodeLookupService: barcodeLookupService,
            networkMonitor: networkMonitor
        )
        scannerModule = BarcodeScanner.ScannerModule(dependencies: scannerDependencies)
        
        // Create photo repository
        let photoRepository = try! CoreModule.makePhotoRepository()
        
        // Create collection repository
        let collectionRepository = DefaultCollectionRepository()
        
        // Create tag repository
        let tagRepository = Core.DefaultTagRepository()
        
        // Create storage unit repository
        let storageUnitRepository = Core.DefaultStorageUnitRepository()
        
        // Create warranty repository
        let warrantyRepository = MockWarrantyRepository()
        
        // Create document repository and storage
        let documentRepository = Core.DefaultDocumentRepository()
        let documentStorage = try! FileDocumentStorage()
        let cloudStorage: CloudDocumentStorageProtocol? = nil // TODO: Add cloud storage when available
        
        // Initialize Receipts module first
        let receiptsDependencies = Receipts.ReceiptsModuleDependencies(
            receiptRepository: receiptRepository,
            itemRepository: itemRepository,
            emailService: emailService,
            ocrService: ocrService
        )
        receiptsModule = Receipts.ReceiptsModule(dependencies: receiptsDependencies)
        
        // Create budget repository
        let budgetRepository = MockBudgetRepository()
        
        // Create insurance repository
        let insuranceRepository = Core.MockInsurancePolicyRepository()
        
        // Initialize Items module with scanner and receipts dependencies
        let itemsDependencies = Items.ItemsModuleDependencies(
            itemRepository: itemRepository,
            locationRepository: locationRepository,
            itemTemplateRepository: itemTemplateRepository,
            photoRepository: photoRepository,
            barcodeLookupService: barcodeLookupService,
            collectionRepository: collectionRepository,
            tagRepository: tagRepository,
            storageUnitRepository: storageUnitRepository,
            warrantyRepository: warrantyRepository,
            documentRepository: documentRepository,
            documentStorage: documentStorage,
            cloudStorage: cloudStorage,
            searchHistoryRepository: nil,
            savedSearchRepository: nil,
            receiptRepository: receiptRepository,
            scannerModule: scannerModule,
            receiptsModule: receiptsModule,
            budgetRepository: budgetRepository,
            insuranceRepository: insuranceRepository
        )
        itemsModule = Items.ItemsModule(dependencies: itemsDependencies)
        
        // Initialize Sync module
        let cloudService = MockCloudService()
        let syncDependencies = Sync.SyncModuleDependencies(
            itemRepository: itemRepository,
            receiptRepository: receiptRepository,
            locationRepository: locationRepository,
            cloudService: cloudService
        )
        syncModule = Sync.SyncModule(dependencies: syncDependencies)
        
        // Initialize Premium module
        let purchaseService = MockPurchaseService()
        let premiumDependencies = Premium.PremiumModuleDependencies(
            purchaseService: purchaseService
        )
        premiumModule = Premium.PremiumModule(dependencies: premiumDependencies)
        
        // Initialize Onboarding module
        let onboardingDependencies = Onboarding.OnboardingModuleDependencies()
        onboardingModule = Onboarding.OnboardingModule(dependencies: onboardingDependencies)
        
        // Start warranty expiration monitoring
        Core.WarrantyExpirationCheckService.shared.startMonitoring(warrantyRepository: warrantyRepository)
        
        // Start notification monitoring
        Core.NotificationTriggerService.shared.startMonitoring(
            itemRepository: itemRepository,
            warrantyRepository: warrantyRepository,
            budgetRepository: budgetRepository
        )
        
        // Configure Spotlight integration
        Core.SpotlightIntegrationManager.shared.configure(
            itemRepository: itemRepository,
            locationRepository: locationRepository
        )
    }
}

// MARK: - Mock Repositories

final class MockItemRepository: ItemRepository {
    private var items: [Item] = MockDataService.generateComprehensiveItems()
    
    func fetchAll() async throws -> [Item] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return items
    }
    
    func fetch(id: UUID) async throws -> Item? {
        items.first { $0.id == id }
    }
    
    func save(_ entity: Item) async throws {
        if let index = items.firstIndex(where: { $0.id == entity.id }) {
            items[index] = entity
        } else {
            items.append(entity)
        }
    }
    
    func saveAll(_ entities: [Item]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: Item) async throws {
        items.removeAll { $0.id == entity.id }
    }
    
    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }
    
    func search(query: String) async throws -> [Item] {
        items.filter { item in
            item.name.localizedCaseInsensitiveContains(query) ||
            (item.brand?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func fuzzySearch(query: String, threshold: Double = 0.6) async throws -> [Item] {
        let fuzzyService = Core.FuzzySearchService()
        return items.fuzzySearch(query: query, fuzzyService: fuzzyService)
    }
    
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item] {
        items.filter { $0.category == category }
    }
    
    func fetchByCategoryId(_ categoryId: UUID) async throws -> [Item] {
        items.filter { $0.categoryId == categoryId }
    }
    
    func fetchByLocation(_ locationId: UUID) async throws -> [Item] {
        items.filter { $0.locationId == locationId }
    }
    
    func fetchByBarcode(_ barcode: String) async throws -> Item? {
        items.first { $0.barcode == barcode }
    }
    
    func searchWithCriteria(_ criteria: ItemSearchCriteria) async throws -> [Item] {
        var results = items
        
        // Filter by search text
        if let searchText = criteria.searchText, !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            results = results.filter { item in
                item.name.lowercased().contains(lowercased) ||
                (item.brand?.lowercased().contains(lowercased) ?? false) ||
                (item.model?.lowercased().contains(lowercased) ?? false)
            }
        }
        
        // Filter by categories
        if !criteria.categories.isEmpty {
            results = results.filter { criteria.categories.contains($0.category) }
        }
        
        // Add other filters as needed
        
        return results
    }
    
    func fetchItemsUnderWarranty() async throws -> [Item] {
        // In a real implementation, would check warranty dates
        items.filter { $0.warrantyId != nil }
    }
    
    func fetchFavoriteItems() async throws -> [Item] {
        // Mock implementation - return empty array
        []
    }
    
    func fetchRecentlyAdded(days: Int) async throws -> [Item] {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return items.filter { $0.createdAt > cutoffDate }
    }
}

final class MockLocationRepository: LocationRepository {
    private let locations: [Location] = MockDataService.locations
    
    func fetchAll() async throws -> [Location] {
        locations
    }
    
    func fetch(id: UUID) async throws -> Location? {
        locations.first { $0.id == id }
    }
    
    func save(_ entity: Location) async throws {
        // Mock implementation
    }
    
    func saveAll(_ entities: [Location]) async throws {
        // Mock implementation
    }
    
    func delete(_ entity: Location) async throws {
        // Mock implementation
    }
    
    func delete(id: UUID) async throws {
        // Mock implementation
    }
    
    func fetchRootLocations() async throws -> [Location] {
        locations.filter { $0.parentId == nil }
    }
    
    func fetchChildren(of parentId: UUID) async throws -> [Location] {
        locations.filter { $0.parentId == parentId }
    }
}

// MARK: - Mock Receipt Repository

final class MockReceiptRepository: ReceiptRepository {
    private var receipts: [Receipt] = {
        let generated = MockDataService.generateReceipts()
        print("MockReceiptRepository: Generated \(generated.count) receipts")
        return generated
    }()
    
    func fetchAll() async throws -> [Receipt] {
        print("MockReceiptRepository: Returning \(receipts.count) receipts")
        return receipts
    }
    
    func fetch(id: UUID) async throws -> Receipt? {
        receipts.first { $0.id == id }
    }
    
    func save(_ entity: Receipt) async throws {
        if let index = receipts.firstIndex(where: { $0.id == entity.id }) {
            receipts[index] = entity
        } else {
            receipts.append(entity)
        }
    }
    
    func saveAll(_ entities: [Receipt]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: Receipt) async throws {
        receipts.removeAll { $0.id == entity.id }
    }
    
    func delete(id: UUID) async throws {
        receipts.removeAll { $0.id == id }
    }
    
    func search(query: String) async throws -> [Receipt] {
        receipts.filter { receipt in
            receipt.storeName.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Receipt] {
        receipts.filter { receipt in
            receipt.date >= startDate && receipt.date <= endDate
        }
    }
    
    func fetchByStore(_ storeName: String) async throws -> [Receipt] {
        receipts.filter { $0.storeName == storeName }
    }
    
    func fetchByItemId(_ itemId: UUID) async throws -> [Receipt] {
        receipts.filter { $0.itemIds.contains(itemId) }
    }
    
    func fetchAboveAmount(_ amount: Decimal) async throws -> [Receipt] {
        receipts.filter { $0.totalAmount > amount }
    }
}

// MARK: - Mock Email Service

final class MockEmailService: EmailServiceProtocol {
    func fetchEmails(from sender: String?, matching criteria: String?) async throws -> [EmailMessage] {
        // Return mock email data
        return []
    }
    
    func parseReceiptFromEmail(_ email: EmailMessage) async throws -> ParsedEmailReceipt? {
        // Mock implementation
        return nil
    }
}

// MARK: - Mock OCR Service (Will be replaced with VisionOCRService when available)

final class MockOCRService: OCRServiceProtocol {
    #if canImport(UIKit)
    func extractText(from image: UIImage) async throws -> OCRResult {
        // For now, return mock data
        // TODO: Replace with VisionOCRService from Receipts module
        OCRResult(
            text: "Mock OCR text\nStore Name\nDate: 12/22/2024\nTotal: $99.99",
            confidence: 0.85,
            language: "en"
        )
    }
    
    func extractReceiptData(from image: UIImage) async throws -> OCRReceiptData? {
        // Mock implementation that simulates real OCR
        OCRReceiptData(
            storeName: "Target",
            date: Date(),
            totalAmount: 99.99,
            items: [
                OCRReceiptItem(name: "Item 1", price: 29.99, quantity: 1),
                OCRReceiptItem(name: "Item 2", price: 49.99, quantity: 1),
                OCRReceiptItem(name: "Tax", price: 20.01, quantity: 1)
            ],
            confidence: 0.85,
            rawText: "Mock receipt text with extracted data"
        )
    }
    #endif
}

// MARK: - Mock Warranty Repository

final class MockWarrantyRepository: WarrantyRepository {
    private var warranties: [Warranty] = MockDataService.generateWarranties()
    @Published private var warrantiesSubject: [Warranty] = MockDataService.generateWarranties()
    
    var warrantiesPublisher: AnyPublisher<[Warranty], Never> {
        $warrantiesSubject.eraseToAnyPublisher()
    }
    
    func fetchAll() async throws -> [Warranty] {
        warranties
    }
    
    func fetch(by id: UUID) async throws -> Warranty? {
        warranties.first { $0.id == id }
    }
    
    func fetch(id: UUID) async throws -> Warranty? {
        warranties.first { $0.id == id }
    }
    
    func fetchWarranties(for itemId: UUID) async throws -> [Warranty] {
        warranties.filter { $0.itemId == itemId }
    }
    
    func save(_ entity: Warranty) async throws {
        if let index = warranties.firstIndex(where: { $0.id == entity.id }) {
            warranties[index] = entity
        } else {
            warranties.append(entity)
        }
        warrantiesSubject = warranties
    }
    
    func saveAll(_ entities: [Warranty]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: Warranty) async throws {
        warranties.removeAll { $0.id == entity.id }
        warrantiesSubject = warranties
    }
    
    func delete(id: UUID) async throws {
        warranties.removeAll { $0.id == id }
        warrantiesSubject = warranties
    }
}

// MARK: - Mock Cloud Service

final class MockCloudService: CloudServiceProtocol {
    private var isLoggedIn = false
    
    func upload<T: Codable>(_ data: T, to path: String) async throws {
        // Mock upload
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    func download<T: Codable>(_ type: T.Type, from path: String) async throws -> T? {
        // Mock download
        return nil
    }
    
    func delete(at path: String) async throws {
        // Mock delete
    }
    
    var isAuthenticated: Bool {
        isLoggedIn
    }
    
    func authenticate() async throws {
        // Mock authentication
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isLoggedIn = true
    }
}

// MARK: - Mock Item Template Repository

final class MockItemTemplateRepository: ItemTemplateRepository {
    private var templates: [ItemTemplate] = ItemTemplate.previews
    
    func fetchAll() async throws -> [ItemTemplate] {
        templates
    }
    
    func fetch(id: UUID) async throws -> ItemTemplate? {
        templates.first { $0.id == id }
    }
    
    func save(_ entity: ItemTemplate) async throws {
        if let index = templates.firstIndex(where: { $0.id == entity.id }) {
            templates[index] = entity
        } else {
            templates.append(entity)
        }
    }
    
    func saveAll(_ entities: [ItemTemplate]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    func delete(_ entity: ItemTemplate) async throws {
        templates.removeAll { $0.id == entity.id }
    }
    
    func delete(id: UUID) async throws {
        templates.removeAll { $0.id == id }
    }
    
    func fetchByCategory(_ category: ItemCategory) async throws -> [ItemTemplate] {
        templates.filter { $0.category == category }
    }
    
    func search(query: String) async throws -> [ItemTemplate] {
        templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.templateName.localizedCaseInsensitiveContains(query) ||
            (template.brand?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Mock Purchase Service

final class MockPurchaseService: PurchaseServiceProtocol {
    func fetchProducts() async throws -> [PremiumProduct] {
        [
            PremiumProduct(
                id: "com.homeinventory.premium.monthly",
                name: "Premium Monthly",
                description: "Unlimited items and all features",
                price: "$4.99",
                period: .monthly
            ),
            PremiumProduct(
                id: "com.homeinventory.premium.yearly",
                name: "Premium Yearly",
                description: "Best value - save 33%",
                price: "$39.99",
                period: .yearly
            )
        ]
    }
    
    func purchase(_ product: PremiumProduct) async throws {
        // Mock purchase
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
    
    func restorePurchases() async throws {
        // Mock restore
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    func hasActiveSubscription() async -> Bool {
        // Mock subscription check
        false
    }
}