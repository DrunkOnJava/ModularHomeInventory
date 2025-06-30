import Foundation
import Core
import CoreData

/// In-memory database for testing
public class TestDatabase: Database {
    
    private let container: NSPersistentContainer
    private let isInMemory: Bool
    
    /// Create in-memory test database
    public static func inMemory() async -> TestDatabase {
        return TestDatabase(inMemory: true)
    }
    
    /// Create persistent test database
    public static func persistent(name: String = "TestDatabase") async -> TestDatabase {
        return TestDatabase(inMemory: false, name: name)
    }
    
    private init(inMemory: Bool = true, name: String = "TestDatabase") {
        self.isInMemory = inMemory
        
        container = NSPersistentContainer(name: name)
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test database: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Database Protocol
    
    public var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    public func save() async throws {
        let context = viewContext
        
        guard context.hasChanges else { return }
        
        try await context.perform {
            try context.save()
        }
    }
    
    public func fetch<T>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await viewContext.perform {
            try self.viewContext.fetch(request)
        }
    }
    
    public func delete(_ object: NSManagedObject) async throws {
        await viewContext.perform {
            self.viewContext.delete(object)
        }
        try await save()
    }
    
    // MARK: - Test Helpers
    
    /// Delete all data from the database
    public func deleteAll() async throws {
        let entities = container.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let objects = try await fetch(fetchRequest)
            
            for object in objects {
                try await delete(object)
            }
        }
    }
    
    /// Reset database to initial state
    public func reset() async throws {
        try await deleteAll()
        
        if !isInMemory {
            // Remove persistent store
            let storeCoordinator = container.persistentStoreCoordinator
            for store in storeCoordinator.persistentStores {
                try storeCoordinator.remove(store)
                
                if let url = store.url {
                    try FileManager.default.removeItem(at: url)
                }
            }
            
            // Reload stores
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Failed to reload test database: \(error)")
                }
            }
        }
    }
    
    /// Insert test data
    public func insertTestData<T: NSManagedObject>(
        entityName: String,
        count: Int,
        configure: (T, Int) -> Void
    ) async throws {
        try await viewContext.perform {
            for i in 0..<count {
                let entity = NSEntityDescription.entity(
                    forEntityName: entityName,
                    in: self.viewContext
                )!
                
                let object = T(entity: entity, insertInto: self.viewContext)
                configure(object, i)
            }
            
            try self.viewContext.save()
        }
    }
    
    /// Count entities
    public func count<T: NSManagedObject>(
        for type: T.Type,
        predicate: NSPredicate? = nil
    ) async throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        
        return try await viewContext.perform {
            try self.viewContext.count(for: request)
        }
    }
}

// MARK: - Test Core Data Stack

public class TestCoreDataStack {
    
    public let container: NSPersistentContainer
    
    public init(modelName: String) {
        container = NSPersistentContainer(name: modelName)
        
        // Use in-memory store
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
    }
    
    public var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    public func reset() throws {
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to reload test store: \(error)")
            }
        }
    }
}