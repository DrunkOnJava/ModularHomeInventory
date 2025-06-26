//
//  ImageSearchViewModel.swift
//  Items Module
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
//  Module: Items
//  Dependencies: Foundation, Core, UIKit
//  Testing: ItemsTests/ImageSearchViewModelTests.swift
//
//  Description: View model for image similarity search
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import Core
import UIKit

/// Search result for image similarity
public struct ImageSearchResult: Identifiable {
    public let id = UUID()
    public let item: Item
    public let similarity: Float
    public let matchedFeatures: [String]
}

/// View model for image search functionality
@MainActor
public class ImageSearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var searchResults: [ImageSearchResult] = []
    @Published public var isSearching = false
    @Published public var searchProgress: Double = 0.0
    @Published public var error: Error?
    @Published public var hasSearched = false
    
    // MARK: - Private Properties
    
    private let itemRepository: any ItemRepository
    private let imageSimilarityService = ImageSimilarityService()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    // MARK: - Public Methods
    
    /// Search for items similar to the provided image
    public func searchSimilarItems(to queryImage: UIImage, threshold: Float = 0.5) async {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Reset state
        searchResults = []
        error = nil
        hasSearched = false
        isSearching = true
        searchProgress = 0.0
        
        searchTask = Task {
            do {
                // Get all items from repository
                let allItems = try await itemRepository.fetchAll()
                
                // Filter items that have images
                let itemsWithImages = allItems.filter { !$0.imageIds.isEmpty }
                
                guard !itemsWithImages.isEmpty else {
                    throw ImageSearchError.noItemsWithImages
                }
                
                // Create image pairs for similarity search
                var itemImagePairs: [(id: UUID, image: UIImage)] = []
                
                for (index, item) in itemsWithImages.enumerated() {
                    // Update progress
                    searchProgress = Double(index) / Double(itemsWithImages.count) * 0.5
                    
                    // For demo purposes, create a placeholder image
                    // In real app, load from image storage
                    if let firstImageId = item.imageIds.first,
                       let image = await loadImage(for: firstImageId) {
                        itemImagePairs.append((id: item.id, image: image))
                    }
                }
                
                // Perform similarity search
                let results = try await imageSimilarityService.findSimilarItems(
                    to: queryImage,
                    in: itemImagePairs,
                    threshold: threshold
                )
                
                // Map results to items
                searchResults = results.compactMap { result in
                    guard let item = itemsWithImages.first(where: { $0.id == result.itemId }) else {
                        return nil
                    }
                    
                    let matchedFeatures = buildMatchedFeatures(
                        similarity: result.similarity,
                        colors: result.dominantColors,
                        categories: result.objectCategories
                    )
                    
                    return ImageSearchResult(
                        item: item,
                        similarity: result.similarity,
                        matchedFeatures: matchedFeatures
                    )
                }
                
                hasSearched = true
                
            } catch {
                self.error = error
                print("Image search error: \(error)")
            }
            
            isSearching = false
            searchProgress = 1.0
        }
    }
    
    /// Clear search results
    public func clearResults() {
        searchResults = []
        hasSearched = false
        error = nil
        searchProgress = 0.0
    }
    
    /// Cancel ongoing search
    public func cancelSearch() {
        searchTask?.cancel()
        isSearching = false
    }
    
    // MARK: - Private Methods
    
    private func loadImage(for imageId: UUID) async -> UIImage? {
        // In a real app, this would load from image storage
        // For demo, return a placeholder image
        return UIImage(systemName: "photo")
    }
    
    private func buildMatchedFeatures(
        similarity: Float,
        colors: [UIColor],
        categories: [String]
    ) -> [String] {
        var features: [String] = []
        
        // Add similarity level
        if similarity > 0.8 {
            features.append("Very similar appearance")
        } else if similarity > 0.6 {
            features.append("Similar appearance")
        }
        
        // Add color info
        if !colors.isEmpty {
            features.append("Matching colors")
        }
        
        // Add category info
        for category in categories.prefix(3) {
            features.append(category.capitalized)
        }
        
        return features
    }
}

// MARK: - Image Search Errors

public enum ImageSearchError: LocalizedError {
    case noItemsWithImages
    case imageLoadingFailed
    case searchFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noItemsWithImages:
            return "No items with images found in your inventory"
        case .imageLoadingFailed:
            return "Failed to load item images"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        }
    }
}