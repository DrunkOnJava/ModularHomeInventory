import Foundation

/// Repository protocol for managing categories
/// Swift 5.9 - No Swift 6 features
public protocol CategoryRepository: Repository where Entity == ItemCategoryModel {
    func fetchBuiltIn() async throws -> [ItemCategoryModel]
    func fetchCustom() async throws -> [ItemCategoryModel]
    func fetchByParent(id: UUID?) async throws -> [ItemCategoryModel]
    func canDelete(_ category: ItemCategoryModel) async throws -> Bool
}

/// Default implementation of CategoryRepository
public final class DefaultCategoryRepository: CategoryRepository {
    private let storage: any Storage<ItemCategoryModel>
    private let itemRepository: any ItemRepository
    
    public init(storage: any Storage<ItemCategoryModel>, itemRepository: any ItemRepository) {
        self.storage = storage
        self.itemRepository = itemRepository
    }
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [ItemCategoryModel] {
        return try await storage.fetchAll()
    }
    
    public func fetch(id: UUID) async throws -> ItemCategoryModel? {
        return try await storage.fetch(id: id)
    }
    
    public func save(_ entity: ItemCategoryModel) async throws {
        try await storage.save(entity)
    }
    
    public func saveAll(_ entities: [ItemCategoryModel]) async throws {
        try await storage.saveAll(entities)
    }
    
    public func delete(_ entity: ItemCategoryModel) async throws {
        // Check if category can be deleted
        let canDelete = try await canDelete(entity)
        guard canDelete else {
            throw CategoryError.cannotDeleteCategoryInUse
        }
        
        try await storage.delete(entity)
    }
    
    public func delete(id: UUID) async throws {
        if let entity = try await fetch(id: id) {
            try await delete(entity)
        }
    }
    
    public func search(query: String) async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { category in
            category.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - CategoryRepository Protocol
    
    public func fetchBuiltIn() async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { $0.isBuiltIn }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public func fetchCustom() async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { !$0.isBuiltIn }.sorted { $0.name < $1.name }
    }
    
    public func fetchByParent(id: UUID?) async throws -> [ItemCategoryModel] {
        let all = try await fetchAll()
        return all.filter { $0.parentId == id }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public func canDelete(_ category: ItemCategoryModel) async throws -> Bool {
        // Cannot delete built-in categories
        if category.isBuiltIn {
            return false
        }
        
        // Check if any items use this category
        let items = try await itemRepository.fetchAll()
        let hasItems = items.contains { $0.categoryId == category.id }
        
        // Check if any subcategories exist
        let subcategories = try await fetchByParent(id: category.id)
        let hasSubcategories = !subcategories.isEmpty
        
        return !hasItems && !hasSubcategories
    }
}

// MARK: - Errors
public enum CategoryError: LocalizedError {
    case cannotDeleteBuiltInCategory
    case cannotDeleteCategoryInUse
    case invalidParentCategory
    
    public var errorDescription: String? {
        switch self {
        case .cannotDeleteBuiltInCategory:
            return "Built-in categories cannot be deleted"
        case .cannotDeleteCategoryInUse:
            return "Cannot delete category that contains items or subcategories"
        case .invalidParentCategory:
            return "Invalid parent category"
        }
    }
}

// MARK: - Category Storage Initializer
public extension DefaultCategoryRepository {
    /// Initialize storage with built-in categories if needed
    static func initializeWithBuiltInCategories(storage: any Storage<ItemCategoryModel>) async throws {
        let existing = try await storage.fetchAll()
        
        // Only add built-in categories if storage is empty
        if existing.isEmpty {
            for category in ItemCategoryModel.builtInCategories {
                try await storage.save(category)
            }
        }
    }
}