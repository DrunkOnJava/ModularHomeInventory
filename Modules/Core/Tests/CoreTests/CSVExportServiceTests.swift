//
//  CSVExportServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class CSVExportServiceTests: XCTestCase {
    
    var sut: CSVExportService!
    
    override func setUp() {
        super.setUp()
        sut = CSVExportService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Export Tests
    
    func testExportBasicItems() async throws {
        // Given
        let items = [
            Item(
                name: "MacBook Pro",
                category: .electronics,
                purchasePrice: 2499.99,
                brand: "Apple"
            ),
            Item(
                name: "Office Chair",
                category: .furniture,
                purchasePrice: 399.99,
                brand: "Herman Miller"
            )
        ]
        
        let fields = CSVExportService.defaultFields()
        
        // When
        let csv = try await sut.exportItems(items, fields: fields)
        
        // Then
        XCTAssertTrue(csv.contains("Name,Category,Brand,Purchase Price"))
        XCTAssertTrue(csv.contains("MacBook Pro,Electronics,Apple,2499.99"))
        XCTAssertTrue(csv.contains("Office Chair,Furniture,Herman Miller,399.99"))
    }
    
    func testExportWithSelectedFields() async throws {
        // Given
        var item = Item(
            name: "iPhone",
            category: .electronics,
            purchasePrice: 999.99,
            purchaseDate: Date(timeIntervalSince1970: 1704067200) // 2024-01-01
        )
        item.serialNumber = "ABC123"
        item.notes = "Test notes"
        
        let fields: [CSVExportService.ExportField] = [
            .name,
            .serialNumber,
            .purchaseDate,
            .notes
        ]
        
        // When
        let csv = try await sut.exportItems([item], fields: fields)
        
        // Then
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines[0], "Name,Serial Number,Purchase Date,Notes")
        XCTAssertTrue(lines[1].contains("iPhone"))
        XCTAssertTrue(lines[1].contains("ABC123"))
        XCTAssertTrue(lines[1].contains("2024-01-01"))
        XCTAssertTrue(lines[1].contains("Test notes"))
    }
    
    func testExportWithEmptyFields() async throws {
        // Given
        let item = Item(
            name: "Mystery Item",
            category: .other,
            purchasePrice: nil,
            brand: nil
        )
        
        let fields: [CSVExportService.ExportField] = [
            .name,
            .brand,
            .purchasePrice,
            .warrantyExpiration
        ]
        
        // When
        let csv = try await sut.exportItems([item], fields: fields)
        
        // Then
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 2) // Header + 1 item
        XCTAssertTrue(lines[1].contains("Mystery Item,,"))
    }
    
    func testExportWithSpecialCharacters() async throws {
        // Given
        var item = Item(
            name: "Item with \"quotes\"",
            category: .other,
            purchasePrice: 29.99
        )
        item.notes = "Line 1\nLine 2"
        item.location = "Room, with comma"
        
        let fields: [CSVExportService.ExportField] = [
            .name,
            .location,
            .notes
        ]
        
        // When
        let csv = try await sut.exportItems([item], fields: fields)
        
        // Then
        XCTAssertTrue(csv.contains("\"Item with \"\"quotes\"\"\""))
        XCTAssertTrue(csv.contains("\"Room, with comma\""))
        XCTAssertTrue(csv.contains("\"Line 1\nLine 2\""))
    }
    
    func testExportEmptyItemsList() async throws {
        // Given
        let items: [Item] = []
        let fields = CSVExportService.defaultFields()
        
        // When
        let csv = try await sut.exportItems(items, fields: fields)
        
        // Then
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 1) // Only header
        XCTAssertTrue(csv.contains("Name,Category,Brand,Purchase Price"))
    }
    
    func testExportWithWarrantyInfo() async throws {
        // Given
        var item = Item(
            name: "Appliance",
            category: .appliances,
            purchasePrice: 599.99
        )
        item.warrantyExpiration = Date(timeIntervalSince1970: 1735689600) // 2025-01-01
        item.warrantyProvider = "Manufacturer"
        
        let fields: [CSVExportService.ExportField] = [
            .name,
            .warrantyExpiration,
            .warrantyProvider
        ]
        
        // When
        let csv = try await sut.exportItems([item], fields: fields)
        
        // Then
        let lines = csv.split(separator: "\n")
        XCTAssertTrue(lines[0].contains("Warranty Expiration"))
        XCTAssertTrue(lines[0].contains("Warranty Provider"))
        XCTAssertTrue(lines[1].contains("2025-01-01"))
        XCTAssertTrue(lines[1].contains("Manufacturer"))
    }
    
    // MARK: - Field Tests
    
    func testDefaultFields() {
        // When
        let fields = CSVExportService.defaultFields()
        
        // Then
        XCTAssertTrue(fields.contains(.name))
        XCTAssertTrue(fields.contains(.category))
        XCTAssertTrue(fields.contains(.brand))
        XCTAssertTrue(fields.contains(.purchasePrice))
        XCTAssertFalse(fields.contains(.id)) // ID should not be in default export
    }
    
    func testAllFields() {
        // When
        let allFields = CSVExportService.allFields()
        
        // Then
        XCTAssertTrue(allFields.contains(.name))
        XCTAssertTrue(allFields.contains(.description))
        XCTAssertTrue(allFields.contains(.category))
        XCTAssertTrue(allFields.contains(.brand))
        XCTAssertTrue(allFields.contains(.model))
        XCTAssertTrue(allFields.contains(.serialNumber))
        XCTAssertTrue(allFields.contains(.purchasePrice))
        XCTAssertTrue(allFields.contains(.purchaseDate))
        XCTAssertTrue(allFields.contains(.purchaseStore))
        XCTAssertTrue(allFields.contains(.quantity))
        XCTAssertTrue(allFields.contains(.location))
        XCTAssertTrue(allFields.contains(.warrantyExpiration))
        XCTAssertTrue(allFields.contains(.notes))
    }
    
    func testFieldDisplayNames() {
        // Test that all fields have proper display names
        for field in CSVExportService.allFields() {
            XCTAssertFalse(field.displayName.isEmpty)
            XCTAssertFalse(field.key.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testExportLargeDataset() async throws {
        // Given - Generate 1000 items
        let items = (0..<1000).map { index in
            Item(
                name: "Item \(index)",
                category: .other,
                purchasePrice: Double(index),
                brand: "Brand \(index % 10)"
            )
        }
        
        let fields = CSVExportService.defaultFields()
        
        // When
        let startTime = Date()
        let csv = try await sut.exportItems(items, fields: fields)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsed, 1.0) // Should complete in under 1 second
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 1001) // Header + 1000 items
    }
    
    // MARK: - Error Handling Tests
    
    func testExportWithInvalidDate() async throws {
        // Given
        var item = Item(
            name: "Test Item",
            category: .other
        )
        // Force an invalid date scenario
        item.purchaseDate = Date(timeIntervalSince1970: -1)
        
        let fields: [CSVExportService.ExportField] = [
            .name,
            .purchaseDate
        ]
        
        // When
        let csv = try await sut.exportItems([item], fields: fields)
        
        // Then - Should handle gracefully
        XCTAssertTrue(csv.contains("Test Item"))
    }
}