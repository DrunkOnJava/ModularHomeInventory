//
//  FuzzySearchServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class FuzzySearchServiceTests: XCTestCase {
    
    var sut: FuzzySearchService!
    
    override func setUp() {
        super.setUp()
        sut = FuzzySearchService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Fuzzy Match Tests
    
    func testExactMatch() {
        // When
        let score = sut.fuzzyMatch("iPhone", in: "iPhone")
        
        // Then
        XCTAssertEqual(score, 1.0)
    }
    
    func testCaseInsensitiveMatch() {
        // When
        let score1 = sut.fuzzyMatch("iphone", in: "iPhone")
        let score2 = sut.fuzzyMatch("IPHONE", in: "iPhone")
        let score3 = sut.fuzzyMatch("IpHoNe", in: "iPhone")
        
        // Then
        XCTAssertEqual(score1, 1.0)
        XCTAssertEqual(score2, 1.0)
        XCTAssertEqual(score3, 1.0)
    }
    
    func testPartialMatch() {
        // When
        let score = sut.fuzzyMatch("Mac", in: "MacBook Pro")
        
        // Then
        XCTAssertGreaterThan(score, 0.5)
        XCTAssertLessThan(score, 1.0)
    }
    
    func testTypoTolerance() {
        // When
        let score1 = sut.fuzzyMatch("iPone", in: "iPhone") // One typo
        let score2 = sut.fuzzyMatch("McBook", in: "MacBook") // One typo
        let score3 = sut.fuzzyMatch("Cofee", in: "Coffee") // One typo
        
        // Then
        XCTAssertGreaterThan(score1, 0.7)
        XCTAssertGreaterThan(score2, 0.7)
        XCTAssertGreaterThan(score3, 0.7)
    }
    
    func testNoMatch() {
        // When
        let score = sut.fuzzyMatch("xyz", in: "iPhone")
        
        // Then
        XCTAssertLessThan(score, 0.3)
    }
    
    func testEmptyQuery() {
        // When
        let score = sut.fuzzyMatch("", in: "iPhone")
        
        // Then
        XCTAssertEqual(score, 0.0)
    }
    
    func testEmptyTarget() {
        // When
        let score = sut.fuzzyMatch("iPhone", in: "")
        
        // Then
        XCTAssertEqual(score, 0.0)
    }
    
    // MARK: - Item Search Tests
    
    func testSearchItems() async {
        // Given
        let items = [
            Item(name: "iPhone 15 Pro", category: .electronics),
            Item(name: "iPad Pro", category: .electronics),
            Item(name: "MacBook Pro", category: .electronics),
            Item(name: "Coffee Maker", category: .appliances),
            Item(name: "Office Chair", category: .furniture)
        ]
        
        // When
        let results = await sut.searchItems(query: "pro", in: items)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.contains { $0.item.name == "iPhone 15 Pro" })
        XCTAssertTrue(results.contains { $0.item.name == "iPad Pro" })
        XCTAssertTrue(results.contains { $0.item.name == "MacBook Pro" })
    }
    
    func testSearchItemsWithThreshold() async {
        // Given
        let items = [
            Item(name: "iPhone", category: .electronics),
            Item(name: "iPod", category: .electronics),
            Item(name: "Android Phone", category: .electronics)
        ]
        
        // When
        let results = await sut.searchItems(query: "iPhn", in: items, threshold: 0.6)
        
        // Then
        XCTAssertTrue(results.contains { $0.item.name == "iPhone" })
        XCTAssertFalse(results.contains { $0.item.name == "Android Phone" })
    }
    
    func testSearchItemsByBrand() async {
        // Given
        let items = [
            Item(name: "Product 1", category: .other, brand: "Apple"),
            Item(name: "Product 2", category: .other, brand: "Samsung"),
            Item(name: "Product 3", category: .other, brand: "Apple Inc.")
        ]
        
        // When
        let results = await sut.searchItems(query: "aple", in: items) // Typo
        
        // Then
        XCTAssertTrue(results.contains { $0.item.brand == "Apple" })
        XCTAssertTrue(results.contains { $0.item.brand == "Apple Inc." })
    }
    
    func testSearchItemsByDescription() async {
        // Given
        var item1 = Item(name: "Item 1", category: .other)
        item1.itemDescription = "High-quality wireless headphones"
        
        var item2 = Item(name: "Item 2", category: .other)
        item2.itemDescription = "Premium wired earbuds"
        
        let items = [item1, item2]
        
        // When
        let results = await sut.searchItems(query: "wirelss", in: items) // Typo
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.item.name, "Item 1")
    }
    
    // MARK: - Scoring Tests
    
    func testScoringOrder() async {
        // Given
        let items = [
            Item(name: "iPhone", category: .electronics),
            Item(name: "iPhone Pro", category: .electronics),
            Item(name: "My iPhone Case", category: .electronics)
        ]
        
        // When
        let results = await sut.searchItems(query: "iPhone", in: items)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].item.name, "iPhone") // Exact match first
        XCTAssertGreaterThan(results[0].score, results[1].score)
        XCTAssertGreaterThan(results[1].score, results[2].score)
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() async {
        // Given - Large dataset
        let items = (0..<1000).map { i in
            Item(name: "Item \(i)", category: .other, brand: "Brand \(i % 10)")
        }
        
        // When
        let startTime = Date()
        let results = await sut.searchItems(query: "Item 50", in: items)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsed, 1.0) // Should complete within 1 second
        XCTAssertFalse(results.isEmpty)
    }
    
    // MARK: - Configuration Tests
    
    func testCustomThreshold() async {
        // Given
        let items = [
            Item(name: "Test", category: .other),
            Item(name: "Testing", category: .other),
            Item(name: "Tester", category: .other)
        ]
        
        // When - High threshold
        let strictResults = await sut.searchItems(query: "Test", in: items, threshold: 0.9)
        
        // When - Low threshold
        let lenientResults = await sut.searchItems(query: "Test", in: items, threshold: 0.5)
        
        // Then
        XCTAssertLessThanOrEqual(strictResults.count, lenientResults.count)
    }
    
    // MARK: - Edge Cases
    
    func testSpecialCharacters() {
        // When
        let score1 = sut.fuzzyMatch("Item (1)", in: "Item (1)")
        let score2 = sut.fuzzyMatch("Item [A]", in: "Item [A]")
        let score3 = sut.fuzzyMatch("Item & Co.", in: "Item & Co.")
        
        // Then
        XCTAssertEqual(score1, 1.0)
        XCTAssertEqual(score2, 1.0)
        XCTAssertEqual(score3, 1.0)
    }
    
    func testUnicodeCharacters() {
        // When
        let score1 = sut.fuzzyMatch("café", in: "cafe")
        let score2 = sut.fuzzyMatch("naïve", in: "naive")
        let score3 = sut.fuzzyMatch("résumé", in: "resume")
        
        // Then
        XCTAssertGreaterThan(score1, 0.8)
        XCTAssertGreaterThan(score2, 0.8)
        XCTAssertGreaterThan(score3, 0.8)
    }
    
    func testLongStrings() {
        // Given
        let longString = "This is a very long product name that contains many words and should still be searchable"
        
        // When
        let score1 = sut.fuzzyMatch("very long product", in: longString)
        let score2 = sut.fuzzyMatch("contains many", in: longString)
        
        // Then
        XCTAssertGreaterThan(score1, 0.5)
        XCTAssertGreaterThan(score2, 0.5)
    }
}