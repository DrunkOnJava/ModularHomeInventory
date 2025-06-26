//
//  ImageSimilarityService.swift
//  Core Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Core
//  Dependencies: Vision, CoreML, UIKit
//  Testing: CoreTests/ImageSimilarityServiceTests.swift
//
//  Description: Service for finding similar images using Vision framework
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Vision
import CoreImage
import UIKit
import SwiftUI

/// Service for image similarity search using Vision framework
public class ImageSimilarityService: ObservableObject {
    
    // MARK: - Types
    
    /// Result of image similarity comparison
    public struct SimilarityResult {
        public let itemId: UUID
        public let similarity: Float
        public let dominantColors: [UIColor]
        public let objectCategories: [String]
    }
    
    /// Image features for comparison
    public struct ImageFeatures {
        public let id: UUID
        public let featurePrint: VNFeaturePrintObservation?
        public let dominantColors: [UIColor]
        public let objectClassifications: [VNClassificationObservation]
        public let faceObservations: [VNFaceObservation]
    }
    
    /// Error types for image similarity
    public enum ImageSimilarityError: LocalizedError {
        case imageProcessingFailed
        case featureExtractionFailed
        case noFeaturesFound
        case comparisonFailed
        
        public var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Failed to process the image"
            case .featureExtractionFailed:
                return "Failed to extract features from the image"
            case .noFeaturesFound:
                return "No features could be extracted from the image"
            case .comparisonFailed:
                return "Failed to compare images"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published public var isProcessing = false
    @Published public var progress: Double = 0.0
    
    private let featurePrintRequest = VNGenerateImageFeaturePrintRequest()
    private let classificationRequest: VNClassifyImageRequest
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    private var imageCache: [UUID: ImageFeatures] = [:]
    private let cacheQueue = DispatchQueue(label: "com.homeinventory.imagesimilarity.cache", attributes: .concurrent)
    
    // MARK: - Initialization
    
    public init() {
        // Initialize classification request
        self.classificationRequest = VNClassifyImageRequest()
    }
    
    // MARK: - Public Methods
    
    /// Extract features from an image
    public func extractFeatures(from image: UIImage, id: UUID) async throws -> ImageFeatures {
        // Check cache first
        if let cached = getCachedFeatures(for: id) {
            return cached
        }
        
        guard let cgImage = image.cgImage else {
            throw ImageSimilarityError.imageProcessingFailed
        }
        
        // Create request handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Extract feature print
        let featurePrint = try await extractFeaturePrint(handler: handler)
        
        // Extract dominant colors
        let dominantColors = extractDominantColors(from: image)
        
        // Extract object classifications
        let classifications = try await extractClassifications(handler: handler)
        
        // Detect faces (if any)
        let faceObservations = try await detectFaces(handler: handler)
        
        let features = ImageFeatures(
            id: id,
            featurePrint: featurePrint,
            dominantColors: dominantColors,
            objectClassifications: classifications,
            faceObservations: faceObservations
        )
        
        // Cache the features
        cacheFeatures(features, for: id)
        
        return features
    }
    
    /// Find similar items based on image
    public func findSimilarItems(
        to queryImage: UIImage,
        in itemImages: [(id: UUID, image: UIImage)],
        threshold: Float = 0.5
    ) async throws -> [SimilarityResult] {
        isProcessing = true
        progress = 0.0
        defer { 
            isProcessing = false
            progress = 1.0
        }
        
        // Extract features from query image
        let queryFeatures = try await extractFeatures(from: queryImage, id: UUID())
        
        guard queryFeatures.featurePrint != nil else {
            throw ImageSimilarityError.noFeaturesFound
        }
        
        var results: [SimilarityResult] = []
        let totalItems = itemImages.count
        
        // Process each item image
        for (index, item) in itemImages.enumerated() {
            // Update progress
            await MainActor.run {
                self.progress = Double(index) / Double(totalItems)
            }
            
            do {
                let itemFeatures = try await extractFeatures(from: item.image, id: item.id)
                
                // Calculate similarity
                let similarity = calculateSimilarity(
                    between: queryFeatures,
                    and: itemFeatures
                )
                
                if similarity >= threshold {
                    let result = SimilarityResult(
                        itemId: item.id,
                        similarity: similarity,
                        dominantColors: itemFeatures.dominantColors,
                        objectCategories: itemFeatures.objectClassifications
                            .prefix(3)
                            .map { $0.identifier }
                    )
                    results.append(result)
                }
            } catch {
                // Skip items that fail processing
                print("Failed to process item \(item.id): \(error)")
            }
        }
        
        // Sort by similarity (highest first)
        results.sort { $0.similarity > $1.similarity }
        
        return results
    }
    
