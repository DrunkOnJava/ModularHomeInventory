//
//  NaturalLanguageSearchViewModel.swift
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
//  Dependencies: SwiftUI, Core, Combine
//  Testing: ItemsTests/NaturalLanguageSearchViewModelTests.swift
//
//  Description: View model for natural language search functionality and query processing
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

// MARK: - View Model
@MainActor
final class NaturalLanguageSearchViewModel: ObservableObject {
    @Published var searchResults: [Item] = []
    @Published var isSearching = false
    @Published var queryInterpretation: QueryInterpretation?
    @Published var searchHistory: [String] = []
    
    let itemRepository: any ItemRepository
    let nlSearchService = NaturalLanguageSearchService()
    let searchHistoryRepository: any SearchHistoryRepository
    let savedSearchRepository: any SavedSearchRepository
    
    init(itemRepository: any ItemRepository, searchHistoryRepository: any SearchHistoryRepository, savedSearchRepository: any SavedSearchRepository) {
        self.itemRepository = itemRepository
        self.searchHistoryRepository = searchHistoryRepository
        self.savedSearchRepository = savedSearchRepository
        loadSearchHistory()
    }
}

// MARK: - Search Methods

extension NaturalLanguageSearchViewModel {
    func performNaturalLanguageSearch(
        _ query: String,
        useFuzzySearch: Bool = false,
        fuzzyThreshold: Double = 0.7
    ) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        // Parse the natural language query
        let nlQuery = nlSearchService.parseQuery(query)
        
        // Update interpretation
        queryInterpretation = buildInterpretation(from: nlQuery)
        
        // Convert to search criteria
        let criteria = nlSearchService.convertToSearchCriteria(nlQuery)
        
        do {
            // Perform the search
            if useFuzzySearch && criteria.searchText != nil {
                // Use fuzzy search for the text portion
                let fuzzyResults = try await itemRepository.fuzzySearch(
                    query: criteria.searchText ?? "",
                    threshold: fuzzyThreshold
                )
                
                // Then apply other filters
                searchResults = fuzzyResults.filter { item in
                    // Apply category filter
                    if !criteria.categories.isEmpty && !criteria.categories.contains(item.category) {
                        return false
                    }
                    
                    // Apply date range filter
                    if let startDate = criteria.purchaseDateStart,
                       let purchaseDate = item.purchaseDate,
                       purchaseDate < startDate {
                        return false
                    }
                    
                    if let endDate = criteria.purchaseDateEnd,
                       let purchaseDate = item.purchaseDate,
                       purchaseDate > endDate {
                        return false
                    }
                    
                    // Apply price range filter
                    if let minPrice = criteria.minPrice,
                       let purchasePrice = item.purchasePrice,
                       purchasePrice < Decimal(minPrice) {
                        return false
                    }
                    
                    if let maxPrice = criteria.maxPrice,
                       let purchasePrice = item.purchasePrice,
                       purchasePrice > Decimal(maxPrice) {
                        return false
                    }
                    
                    return true
                }
            } else {
                searchResults = try await itemRepository.searchWithCriteria(criteria)
            }
            
            // Add to search history
            addToSearchHistory(query)
            
            // Save to persistent search history
            let historyEntry = SearchHistoryEntry(
                query: query,
                searchType: .natural,
                resultCount: searchResults.count
            )
            try? await searchHistoryRepository.save(historyEntry)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
    
    func clearSearch() {
        searchResults = []
        queryInterpretation = nil
    }
    
    func performSavedSearch(_ savedSearch: SavedSearch, useFuzzySearch: Bool = false, fuzzyThreshold: Double = 0.7) async {
        // Record usage
        try? await savedSearchRepository.recordUsage(of: savedSearch)
        
        // Perform the search
        await performNaturalLanguageSearch(savedSearch.query, useFuzzySearch: useFuzzySearch, fuzzyThreshold: fuzzyThreshold)
    }
}

// MARK: - Interpretation Methods

extension NaturalLanguageSearchViewModel {
    private func buildInterpretation(from nlQuery: NaturalLanguageQuery) -> QueryInterpretation {
        var components: [QueryComponent] = []
        
        // Add color components
        for color in nlQuery.colors {
            components.append(QueryComponent(
                type: .color,
                value: color,
                icon: "paintpalette",
                color: "#FF6B6B"
            ))
        }
        
        // Add item components
        for item in nlQuery.items {
            components.append(QueryComponent(
                type: .item,
                value: item,
                icon: "cube.box",
                color: "#4ECDC4"
            ))
        }
        
        // Add location components
        for location in nlQuery.locations {
            components.append(QueryComponent(
                type: .location,
                value: location,
                icon: "location",
                color: "#FFE66D"
            ))
        }
        
        // Add time components
        for timeRef in nlQuery.timeReferences {
            components.append(QueryComponent(
                type: .time,
                value: timeRef,
                icon: "calendar",
                color: "#95E1D3"
            ))
        }
        
        // Add price components
        for priceRange in nlQuery.priceRanges {
            let value: String
            if let min = priceRange.min, let max = priceRange.max {
                value = "$\(Int(min))-$\(Int(max))"
            } else if let min = priceRange.min {
                value = "over $\(Int(min))"
            } else if let max = priceRange.max {
                value = "under $\(Int(max))"
            } else {
                continue
            }
            
            components.append(QueryComponent(
                type: .price,
                value: value,
                icon: "dollarsign.circle",
                color: "#A8E6CF"
            ))
        }
        
        // Add brand components
        for brand in nlQuery.brands {
            components.append(QueryComponent(
                type: .brand,
                value: brand,
                icon: "tag",
                color: "#C7CEEA"
            ))
        }
        
        // Add category components
        for category in nlQuery.categories {
            components.append(QueryComponent(
                type: .category,
                value: category,
                icon: "folder",
                color: "#FFDAB9"
            ))
        }
        
        // Add action components
        for action in nlQuery.actions {
            if action.lowercased().contains("warranty") {
                components.append(QueryComponent(
                    type: .action,
                    value: "under warranty",
                    icon: "shield",
                    color: "#B19CD9"
                ))
            }
        }
        
        return QueryInterpretation(components: components)
    }
}

// MARK: - History Management

extension NaturalLanguageSearchViewModel {
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = history
        }
    }
    
    private func addToSearchHistory(_ query: String) {
        // Remove if already exists
        searchHistory.removeAll { $0 == query }
        
        // Add to beginning
        searchHistory.insert(query, at: 0)
        
        // Keep only last 20
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "searchHistory")
        }
    }
}