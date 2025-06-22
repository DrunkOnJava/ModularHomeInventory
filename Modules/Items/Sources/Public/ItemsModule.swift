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
    
    public func makeItemDetailView(item: Item) -> AnyView {
        let viewModel = ItemDetailViewModel(
            item: item,
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository,
            itemsModule: self
        )
        return AnyView(ItemDetailView(viewModel: viewModel))
    }
    
    public func makeAddItemView(completion: @escaping (Item) -> Void) -> AnyView {
        let viewModel = AddItemViewModel(
            itemRepository: dependencies.itemRepository,
            locationRepository: dependencies.locationRepository,
            itemTemplateRepository: dependencies.itemTemplateRepository,
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
}