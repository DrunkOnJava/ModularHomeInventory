import SwiftUI
import Core
import Scanner
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
        receiptsModule: (any ReceiptsModuleAPI)? = nil
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
    }
}