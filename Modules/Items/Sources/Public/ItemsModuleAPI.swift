import SwiftUI
import Core
import Scanner

/// Public API for the Items module
@MainActor
public protocol ItemsModuleAPI: AnyObject {
    /// Creates the main items list view
    func makeItemsListView() -> AnyView
    
    /// Creates the item detail view
    func makeItemDetailView(item: Item) -> AnyView
    
    /// Creates the add item view
    func makeAddItemView(completion: @escaping (Item) -> Void) -> AnyView
    
    /// Creates the edit item view
    func makeEditItemView(item: Item, completion: @escaping (Item) -> Void) -> AnyView
}

/// Dependencies required by the Items module
public struct ItemsModuleDependencies {
    public let itemRepository: any ItemRepository
    public let locationRepository: any LocationRepository
    public let itemTemplateRepository: any ItemTemplateRepository
    public let scannerModule: (any ScannerModuleAPI)?
    
    public init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        scannerModule: (any ScannerModuleAPI)? = nil
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.scannerModule = scannerModule
    }
}