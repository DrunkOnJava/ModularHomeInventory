import Foundation
import Core

/// Factory for creating Items module with dependencies
public struct ItemsModuleFactory {
    
    /// Creates an Items module with mock repositories for development
    @MainActor
    public static func makeModule() -> (module: ItemsModuleAPI, repositories: (items: any ItemRepository, locations: any LocationRepository, templates: any ItemTemplateRepository)) {
        let itemRepository = ItemRepositoryImplementation()
        let locationRepository = LocationRepositoryImplementation()
        
        let itemTemplateRepository = ItemTemplateRepositoryImplementation()
        
        let dependencies = ItemsModuleDependencies(
            itemRepository: itemRepository,
            locationRepository: locationRepository,
            itemTemplateRepository: itemTemplateRepository
        )
        
        let module = ItemsModule(dependencies: dependencies)
        
        return (module, (itemRepository, locationRepository, itemTemplateRepository))
    }
    
    /// Creates an Items module with provided repositories
    @MainActor
    public static func makeModule(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        itemTemplateRepository: any ItemTemplateRepository
    ) -> ItemsModuleAPI {
        let dependencies = ItemsModuleDependencies(
            itemRepository: itemRepository,
            locationRepository: locationRepository,
            itemTemplateRepository: itemTemplateRepository
        )
        
        return ItemsModule(dependencies: dependencies)
    }
}