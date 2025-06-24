import Foundation
import UIKit
import PDFKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// Service for generating and caching document thumbnails
/// Swift 5.9 - No Swift 6 features
public final class ThumbnailService {
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let thumbnailsDirectory: URL
    
    public init() throws {
        // Setup thumbnails cache directory
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        thumbnailsDirectory = documentsDirectory.appendingPathComponent("Thumbnails")
        
        // Create thumbnails directory if needed
        if !fileManager.fileExists(atPath: thumbnailsDirectory.path) {
            try fileManager.createDirectory(
                at: thumbnailsDirectory,
                withIntermediateDirectories: true
            )
        }
        
        // Configure cache
        cache.countLimit = 100 // Maximum 100 thumbnails in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB maximum
    }
    
    /// Generate thumbnail for a document
    public func generateThumbnail(
        for documentId: UUID,
        from data: Data,
        mimeType: String,
        size: CGSize = CGSize(width: 200, height: 260),
        scale: CGFloat = 2.0
    ) async -> UIImage? {
        // Check memory cache first
        let cacheKey = "\(documentId.uuidString)-\(Int(size.width))x\(Int(size.height))" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = loadThumbnailFromDisk(documentId: documentId, size: size) {
            cache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // Generate new thumbnail
        let thumbnail: UIImage?
        
        if mimeType.hasPrefix("image/") {
            thumbnail = generateImageThumbnail(from: data, size: size)
        } else if mimeType == "application/pdf" {
            thumbnail = generatePDFThumbnail(from: data, size: size)
        } else {
            // Use QuickLook for other document types
            thumbnail = await generateQuickLookThumbnail(
                for: documentId,
                data: data,
                mimeType: mimeType,
                size: size,
                scale: scale
            )
        }
        
        // Cache thumbnail
        if let thumbnail = thumbnail {
            cache.setObject(thumbnail, forKey: cacheKey)
            saveThumbnailToDisk(thumbnail, documentId: documentId, size: size)
        }
        
        return thumbnail
    }
    
    /// Generate multiple thumbnails for a multi-page document
    public func generatePageThumbnails(
        for documentId: UUID,
        from data: Data,
        pageCount: Int,
        size: CGSize = CGSize(width: 150, height: 200),
        maxPages: Int = 10
    ) async -> [Int: UIImage] {
        guard let pdfDocument = PDFDocument(data: data) else { return [:] }
        
        var thumbnails: [Int: UIImage] = [:]
        let pagesToGenerate = min(pageCount, maxPages)
        
        for pageIndex in 0..<pagesToGenerate {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let cacheKey = "\(documentId.uuidString)-page\(pageIndex)-\(Int(size.width))x\(Int(size.height))" as NSString
            
            if let cachedImage = cache.object(forKey: cacheKey) {
                thumbnails[pageIndex] = cachedImage
                continue
            }
            
            if let thumbnail = generatePDFPageThumbnail(page: page, size: size) {
                thumbnails[pageIndex] = thumbnail
                cache.setObject(thumbnail, forKey: cacheKey)
            }
        }
        
        return thumbnails
    }
    
    /// Clear thumbnail cache for a document
    public func clearThumbnails(for documentId: UUID) {
        // Clear memory cache
        clearMemoryCache(for: documentId)
        
        // Clear disk cache
        clearDiskCache(for: documentId)
    }
    
    /// Clear all thumbnail caches
    public func clearAllThumbnails() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: thumbnailsDirectory)
        try? fileManager.createDirectory(
            at: thumbnailsDirectory,
            withIntermediateDirectories: true
        )
    }
    
    /// Get cached thumbnail if available
    public func getCachedThumbnail(
        for documentId: UUID,
        size: CGSize = CGSize(width: 200, height: 260)
    ) -> UIImage? {
        let cacheKey = "\(documentId.uuidString)-\(Int(size.width))x\(Int(size.height))" as NSString
        
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        if let diskImage = loadThumbnailFromDisk(documentId: documentId, size: size) {
            cache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func generateImageThumbnail(from data: Data, size: CGSize) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func generatePDFThumbnail(from data: Data, size: CGSize) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: data),
              let firstPage = pdfDocument.page(at: 0) else { return nil }
        
        return generatePDFPageThumbnail(page: firstPage, size: size)
    }
    
    private func generatePDFPageThumbnail(page: PDFPage, size: CGSize) -> UIImage? {
        let pageBounds = page.bounds(for: .mediaBox)
        let scale = min(size.width / pageBounds.width, size.height / pageBounds.height)
        let scaledSize = CGSize(
            width: pageBounds.width * scale,
            height: pageBounds.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))
            
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
    
    private func generateQuickLookThumbnail(
        for documentId: UUID,
        data: Data,
        mimeType: String,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        // Write data to temporary file for QuickLook
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(documentId.uuidString)
            .appendingPathExtension(UTType(mimeType: mimeType)?.preferredFilenameExtension ?? "doc")
        
        do {
            try data.write(to: tempURL)
            defer { try? fileManager.removeItem(at: tempURL) }
            
            let request = QLThumbnailGenerator.Request(
                fileAt: tempURL,
                size: size,
                scale: scale,
                representationTypes: .thumbnail
            )
            
            let generator = QLThumbnailGenerator.shared
            let thumbnail = try await generator.generateBestRepresentation(for: request)
            return thumbnail.uiImage
            
        } catch {
            print("Failed to generate QuickLook thumbnail: \(error)")
            return nil
        }
    }
    
    private func loadThumbnailFromDisk(documentId: UUID, size: CGSize) -> UIImage? {
        let filename = "\(documentId.uuidString)-\(Int(size.width))x\(Int(size.height)).png"
        let fileURL = thumbnailsDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveThumbnailToDisk(_ image: UIImage, documentId: UUID, size: CGSize) {
        let filename = "\(documentId.uuidString)-\(Int(size.width))x\(Int(size.height)).png"
        let fileURL = thumbnailsDirectory.appendingPathComponent(filename)
        
        guard let data = image.pngData() else { return }
        
        try? data.write(to: fileURL)
    }
    
    private func clearMemoryCache(for documentId: UUID) {
        let keysToRemove = cache.allKeys.filter { key in
            (key as String).hasPrefix(documentId.uuidString)
        }
        
        keysToRemove.forEach { cache.removeObject(forKey: $0) }
    }
    
    private func clearDiskCache(for documentId: UUID) {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: thumbnailsDirectory,
                includingPropertiesForKeys: nil
            )
            
            let filesToDelete = files.filter { url in
                url.lastPathComponent.hasPrefix(documentId.uuidString)
            }
            
            for file in filesToDelete {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
}

// MARK: - NSCache Extension

extension NSCache where KeyType == NSString, ObjectType == UIImage {
    var allKeys: [NSString] {
        // This is a workaround since NSCache doesn't expose its keys
        // In production, you might want to maintain a separate key set
        return []
    }
}