import SwiftUI
import Core

/// Main implementation of the Items module
@MainActor
public final class ItemsModule: ItemsModuleAPI {
    private let dependencies: ItemsModuleDependencies
    
    public init(dependencies: ItemsModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeItemsListView() -> AnyView {
        let viewModel = ItemsListViewModel(
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository
        )
        viewModel.itemsModule = self
        return AnyView(ItemsListView(viewModel: viewModel))
    }
    
    public func makeItemsListView(onSearchTapped: @escaping () -> Void) -> AnyView {
        let viewModel = ItemsListViewModel(
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository
        )
        viewModel.itemsModule = self
        return AnyView(ItemsListView(viewModel: viewModel, onSearchTapped: onSearchTapped))
    }
    
    public func makeItemsListView(onSearchTapped: @escaping () -> Void, onBarcodeSearchTapped: @escaping () -> Void) -> AnyView {
        let viewModel = ItemsListViewModel(
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository
        )
        viewModel.itemsModule = self
        return AnyView(ItemsListView(viewModel: viewModel, onSearchTapped: onSearchTapped, onBarcodeSearchTapped: onBarcodeSearchTapped))
    }
    
    public func makeItemDetailView(item: Item) -> AnyView {
        let viewModel = ItemDetailViewModel(
            item: item,
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository,
            photoRepository: dependencies.photoRepository,
            warrantyRepository: dependencies.warrantyRepository,
            documentRepository: dependencies.documentRepository,
            documentStorage: dependencies.documentStorage,
            cloudStorage: dependencies.cloudStorage,
            itemsModule: self
        )
        return AnyView(ItemDetailView(viewModel: viewModel))
    }
    
    public func makeAddItemView(completion: @escaping (Item) -> Void) -> AnyView {
        let viewModel = AddItemViewModel(
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository,
            itemTemplateRepository: dependencies.itemTemplateRepository,
            photoRepository: dependencies.photoRepository,
            barcodeLookupService: dependencies.barcodeLookupService,
            completion: completion
        )
        viewModel.scannerModule = dependencies.scannerModule
        return AnyView(AddItemView(viewModel: viewModel))
    }
    
    public func makeEditItemView(item: Item, completion: @escaping (Item) -> Void) -> AnyView {
        let viewModel = EditItemViewModel(
            item: item,
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository,
            completion: completion
        )
        viewModel.scannerModule = dependencies.scannerModule
        return AnyView(EditItemView(viewModel: viewModel))
    }
    
    public func makeSpendingDashboardView() -> AnyView {
        let viewModel = SpendingDashboardViewModel(
            itemRepository: dependencies.itemRepository,
            receiptRepository: dependencies.receiptRepository
        )
        return AnyView(
            NavigationView {
                SpendingDashboardView(viewModel: viewModel)
            }
        )
    }
    
    public func makeCollectionsListView() -> AnyView {
        return AnyView(
            NavigationView {
                CollectionsListView(
                    collectionRepository: dependencies.collectionRepository,
                    itemRepository: dependencies.itemRepository,
                    onSelectCollection: { [weak self] collection in
                        // Navigate to collection detail
                        // This would be handled by the navigation coordinator
                    }
                )
            }
        )
    }
    
    public func makeCollectionDetailView(collection: Collection) -> AnyView {
        return AnyView(
            CollectionDetailView(
                collection: collection,
                collectionRepository: dependencies.collectionRepository,
                itemRepository: dependencies.itemRepository,
                onSelectItem: { [weak self] item in
                    // Navigate to item detail
                    // This would be handled by the navigation coordinator
                }
            )
        )
    }
    
    public func makeReceiptsListView() -> AnyView {
        if let receiptsModule = dependencies.receiptsModule {
            return receiptsModule.makeReceiptsListView()
        } else {
            return AnyView(Text("Receipts module not available"))
        }
    }
    
    public func makeTagsManagementView() -> AnyView {
        return AnyView(
            NavigationView {
                TagsManagementView(tagRepository: dependencies.tagRepository)
            }
        )
    }
    
    public func makeStorageUnitsListView() -> AnyView {
        return AnyView(
            NavigationView {
                StorageUnitsListView(
                    storageUnitRepository: dependencies.storageUnitRepository,
                    locationRepository: dependencies.locationRepository,
                    itemRepository: dependencies.itemRepository
                )
            }
        )
    }
    
    public func makeNaturalLanguageSearchView() -> AnyView {
        return AnyView(
            NaturalLanguageSearchView(
                itemRepository: dependencies.itemRepository,
                searchHistoryRepository: dependencies.searchHistoryRepository,
                savedSearchRepository: dependencies.savedSearchRepository,
                locationRepository: dependencies.locationRepository
                // categoryRepository: dependencies.categoryRepository
            )
        )
    }
    
    public func makeBarcodeSearchView() -> AnyView {
        return AnyView(
            BarcodeSearchView(
                itemRepository: dependencies.itemRepository,
                scannerModule: dependencies.scannerModule,
                searchHistoryRepository: dependencies.searchHistoryRepository
            )
        )
    }
    
    public func makeRetailerAnalyticsView() -> AnyView {
        return AnyView(
            RetailerAnalyticsView(
                itemRepository: dependencies.itemRepository,
                receiptRepository: dependencies.receiptRepository
            )
        )
    }
    
    public func makeTimeBasedAnalyticsView() -> AnyView {
        return AnyView(
            TimeBasedAnalyticsView(
                itemRepository: dependencies.itemRepository
            )
        )
    }
    
    public func makeDepreciationReportView() -> AnyView {
        return AnyView(
            DepreciationReportView(
                itemRepository: dependencies.itemRepository
            )
        )
    }
}