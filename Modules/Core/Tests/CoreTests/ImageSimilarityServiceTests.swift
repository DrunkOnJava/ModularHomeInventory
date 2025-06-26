//
//  ImageSimilarityServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core
import UIKit
import Vision

final class ImageSimilarityServiceTests: XCTestCase {
    
    var sut: ImageSimilarityService!
    
    override func setUp() {
        super.setUp()
        sut = ImageSimilarityService()
    }
    
    override func tearDown() {
        sut.clearCache()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isProcessing)
        XCTAssertEqual(sut.progress, 0.0)
    }
    
    // MARK: - Feature Extraction Tests
    
    func testExtractFeaturesFromValidImage() async throws {
        // Given
        let image = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        let id = UUID()
        
        // When
        let features = try await sut.extractFeatures(from: image, id: id)
        
        // Then
        XCTAssertEqual(features.id, id)
        XCTAssertFalse(features.dominantColors.isEmpty)
        XCTAssertNotNil(features.featurePrint)
    }
    
    func testExtractFeaturesCache() async throws {
        // Given
        let image = createTestImage(color: .blue, size: CGSize(width: 100, height: 100))
        let id = UUID()
        
        // When - First extraction
        let features1 = try await sut.extractFeatures(from: image, id: id)
        
        // When - Second extraction (should use cache)
        let startTime = Date()
        let features2 = try await sut.extractFeatures(from: image, id: id)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(features1.id, features2.id)
        XCTAssertLessThan(elapsed, 0.1) // Cache should be much faster
    }
    
    // MARK: - Similarity Search Tests
    
    func testFindSimilarItemsWithEmptyList() async throws {
        // Given
        let queryImage = createTestImage(color: .green, size: CGSize(width: 100, height: 100))
        let items: [(id: UUID, image: UIImage)] = []
        
        // When
        let results = try await sut.findSimilarItems(to: queryImage, in: items)
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    func testFindSimilarItemsProgressTracking() async throws {
        // Given
        let queryImage = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        let items = createTestItemImages(count: 5)
        
        var progressUpdates: [Double] = []
        let progressExpectation = expectation(description: "Progress updates")
        progressExpectation.expectedFulfillmentCount = 3 // Expect at least 3 updates
        
        // Observe progress
        let cancellable = sut.$progress.sink { progress in
            if progress > 0 && progress <= 1.0 {
                progressUpdates.append(progress)
                progressExpectation.fulfill()
            }
        }
        
        // When
        _ = try await sut.findSimilarItems(to: queryImage, in: items)
        
        // Then
        await fulfillment(of: [progressExpectation], timeout: 5.0)
        XCTAssertFalse(progressUpdates.isEmpty)
        XCTAssertTrue(progressUpdates.allSatisfy { $0 >= 0 && $0 <= 1.0 })
        
        cancellable.cancel()
    }
    
    func testFindSimilarItemsThreshold() async throws {
        // Given
        let queryImage = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        let items = [
            (id: UUID(), image: createTestImage(color: .red, size: CGSize(width: 100, height: 100))),
            (id: UUID(), image: createTestImage(color: .blue, size: CGSize(width: 100, height: 100)))
        ]
        
        // When - High threshold
        let highThresholdResults = try await sut.findSimilarItems(
            to: queryImage,
            in: items,
            threshold: 0.9
        )
        
        // When - Low threshold
        let lowThresholdResults = try await sut.findSimilarItems(
            to: queryImage,
            in: items,
            threshold: 0.1
        )
        
        // Then
        XCTAssertLessThanOrEqual(highThresholdResults.count, lowThresholdResults.count)
    }
    
    // MARK: - Cache Management Tests
    
    func testClearCache() async throws {
        // Given
        let image = createTestImage(color: .yellow, size: CGSize(width: 100, height: 100))
        let id = UUID()
        
        // Cache some features
        _ = try await sut.extractFeatures(from: image, id: id)
        
        // When
        sut.clearCache()
        
        // Then - Next extraction should not use cache
        let startTime = Date()
        _ = try await sut.extractFeatures(from: image, id: id)
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertGreaterThan(elapsed, 0.01) // Should take time to process
    }
    
    // MARK: - Error Handling Tests
    
    func testImageSimilarityErrorDescriptions() {
        let errors: [ImageSimilarityService.ImageSimilarityError] = [
            .imageProcessingFailed,
            .featureExtractionFailed,
            .noFeaturesFound,
            .comparisonFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    private func createTestItemImages(count: Int) -> [(id: UUID, image: UIImage)] {
        let colors: [UIColor] = [.red, .blue, .green, .yellow, .purple, .orange]
        
        return (0..<count).map { index in
            let color = colors[index % colors.count]
            let image = createTestImage(color: color, size: CGSize(width: 100, height: 100))
            return (id: UUID(), image: image)
        }
    }
}