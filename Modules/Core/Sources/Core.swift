import Foundation

public struct CoreModule {
    public static func configure() {
        // Module configuration if needed
    }
    
    // Factory methods for creating repositories
    public static func makePhotoRepository() throws -> any PhotoRepository {
        let storage = try FilePhotoStorage()
        return PhotoRepositoryImpl(storage: storage)
    }
    
    public static func makeCloudDocumentStorage() throws -> CloudDocumentStorageProtocol {
        return try ICloudDocumentStorage()
    }
    
    public static func makeThumbnailService() throws -> ThumbnailService {
        return try ThumbnailService()
    }
}