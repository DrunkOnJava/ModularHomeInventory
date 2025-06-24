import Foundation
import Core
import Combine


/// Factory for creating Items module with dependencies
public struct ItemsModuleFactory {
    
    /// Creates an Items module with mock repositories for development
    @MainActor
    public static func makeModule() -> (module: ItemsModuleAPI, repositories: (items: any ItemRepository, locations: any LocationRepository, templates: any ItemTemplateRepository)) {
        let itemRepository = ItemRepositoryImplementation()
        let locationRepository = LocationRepositoryImplementation()
        let itemTemplateRepository = ItemTemplateRepositoryImplementation()
        let photoRepository = try! CoreModule.makePhotoRepository()
        let barcodeLookupService = DefaultBarcodeLookupService()
        let collectionRepository = DefaultCollectionRepository()
        let tagRepository = Core.DefaultTagRepository()
        let storageUnitRepository = Core.DefaultStorageUnitRepository()
        let warrantyRepository = MockWarrantyRepository()
        let documentRepository = Core.DefaultDocumentRepository()
        let documentStorage = try! FileDocumentStorage()
        let insuranceRepository = MockInsurancePolicyRepository()
        let serviceRecordRepository = MockServiceRecordRepositoryForItemsModule()
        
        let dependencies = ItemsModuleDependencies(
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
            insuranceRepository: insuranceRepository,
            serviceRecordRepository: serviceRecordRepository
        )
        
        let module = ItemsModule(dependencies: dependencies)
        
        return (module, (itemRepository, locationRepository, itemTemplateRepository))
    }
    
    /// Creates an Items module with provided repositories
    @MainActor
    public static func makeModule(
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
        insuranceRepository: any InsurancePolicyRepository,
        serviceRecordRepository: any ServiceRecordRepository
    ) -> ItemsModuleAPI {
        let dependencies = ItemsModuleDependencies(
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
            insuranceRepository: insuranceRepository,
            serviceRecordRepository: serviceRecordRepository
        )
        
        return ItemsModule(dependencies: dependencies)
    }
}

// MARK: - Mock Warranty Repository for Factory
private final class MockWarrantyRepository: WarrantyRepository {
    private var warranties: [Warranty] = []
    @Published private var warrantiesSubject: [Warranty] = []
    
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

// MARK: - Mock Service Record Repository for Factory
private final class MockServiceRecordRepositoryForItemsModule: ServiceRecordRepository {
    private var serviceRecords: [ServiceRecord] = []
    private let serviceRecordsSubject = CurrentValueSubject<[ServiceRecord], Never>([])
    
    var serviceRecordsPublisher: AnyPublisher<[ServiceRecord], Never> {
        serviceRecordsSubject.eraseToAnyPublisher()
    }
    
    func fetchAll() async throws -> [ServiceRecord] {
        serviceRecords
    }
    
    func fetch(id: UUID) async throws -> ServiceRecord? {
        serviceRecords.first { $0.id == id }
    }
    
    func fetchRecords(for itemId: UUID) async throws -> [ServiceRecord] {
        serviceRecords.filter { $0.itemId == itemId }
    }
    
    func fetchByType(_ type: ServiceType) async throws -> [ServiceRecord] {
        serviceRecords.filter { $0.type == type }
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [ServiceRecord] {
        serviceRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }
    
    func fetchUpcoming(within days: Int) async throws -> [ServiceRecord] {
        let cutoffDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        return serviceRecords.filter { record in
            if let nextServiceDate = record.nextServiceDate {
                return nextServiceDate <= cutoffDate && nextServiceDate >= Date()
            }
            return false
        }
    }
    
    func save(_ record: ServiceRecord) async throws {
        if let index = serviceRecords.firstIndex(where: { $0.id == record.id }) {
            serviceRecords[index] = record
        } else {
            serviceRecords.append(record)
        }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    func delete(_ record: ServiceRecord) async throws {
        serviceRecords.removeAll { $0.id == record.id }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    func delete(id: UUID) async throws {
        serviceRecords.removeAll { $0.id == id }
        serviceRecordsSubject.send(serviceRecords)
    }
    
    func search(query: String) async throws -> [ServiceRecord] {
        let lowercasedQuery = query.lowercased()
        return serviceRecords.filter { record in
            record.provider.lowercased().contains(lowercasedQuery) ||
            record.description.lowercased().contains(lowercasedQuery) ||
            (record.notes?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
}