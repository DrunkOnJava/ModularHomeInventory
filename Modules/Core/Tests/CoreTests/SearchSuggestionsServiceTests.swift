//
//  SearchSuggestionsServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class SearchSuggestionsServiceTests: XCTestCase {
    
    var sut: SearchSuggestionsService!
    var mockItems: [Item]!
    
    override func setUp() {
        super.setUp()
        sut = SearchSuggestionsService()
        
        // Create mock items for testing
        mockItems = [
            Item(name: "MacBook Pro", category: .electronics, brand: "Apple"),
            Item(name: "MacBook Air", category: .electronics, brand: "Apple"),
            Item(name: "iPhone 15 Pro", category: .electronics, brand: "Apple"),
            Item(name: "iPad Pro", category: .electronics, brand: "Apple"),
            Item(name: "Office Chair", category: .furniture, brand: "Herman Miller"),
            Item(name: "Standing Desk", category: .furniture, brand: "IKEA"),
            Item(name: "Coffee Maker", category: .appliances, brand: "Breville"),
            Item(name: "Blender", category: .appliances, brand: "Vitamix"),
            Item(name: "Winter Jacket", category: .clothing, brand: "North Face"),
            Item(name: "Running Shoes", category: .clothing, brand: "Nike")
        ]
    }
    
    override func tearDown() {
        sut.clearSearchHistory()
        sut = nil
        mockItems = nil
        super.tearDown()
    }
    
    // MARK: - Suggestion Generation Tests
    
    func testGenerateSuggestionsForPartialMatch() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "mac", items: mockItems)
        
        // Then
        XCTAssertEqual(suggestions.count, 2)
        XCTAssertTrue(suggestions.contains { $0.text == "MacBook Pro" })
        XCTAssertTrue(suggestions.contains { $0.text == "MacBook Air" })
    }
    
    func testGenerateSuggestionsForBrand() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "apple", items: mockItems)
        
        // Then
        XCTAssertEqual(suggestions.count, 4)
        XCTAssertTrue(suggestions.allSatisfy { suggestion in
            mockItems.contains { $0.brand == "Apple" && $0.name == suggestion.text }
        })
    }
    
    func testGenerateSuggestionsForCategory() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "furniture", items: mockItems)
        
        // Then
        XCTAssertEqual(suggestions.count, 2)
        XCTAssertTrue(suggestions.contains { $0.text == "Office Chair" })
        XCTAssertTrue(suggestions.contains { $0.text == "Standing Desk" })
    }
    
    func testGenerateSuggestionsEmpty() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "", items: mockItems)
        
        // Then
        XCTAssertTrue(suggestions.isEmpty || suggestions.count <= 5) // Should return nothing or recent searches
    }
    
    func testGenerateSuggestionsNoMatch() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "xyz123", items: mockItems)
        
        // Then
        XCTAssertTrue(suggestions.isEmpty)
    }
    
    func testGenerateSuggestionsCaseInsensitive() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "MACBOOK", items: mockItems)
        
        // Then
        XCTAssertEqual(suggestions.count, 2)
        XCTAssertTrue(suggestions.contains { $0.text == "MacBook Pro" })
    }
    
    // MARK: - Search History Tests
    
    func testAddToSearchHistory() {
        // When
        sut.addToSearchHistory("iPhone")
        sut.addToSearchHistory("MacBook")
        sut.addToSearchHistory("iPad")
        
        // Then
        let history = sut.getSearchHistory()
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0], "iPad") // Most recent first
        XCTAssertEqual(history[1], "MacBook")
        XCTAssertEqual(history[2], "iPhone")
    }
    
    func testSearchHistoryLimit() {
        // When - Add more than the limit
        for i in 1...25 {
            sut.addToSearchHistory("Search \(i)")
        }
        
        // Then
        let history = sut.getSearchHistory()
        XCTAssertEqual(history.count, 20) // Default limit
        XCTAssertEqual(history[0], "Search 25") // Most recent
        XCTAssertEqual(history[19], "Search 6") // Oldest kept
    }
    
    func testSearchHistoryNoDuplicates() {
        // When
        sut.addToSearchHistory("iPhone")
        sut.addToSearchHistory("MacBook")
        sut.addToSearchHistory("iPhone") // Duplicate
        
        // Then
        let history = sut.getSearchHistory()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0], "iPhone") // Moved to top
        XCTAssertEqual(history[1], "MacBook")
    }
    
    func testClearSearchHistory() {
        // Given
        sut.addToSearchHistory("Test 1")
        sut.addToSearchHistory("Test 2")
        XCTAssertFalse(sut.getSearchHistory().isEmpty)
        
        // When
        sut.clearSearchHistory()
        
        // Then
        XCTAssertTrue(sut.getSearchHistory().isEmpty)
    }
    
    // MARK: - Popular Searches Tests
    
    func testGetPopularSearches() async {
        // Given - Simulate search frequency
        sut.addToSearchHistory("iPhone")
        sut.addToSearchHistory("MacBook")
        sut.addToSearchHistory("iPhone")
        sut.addToSearchHistory("iPad")
        sut.addToSearchHistory("iPhone")
        
        // When
        let popular = await sut.getPopularSearches(items: mockItems)
        
        // Then
        XCTAssertFalse(popular.isEmpty)
        // Should include frequently searched terms
    }
    
    // MARK: - Suggestion Type Tests
    
    func testSuggestionTypes() async {
        // Add search history
        sut.addToSearchHistory("Previous Search")
        
        // When
        let suggestions = await sut.generateSuggestions(for: "pr", items: mockItems)
        
        // Then
        XCTAssertTrue(suggestions.contains { $0.type == .item })
        XCTAssertTrue(suggestions.contains { $0.type == .recent || $0.type == .popular })
    }
    
    // MARK: - Performance Tests
    
    func testSuggestionPerformance() async {
        // Given - Large dataset
        var largeItemSet = mockItems
        for i in 1...1000 {
            largeItemSet.append(Item(name: "Item \(i)", category: .other))
        }
        
        // When
        let startTime = Date()
        let suggestions = await sut.generateSuggestions(for: "Item", items: largeItemSet)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsed, 0.5) // Should be fast
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertLessThanOrEqual(suggestions.count, 10) // Should limit results
    }
    
    // MARK: - Edge Cases
    
    func testSpecialCharacters() async {
        // Given
        let specialItems = [
            Item(name: "Item (Special)", category: .other),
            Item(name: "Item [Bracket]", category: .other),
            Item(name: "Item & More", category: .other)
        ]
        
        // When
        let suggestions1 = await sut.generateSuggestions(for: "(Special)", items: specialItems)
        let suggestions2 = await sut.generateSuggestions(for: "[Bracket]", items: specialItems)
        let suggestions3 = await sut.generateSuggestions(for: "& More", items: specialItems)
        
        // Then
        XCTAssertFalse(suggestions1.isEmpty)
        XCTAssertFalse(suggestions2.isEmpty)
        XCTAssertFalse(suggestions3.isEmpty)
    }
    
    func testEmptyItemsList() async {
        // When
        let suggestions = await sut.generateSuggestions(for: "test", items: [])
        
        // Then
        XCTAssertTrue(suggestions.isEmpty)
    }
}