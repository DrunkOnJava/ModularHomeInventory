import SwiftUI
import Core
import SharedUI
import Items
import Scanner
import Settings
import Receipts
import Sync
import Premium
import Onboarding

@MainActor
final class AppCoordinator: ObservableObject {
    // Module instances
    private(set) var itemsModule: ItemsModuleAPI!
    private(set) var scannerModule: ScannerModuleAPI!
    private(set) var settingsModule: SettingsModuleAPI!
    private(set) var receiptsModule: ReceiptsModuleAPI!
    private(set) var syncModule: SyncModuleAPI!
    private(set) var premiumModule: PremiumModuleAPI!
    private(set) var onboardingModule: OnboardingModuleAPI!
    
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
        // Initialize Scanner module first
        let scannerDependencies = ScannerModuleDependencies(
            itemRepository: itemRepository,
            itemTemplateRepository: itemTemplateRepository
        )
        scannerModule = ScannerModule(dependencies: scannerDependencies)
        
        // Initialize Items module with scanner dependency
        let itemsDependencies = ItemsModuleDependencies(
            itemRepository: itemRepository,
            locationRepository: locationRepository,
            itemTemplateRepository: itemTemplateRepository,
            scannerModule: scannerModule
        )
        itemsModule = ItemsModule(dependencies: itemsDependencies)
        
        // Initialize Settings module
        let settingsStorage = UserDefaultsSettingsStorage()
        let settingsDependencies = SettingsModuleDependencies(
            settingsStorage: settingsStorage
        )
        settingsModule = SettingsModule(dependencies: settingsDependencies)
        
        // Initialize Receipts module
        let receiptsDependencies = ReceiptsModuleDependencies(
            receiptRepository: receiptRepository,
            itemRepository: itemRepository,
            emailService: emailService,
            ocrService: ocrService
        )
        receiptsModule = ReceiptsModule(dependencies: receiptsDependencies)
        
        // Initialize Sync module
        let cloudService = MockCloudService()
        let syncDependencies = SyncModuleDependencies(
            itemRepository: itemRepository,
            receiptRepository: receiptRepository,
            locationRepository: locationRepository,
            cloudService: cloudService
        )
        syncModule = SyncModule(dependencies: syncDependencies)
        
        // Initialize Premium module
        let purchaseService = MockPurchaseService()
        let premiumDependencies = PremiumModuleDependencies(
            purchaseService: purchaseService
        )
        premiumModule = PremiumModule(dependencies: premiumDependencies)
        
        // Initialize Onboarding module
        let onboardingDependencies = OnboardingModuleDependencies()
        onboardingModule = OnboardingModule(dependencies: onboardingDependencies)
    }
}

// MARK: - Mock Repositories

final class MockItemRepository: ItemRepository {
    private var items: [Item] = Item.previews
    
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
    
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item] {
        items.filter { $0.category == category }
    }
    
    func fetchByLocation(_ locationId: UUID) async throws -> [Item] {
        items.filter { $0.locationId == locationId }
    }
    
    func fetchByBarcode(_ barcode: String) async throws -> Item? {
        items.first { $0.barcode == barcode }
    }
}

final class MockLocationRepository: LocationRepository {
    private let locations: [Location] = Location.previews
    
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
    private var receipts: [Receipt] = Receipt.previews
    
    func fetchAll() async throws -> [Receipt] {
        receipts
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