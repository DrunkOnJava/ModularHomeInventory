import Foundation

/// Default implementation of DocumentRepository
/// Swift 5.9 - No Swift 6 features
public final class DefaultDocumentRepository: DocumentRepository {
    private var documents: [Document] = []
    private let userDefaults = UserDefaults.standard
    private let storageKey = "com.homeinventory.documents"
    
    public init() {
        loadFromStorage()
    }
    
    // MARK: - Repository Protocol
    
    public func fetchAll() async throws -> [Document] {
        return documents
    }
    
    public func fetch(id: UUID) async throws -> Document? {
        return documents.first { $0.id == id }
    }
    
    public func save(_ entity: Document) async throws {
        if let index = documents.firstIndex(where: { $0.id == entity.id }) {
            documents[index] = entity
        } else {
            documents.append(entity)
        }
        saveToStorage()
    }
    
    public func saveAll(_ entities: [Document]) async throws {
        for entity in entities {
            try await save(entity)
        }
    }
    
    public func delete(_ entity: Document) async throws {
        documents.removeAll { $0.id == entity.id }
        saveToStorage()
    }
    
    public func delete(id: UUID) async throws {
        documents.removeAll { $0.id == id }
        saveToStorage()
    }
    
    // MARK: - DocumentRepository Protocol
    
    public func fetchByItemId(_ itemId: UUID) async throws -> [Document] {
        return documents.filter { $0.itemId == itemId }
    }
    
    public func fetchByCategory(_ category: Document.DocumentCategory) async throws -> [Document] {
        return documents.filter { $0.category == category }
    }
    
    public func search(query: String) async throws -> [Document] {
        let lowercasedQuery = query.lowercased()
        return documents.filter { document in
            document.name.lowercased().contains(lowercasedQuery) ||
            document.tags.contains { $0.lowercased().contains(lowercasedQuery) } ||
            (document.notes?.lowercased().contains(lowercasedQuery) ?? false) ||
            (document.searchableText?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    public func fetchByTags(_ tags: [String]) async throws -> [Document] {
        return documents.filter { document in
            !Set(document.tags).intersection(tags).isEmpty
        }
    }
    
    public func updateSearchableText(documentId: UUID, text: String) async throws {
        if let index = documents.firstIndex(where: { $0.id == documentId }) {
            documents[index].searchableText = text
            documents[index].updatedAt = Date()
            saveToStorage()
        }
    }
    
    public func getTotalStorageSize() async throws -> Int64 {
        return documents.reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - Private Methods
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(documents) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadFromStorage() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Document].self, from: data) {
            self.documents = decoded
        }
    }
}

// MARK: - File-based Document Storage
public final class FileDocumentStorage: DocumentStorageProtocol {
    private let documentsDirectory: URL
    
    public init() throws {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsPath = paths.first else {
            throw DocumentStorageError.directoryNotFound
        }
        
        self.documentsDirectory = documentsPath.appendingPathComponent("Documents", isDirectory: true)
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }
    
    public func saveDocument(_ data: Data, documentId: UUID) async throws -> URL {
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).pdf")
        try data.write(to: fileURL)
        return fileURL
    }
    
    public func loadDocument(documentId: UUID) async throws -> Data {
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).pdf")
        return try Data(contentsOf: fileURL)
    }
    
    public func deleteDocument(documentId: UUID) async throws {
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).pdf")
        try FileManager.default.removeItem(at: fileURL)
    }
    
    public func getDocumentURL(documentId: UUID) -> URL? {
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).pdf")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    public func documentExists(documentId: UUID) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).pdf")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

// MARK: - Error Types
public enum DocumentStorageError: LocalizedError {
    case directoryNotFound
    case documentNotFound
    case saveFailed
    case deleteFailed
    
    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Documents directory not found"
        case .documentNotFound:
            return "Document not found"
        case .saveFailed:
            return "Failed to save document"
        case .deleteFailed:
            return "Failed to delete document"
        }
    }
}