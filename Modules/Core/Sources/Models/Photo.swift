import Foundation

/// Photo model for item images
public struct Photo: Identifiable, Codable, Equatable {
    public let id: UUID
    public let itemId: UUID
    public var caption: String?
    public var sortOrder: Int
    public let createdAt: Date
    public var updatedAt: Date
    
    /// Transient property for image data
    public var imageData: Data?
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        caption: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.caption = caption
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, itemId, caption, sortOrder, createdAt, updatedAt
    }
}

// MARK: - Photo Storage Protocol
public protocol PhotoStorageProtocol {
    func savePhoto(_ imageData: Data, for photoId: UUID) async throws -> URL
    func loadPhoto(for photoId: UUID) async throws -> Data
    func deletePhoto(for photoId: UUID) async throws
    func generateThumbnail(_ imageData: Data, size: CGSize) async throws -> Data
}

// MARK: - Photo Repository Protocol
public protocol PhotoRepository {
    func savePhoto(_ photo: Photo, imageData: Data) async throws
    func loadPhotos(for itemId: UUID) async throws -> [Photo]
    func loadPhoto(id: UUID) async throws -> Photo?
    func deletePhoto(id: UUID) async throws
    func updatePhotoOrder(itemId: UUID, photoIds: [UUID]) async throws
    func updatePhotoCaption(id: UUID, caption: String?) async throws
}