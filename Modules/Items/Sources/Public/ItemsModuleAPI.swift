import SwiftUI
import Core
import BarcodeScanner
import Receipts

/// Public API for the Items module
@MainActor
public protocol ItemsModuleAPI: AnyObject {
    /// Creates the main items list view
    func makeItemsListView() -> AnyView
    
    /// Creates the main items list view with search button handler
    func makeItemsListView(onSearchTapped: @escaping () -> Void) -> AnyView
    
    /// Creates the main items list view with search and barcode search button handlers
    func makeItemsListView(onSearchTapped: @escaping () -> Void, onBarcodeSearchTapped: @escaping () -> Void) -> AnyView
    
    /// Creates the item detail view
    func makeItemDetailView(item: Item) -> AnyView
    
    /// Creates the add item view
    func makeAddItemView(completion: @escaping (Item) -> Void) -> AnyView
    
    /// Creates the edit item view
    func makeEditItemView(item: Item, completion: @escaping (Item) -> Void) -> AnyView
    
    /// Creates the spending dashboard view
    func makeSpendingDashboardView() -> AnyView
    
    /// Creates the collections list view
    func makeCollectionsListView() -> AnyView
    
    /// Creates the collection detail view
    func makeCollectionDetailView(collection: Collection) -> AnyView
    
    /// Creates the receipts list view
    func makeReceiptsListView() -> AnyView
    
    /// Creates the tags management view
    func makeTagsManagementView() -> AnyView
    
    /// Creates the storage units list view
    func makeStorageUnitsListView() -> AnyView
    
    /// Creates the natural language search view
    func makeNaturalLanguageSearchView() -> AnyView
    
    /// Creates the barcode search view
    func makeBarcodeSearchView() -> AnyView
    
    /// Creates the retailer analytics view
    func makeRetailerAnalyticsView() -> AnyView
    
    /// Creates the time-based analytics view
    func makeTimeBasedAnalyticsView() -> AnyView
    
    /// Creates the depreciation report view
    func makeDepreciationReportView() -> AnyView
    
    /// Creates the purchase patterns view
    func makePurchasePatternsView() -> AnyView
    
    /// Creates the budget dashboard view
    func makeBudgetDashboardView() -> AnyView
    
    /// Creates the CSV import view
    func makeCSVImportView(onImportComplete: @escaping (CSVImportResult) -> Void) -> AnyView
    
    /// Creates the CSV export view
    func makeCSVExportView(items: [Item]?) -> AnyView
    
    /// Creates the warranty dashboard view
    func makeWarrantyDashboardView() -> AnyView
    
    /// Creates the warranty notifications view
    func makeWarrantyNotificationsView() -> AnyView
    
    /// Creates the insurance dashboard view
    func makeInsuranceDashboardView() -> AnyView
}

/// Dependencies required by the Items module
public struct ItemsModuleDependencies {
    public let itemRepository: any ItemRepository
    public let locationRepository: any LocationRepository
    public let itemTemplateRepository: any ItemTemplateRepository
    public let photoRepository: any PhotoRepository
    public let barcodeLookupService: any BarcodeLookupService
    public let collectionRepository: any CollectionRepository
    public let tagRepository: any TagRepository
    public let storageUnitRepository: any StorageUnitRepository
    public let warrantyRepository: any WarrantyRepository
    public let documentRepository: any DocumentRepository
    public let documentStorage: DocumentStorageProtocol
    public let cloudStorage: CloudDocumentStorageProtocol?
    public let searchHistoryRepository: any SearchHistoryRepository
    public let savedSearchRepository: any SavedSearchRepository
    // public let categoryRepository: any CategoryRepository
    public let receiptRepository: (any ReceiptRepository)?
    public let scannerModule: (any ScannerModuleAPI)?
    public let receiptsModule: (any ReceiptsModuleAPI)?
    public let budgetRepository: (any BudgetRepository)?
    public let insuranceRepository: any InsurancePolicyRepository
    public let serviceRecordRepository: any ServiceRecordRepository
    
    public init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        photoRepository: any PhotoRepository,
        barcodeLookupService: any BarcodeLookupService,
        collectionRepository: any CollectionRepository,
        tagRepository: any TagRepository,
        storageUnitRepository: any StorageUnitRepository,
        warrantyRepository: any WarrantyRepository,
        documentRepository: any DocumentRepository,
        documentStorage: DocumentStorageProtocol,
        cloudStorage: CloudDocumentStorageProtocol? = nil,
        searchHistoryRepository: (any SearchHistoryRepository)? = nil,
        savedSearchRepository: (any SavedSearchRepository)? = nil,
        // categoryRepository: (any CategoryRepository)? = nil,
        receiptRepository: (any ReceiptRepository)? = nil,
        scannerModule: (any ScannerModuleAPI)? = nil,
        receiptsModule: (any ReceiptsModuleAPI)? = nil,
        budgetRepository: (any BudgetRepository)? = nil,
        insuranceRepository: any InsurancePolicyRepository,
        serviceRecordRepository: any ServiceRecordRepository
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.photoRepository = photoRepository
        self.barcodeLookupService = barcodeLookupService
        self.collectionRepository = collectionRepository
        self.tagRepository = tagRepository
        self.storageUnitRepository = storageUnitRepository
        self.warrantyRepository = warrantyRepository
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        self.cloudStorage = cloudStorage
        self.searchHistoryRepository = searchHistoryRepository ?? DefaultSearchHistoryRepository()
        self.savedSearchRepository = savedSearchRepository ?? DefaultSavedSearchRepository()
        // self.categoryRepository = categoryRepository ?? InMemoryCategoryRepository()
        self.receiptRepository = receiptRepository
        self.scannerModule = scannerModule
        self.receiptsModule = receiptsModule
        self.budgetRepository = budgetRepository
        self.insuranceRepository = insuranceRepository
        self.serviceRecordRepository = serviceRecordRepository
    }
}