    /// Clear the feature cache
    public func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func extractFeaturePrint(handler: VNImageRequestHandler) async throws -> VNFeaturePrintObservation? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([featurePrintRequest])
                
                if let observation = featurePrintRequest.results?.first as? VNFeaturePrintObservation {
                    continuation.resume(returning: observation)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(throwing: ImageSimilarityError.featureExtractionFailed)
            }
        }
    }
    
    private func extractClassifications(handler: VNImageRequestHandler) async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([classificationRequest])
                
                let observations = classificationRequest.results ?? []
                continuation.resume(returning: observations)
            } catch {
                continuation.resume(throwing: ImageSimilarityError.featureExtractionFailed)
            }
        }
    }
    
    private func detectFaces(handler: VNImageRequestHandler) async throws -> [VNFaceObservation] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([faceDetectionRequest])
                
                let observations = faceDetectionRequest.results ?? []
                continuation.resume(returning: observations)
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    private func extractDominantColors(from image: UIImage, colorCount: Int = 5) -> [UIColor] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = 50
        let height = 50
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Extract colors using k-means clustering
        var colorBuckets: [UIColor: Int] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(rawData[offset]) / 255.0
                let g = CGFloat(rawData[offset + 1]) / 255.0
                let b = CGFloat(rawData[offset + 2]) / 255.0
                
                // Quantize colors to reduce variations
                let quantizedR = round(r * 10) / 10
                let quantizedG = round(g * 10) / 10
                let quantizedB = round(b * 10) / 10
                
                let color = UIColor(red: quantizedR, green: quantizedG, blue: quantizedB, alpha: 1.0)
                colorBuckets[color, default: 0] += 1
            }
        }
        
        // Sort by frequency and take top colors
        let sortedColors = colorBuckets.sorted { $0.value > $1.value }
        return Array(sortedColors.prefix(colorCount).map { $0.key })
    }
    
    private func calculateSimilarity(between features1: ImageFeatures, and features2: ImageFeatures) -> Float {
        var totalScore: Float = 0.0
        var weightSum: Float = 0.0
        
        // Feature print similarity (weight: 0.5)
        if let fp1 = features1.featurePrint,
           let fp2 = features2.featurePrint {
            do {
                var distance = Float(0)
                try fp1.computeDistance(&distance, to: fp2)
                let similarity = 1.0 - min(distance, 1.0)
                totalScore += similarity * 0.5
                weightSum += 0.5
            } catch {
                print("Failed to compute feature print distance: \(error)")
            }
        }
        
        // Color similarity (weight: 0.2)
        let colorSimilarity = calculateColorSimilarity(
            colors1: features1.dominantColors,
            colors2: features2.dominantColors
        )
        totalScore += colorSimilarity * 0.2
        weightSum += 0.2
        
        // Object classification similarity (weight: 0.3)
        let classificationSimilarity = calculateClassificationSimilarity(
            classifications1: features1.objectClassifications,
            classifications2: features2.objectClassifications
        )
        totalScore += classificationSimilarity * 0.3
        weightSum += 0.3
        
        return weightSum > 0 ? totalScore / weightSum : 0
    }
    
    private func calculateColorSimilarity(colors1: [UIColor], colors2: [UIColor]) -> Float {
        guard !colors1.isEmpty && !colors2.isEmpty else { return 0 }
        
        var totalSimilarity: Float = 0
        var comparisons = 0
        
        for color1 in colors1 {
            for color2 in colors2 {
                let similarity = colorDistance(color1, color2)
                totalSimilarity += similarity
                comparisons += 1
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Float(comparisons) : 0
    }
    
    private func colorDistance(_ color1: UIColor, _ color2: UIColor) -> Float {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let dr = Float(r1 - r2)
        let dg = Float(g1 - g2)
        let db = Float(b1 - b2)
        
        let distance = sqrt(dr * dr + dg * dg + db * db)
        return 1.0 - min(distance / sqrt(3), 1.0)
    }
    
    private func calculateClassificationSimilarity(
        classifications1: [VNClassificationObservation],
        classifications2: [VNClassificationObservation]
    ) -> Float {
        let set1 = Set(classifications1.prefix(10).map { $0.identifier })
        let set2 = Set(classifications2.prefix(10).map { $0.identifier })
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return union > 0 ? Float(intersection) / Float(union) : 0
    }
    
    // MARK: - Cache Management
    
    private func getCachedFeatures(for id: UUID) -> ImageFeatures? {
        cacheQueue.sync {
            return imageCache[id]
        }
    }
    
    private func cacheFeatures(_ features: ImageFeatures, for id: UUID) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[id] = features
        }
    }
}