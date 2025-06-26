//
//  ImageSearchView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, PhotosUI
//  Testing: ItemsTests/ImageSearchViewTests.swift
//
//  Description: View for searching items by image similarity
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import PhotosUI

/// View for searching items by image similarity
public struct ImageSearchView: View {
    @StateObject private var viewModel: ImageSearchViewModel
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedItem: Item?
    @State private var similarityThreshold: Float = 0.5
    @State private var showingSettings = false
    
    public init(itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: ImageSearchViewModel(itemRepository: itemRepository))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let image = selectedImage {
                    // Selected image view
                    SelectedImageView(
                        image: image,
                        onRemove: {
                            selectedImage = nil
                            viewModel.clearResults()
                        }
                    )
                    
                    // Similarity threshold slider
                    ThresholdSlider(threshold: $similarityThreshold)
                        .padding()
                    
                    // Search button
                    PrimaryButton(title: "Find Similar Items") {
                        Task {
                            await viewModel.searchSimilarItems(
                                to: image,
                                threshold: similarityThreshold
                            )
                        }
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isSearching)
                    
                    if viewModel.isSearching {
                        ProgressView("Searching...")
                            .padding()
                    }
                    
                    // Results
                    if !viewModel.searchResults.isEmpty {
                        ImageSearchResultsList(
                            results: viewModel.searchResults,
                            onSelectItem: { item in
                                selectedItem = item
                            }
                        )
                    } else if viewModel.hasSearched && !viewModel.isSearching {
                        ImageNoResultsView()
                    }
                } else {
                    // Image selection view
                    ImageSelectionView(
                        onSelectImage: { image in
                            selectedImage = image
                        },
                        onShowImagePicker: {
                            showingImagePicker = true
                        },
                        onShowCamera: {
                            showingCamera = true
                        }
                    )
                }
            }
            .navigationTitle("Image Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailSheet(item: item)
            }
            .sheet(isPresented: $showingSettings) {
                ImageSearchSettingsView()
            }
        }
    }
}

// MARK: - Selected Image View

struct SelectedImageView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .black.opacity(0.7))
                }
                .padding(8)
            }
            .padding()
            
            // Image info
            HStack {
                Label("Query Image", systemImage: "photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(image.size.width))×\(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Threshold Slider

struct ThresholdSlider: View {
    @Binding var threshold: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Similarity Threshold")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(threshold * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Less Similar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $threshold, in: 0.3...0.9, step: 0.05)
                    .tint(.blue)
                
                Text("More Similar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Image Selection View

struct ImageSelectionView: View {
    let onSelectImage: (UIImage) -> Void
    let onShowImagePicker: () -> Void
    let onShowCamera: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            // Title
            VStack(spacing: 8) {
                Text("Search by Image")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Find items that look similar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onShowCamera) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onShowImagePicker) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // How it works
            VStack(alignment: .leading, spacing: 12) {
                Label("How it works", systemImage: "info.circle")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint("Uses AI to analyze visual features")
                    BulletPoint("Compares colors, shapes, and objects")
                    BulletPoint("Finds items with similar appearance")
                    BulletPoint("Adjust threshold for better results")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// MARK: - Search Results List

struct ImageSearchResultsList: View {
    let results: [ImageSearchResult]
    let onSelectItem: (Item) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results) { result in
                    SearchResultCard(
                        result: result,
                        onTap: {
                            onSelectItem(result.item)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: ImageSearchResult
    let onTap: () -> Void
    
    var similarityColor: Color {
        if result.similarity > 0.8 {
            return .green
        } else if result.similarity > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Item image
                if let imageData = result.item.imageIds.first,
                   let uiImage = UIImage(data: Data()) { // In real app, load from storage
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let brand = result.item.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        // Similarity badge
                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.caption2)
                            Text("\(Int(result.similarity * 100))% match")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(similarityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(similarityColor.opacity(0.2))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Category
                        Text(result.item.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - No Results View

struct ImageNoResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Similar Items Found")
                .font(.headline)
            
            Text("Try adjusting the similarity threshold or using a different image")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Item Detail Sheet

struct ItemDetailSheet: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            // Simplified item detail view
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let brand = item.brand {
                        Text(brand)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    LabeledContent("Category", value: item.category.rawValue)
                    
                    if let price = item.purchasePrice {
                        LabeledContent("Purchase Price") {
                            Text("$\(price)")
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Location would need to be fetched from locationId
                    if item.locationId != nil {
                        LabeledContent("Location", value: "Location details")
                    }
                    
                    if let notes = item.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings View

struct ImageSearchSettingsView: View {
    @AppStorage("imageSearch.useMLFeatures") private var useMLFeatures = true
    @AppStorage("imageSearch.useColorMatching") private var useColorMatching = true
    @AppStorage("imageSearch.cacheResults") private var cacheResults = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Search Features") {
                    Toggle("Use Machine Learning", isOn: $useMLFeatures)
                    Toggle("Match Colors", isOn: $useColorMatching)
                }
                
                Section("Performance") {
                    Toggle("Cache Search Results", isOn: $cacheResults)
                }
                
                Section {
                    Button("Clear Cache") {
                        // Clear cache action
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("Clearing the cache will remove stored image analysis data")
                }
            }
            .navigationTitle("Image Search Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bullet Point Helper

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}