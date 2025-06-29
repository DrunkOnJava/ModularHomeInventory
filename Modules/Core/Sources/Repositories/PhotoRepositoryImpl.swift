import Foundation
import UIKit

/// Concrete implementation of PhotoRepository
public final class PhotoRepositoryImpl: PhotoRepository {
    private let storage: PhotoStorageProtocol
    private var photoCache: [UUID: Photo] = [:]
    private let cacheQueue = DispatchQueue(label: "com.modularhome.photoCache", attributes: .concurrent)
    
    public init(storage: PhotoStorageProtocol) {
        self.storage = storage
    }
    
    public func savePhoto(_ photo: Photo, imageData: Data) async throws {
        // Save image to storage
        _ = try await storage.savePhoto(imageData, for: photo.id)
        
        // Cache the photo metadata
        cacheQueue.async(flags: .barrier) {
            self.photoCache[photo.id] = photo
        }
    }
    
    public func loadPhotos(for itemId: UUID) async throws -> [Photo] {
        // In a real implementation, this would load from persistent storage
        // For now, return cached photos for the item
        var photos = cacheQueue.sync {
            photoCache.values
                .filter { $0.itemId == itemId }
                .sorted { $0.sortOrder < $1.sortOrder }
        }
        
        // Load images for each photo
        for i in 0..<photos.count {
            do {
                let imageData = try await storage.loadPhoto(for: photos[i].id)
                photos[i].imageData = imageData
            } catch {
                print("Failed to load image for photo \(photos[i].id): \(error)")
            }
        }
        
        return photos
    }
    
    public func loadPhoto(id: UUID) async throws -> Photo? {
        var photo = cacheQueue.sync {
            photoCache[id]
        }
        
        if photo != nil {
            // Load the actual image
            do {
                let imageData = try await storage.loadPhoto(for: id)
                photo?.imageData = imageData
            } catch {
                print("Failed to load image for photo \(id): \(error)")
            }
        }
        
        return photo
    }
    
    public func deletePhoto(id: UUID) async throws {
        // Delete from storage
        try await storage.deletePhoto(for: id)
        
        // Remove from cache
        cacheQueue.async(flags: .barrier) {
            self.photoCache.removeValue(forKey: id)
        }
    }
    
    public func updatePhotoOrder(itemId: UUID, photoIds: [UUID]) async throws {
        cacheQueue.async(flags: .barrier) {
            for (index, photoId) in photoIds.enumerated() {
                if var photo = self.photoCache[photoId], photo.itemId == itemId {
                    photo.sortOrder = index
                    photo.updatedAt = Date()
                    self.photoCache[photoId] = photo
                }
            }
        }
    }
    
    public func updatePhotoCaption(id: UUID, caption: String?) async throws {
        cacheQueue.async(flags: .barrier) {
            if var photo = self.photoCache[id] {
                photo.caption = caption
                photo.updatedAt = Date()
                self.photoCache[id] = photo
            }
        }
    }
}

/// File-based photo storage implementation
public final class FilePhotoStorage: PhotoStorageProtocol {
    private let documentsDirectory: URL
    private let photosDirectory: URL
    private let thumbnailsDirectory: URL
    
    public init() throws {
        // Get documents directory
        documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // Create photos directory
        photosDirectory = documentsDirectory.appendingPathComponent("Photos")
        try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        
        // Create thumbnails directory
        thumbnailsDirectory = documentsDirectory.appendingPathComponent("Thumbnails")
        try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }
    
    public func savePhoto(_ imageData: Data, for photoId: UUID) async throws -> URL {
        let photoURL = photosDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
        
        // Save the image data
        try imageData.write(to: photoURL)
        
        // Generate and save thumbnail
        guard let image = UIImage(data: imageData) else {
            throw PhotoStorageError.invalidImageData
        }
        
        let thumbnailData = try await generateThumbnail(imageData, size: CGSize(width: 200, height: 200))
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
        
        try thumbnailData.write(to: thumbnailURL)
        
        return photoURL
    }
    
    public func loadPhoto(for photoId: UUID) async throws -> Data {
        let photoURL = photosDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
        
        guard FileManager.default.fileExists(atPath: photoURL.path) else {
            throw PhotoStorageError.photoNotFound
        }
        
        let imageData = try Data(contentsOf: photoURL)
        return imageData
    }
    
    public func deletePhoto(for photoId: UUID) async throws {
        let photoURL = photosDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
        
        if FileManager.default.fileExists(atPath: photoURL.path) {
            try FileManager.default.removeItem(at: photoURL)
        }
        
        if FileManager.default.fileExists(atPath: thumbnailURL.path) {
            try FileManager.default.removeItem(at: thumbnailURL)
        }
    }
    
    public func generateThumbnail(_ imageData: Data, size: CGSize) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = UIImage(data: imageData) else {
                    continuation.resume(throwing: PhotoStorageError.invalidImageData)
                    return
                }
                
                let renderer = UIGraphicsImageRenderer(size: size)
                let thumbnail = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                
                guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
                    continuation.resume(throwing: PhotoStorageError.compressionFailed)
                    return
                }
                
                continuation.resume(returning: thumbnailData)
            }
        }
    }
}

// MARK: - Errors
public enum PhotoStorageError: LocalizedError {
    case compressionFailed
    case photoNotFound
    case invalidImageData
    
    public var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .photoNotFound:
            return "Photo not found"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}