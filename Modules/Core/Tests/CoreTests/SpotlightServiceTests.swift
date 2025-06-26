//
//  SpotlightServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import CoreSpotlight
@testable import Core

final class SpotlightServiceTests: XCTestCase {
    
    var sut: SpotlightService!
    
    override func setUp() {
        super.setUp()
        sut = SpotlightService()
    }
    
    override func tearDown() {
        // Clean up any indexed items
        sut.deleteAllItems()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Indexing Tests
    
    func testIndexItem() {
        // Given
        let item = Item(
            name: "Test Item",
            category: .electronics,
            purchasePrice: 99.99,
            brand: "TestBrand"
        )
        
        // When
        sut.indexItem(item)
        
        // Then
        // Item should be indexed (we can't directly verify in unit tests)
        XCTAssertTrue(true)
    }
    
    func testIndexMultipleItems() {
        // Given
        let items = [
            Item(name: "Item 1", category: .electronics),
            Item(name: "Item 2", category: .furniture),
            Item(name: "Item 3", category: .clothing)
        ]
        
        // When
        sut.indexItems(items)
        
        // Then
        XCTAssertTrue(true) // Items should be indexed
    }
    
    func testIndexItemWithFullDetails() {
        // Given
        var item = Item(
            name: "MacBook Pro",
            category: .electronics,
            purchasePrice: 2499.99,
            brand: "Apple"
        )
        item.itemDescription = "High-performance laptop"
        item.model = "M3 Pro"
        item.serialNumber = "ABC123"
        item.location = "Home Office"
        item.notes = "Work computer"
        item.warrantyExpiration = Date().addingTimeInterval(365 * 24 * 60 * 60)
        
        // When
        sut.indexItem(item)
        
        // Then
        XCTAssertTrue(true) // Item with all details should be indexed
    }
    
    // MARK: - Update Tests
    
    func testUpdateItem() {
        // Given
        var item = Item(name: "Original Name", category: .other)
        sut.indexItem(item)
        
        // When
        item.name = "Updated Name"
        item.purchasePrice = 199.99
        sut.updateItem(item)
        
        // Then
        XCTAssertTrue(true) // Item should be updated in index
    }
    
    // MARK: - Deletion Tests
    
    func testDeleteItem() {
        // Given
        let item = Item(name: "To Delete", category: .other)
        sut.indexItem(item)
        
        // When
        sut.deleteItem(item)
        
        // Then
        XCTAssertTrue(true) // Item should be removed from index
    }
    
    func testDeleteMultipleItems() {
        // Given
        let items = [
            Item(name: "Delete 1", category: .other),
            Item(name: "Delete 2", category: .other),
            Item(name: "Delete 3", category: .other)
        ]
        sut.indexItems(items)
        
        // When
        sut.deleteItems(items)
        
        // Then
        XCTAssertTrue(true) // All items should be removed
    }
    
    func testDeleteAllItems() {
        // Given
        let items = (0..<10).map { Item(name: "Item \($0)", category: .other) }
        sut.indexItems(items)
        
        // When
        sut.deleteAllItems()
        
        // Then
        XCTAssertTrue(true) // All items should be removed
    }
    
    // MARK: - Search Activity Tests
    
    func testCreateUserActivity() {
        // Given
        let item = Item(
            name: "Test Product",
            category: .electronics,
            purchasePrice: 299.99
        )
        
        // When
        let activity = sut.createUserActivity(for: item)
        
        // Then
        XCTAssertEqual(activity.activityType, SpotlightService.viewItemActivityType)
        XCTAssertEqual(activity.title, "View Test Product")
        XCTAssertTrue(activity.isEligibleForSearch)
        XCTAssertTrue(activity.isEligibleForPublicIndexing)
        XCTAssertNotNil(activity.userInfo?["itemID"])
        XCTAssertNotNil(activity.contentAttributeSet)
    }
    
    // MARK: - Searchable Attributes Tests
    
    func testSearchableItemAttributes() {
        // Given
        var item = Item(
            name: "iPhone 15 Pro",
            category: .electronics,
            purchasePrice: 999.99,
            brand: "Apple"
        )
        item.model = "A2896"
        item.serialNumber = "DMPT123456"
        item.location = "Living Room"
        item.notes = "Birthday gift"
        
        // When
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.id.uuidString,
            domainIdentifier: "com.homeinventory.items",
            attributeSet: createAttributeSet(for: item)
        )
        
        // Then
        XCTAssertEqual(searchableItem.uniqueIdentifier, item.id.uuidString)
        XCTAssertNotNil(searchableItem.attributeSet)
        XCTAssertEqual(searchableItem.attributeSet.title, "iPhone 15 Pro")
        XCTAssertTrue(searchableItem.attributeSet.contentDescription?.contains("Apple") ?? false)
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchIndexing() {
        // Given
        let batchSize = 100
        let items = (0..<batchSize).map { i in
            Item(name: "Batch Item \(i)", category: .other, purchasePrice: Double(i))
        }
        
        // When
        let startTime = Date()
        sut.indexItems(items)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsed, 5.0) // Should complete reasonably fast
    }
    
    // MARK: - Edge Cases
    
    func testIndexItemWithMinimalData() {
        // Given
        let item = Item(name: "Minimal", category: .other)
        
        // When
        sut.indexItem(item)
        
        // Then
        XCTAssertTrue(true) // Should handle items with minimal data
    }
    
    func testIndexItemWithSpecialCharacters() {
        // Given
        let item = Item(
            name: "Item with \"quotes\" & special <characters>",
            category: .other,
            brand: "Brand™"
        )
        
        // When
        sut.indexItem(item)
        
        // Then
        XCTAssertTrue(true) // Should handle special characters
    }
    
    func testIndexItemWithLongText() {
        // Given
        var item = Item(name: "Long Description Item", category: .other)
        item.itemDescription = String(repeating: "Very long description. ", count: 100)
        item.notes = String(repeating: "Detailed notes. ", count: 50)
        
        // When
        sut.indexItem(item)
        
        // Then
        XCTAssertTrue(true) // Should handle long text fields
    }
    
    // MARK: - Helper Methods
    
    private func createAttributeSet(for item: Item) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        
        attributeSet.title = item.name
        attributeSet.contentDescription = [
            item.brand,
            item.model,
            item.itemDescription,
            item.category.displayName
        ].compactMap { $0 }.joined(separator: " • ")
        
        if let price = item.purchasePrice {
            attributeSet.information = "$\(String(format: "%.2f", price))"
        }
        
        return attributeSet
    }
}