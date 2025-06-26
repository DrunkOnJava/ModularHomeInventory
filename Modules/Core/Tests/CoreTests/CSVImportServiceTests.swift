//
//  CSVImportServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class CSVImportServiceTests: XCTestCase {
    
    var sut: CSVImportService!
    
    override func setUp() {
        super.setUp()
        sut = CSVImportService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - CSV Parsing Tests
    
    func testParseValidCSV() throws {
        // Given
        let csv = """
        Name,Price,Category,Description
        iPhone 15,999.99,Electronics,"Latest smartphone"
        Coffee Maker,79.99,Appliances,"Morning essential"
        """
        
        // When
        let result = try sut.parseCSV(csv)
        
        // Then
        XCTAssertEqual(result.headers, ["Name", "Price", "Category", "Description"])
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["iPhone 15", "999.99", "Electronics", "Latest smartphone"])
        XCTAssertEqual(result.rows[1], ["Coffee Maker", "79.99", "Appliances", "Morning essential"])
    }
    
    func testParseCSVWithEmptyFields() throws {
        // Given
        let csv = """
        Name,Price,Category
        Item1,,Electronics
        ,29.99,
        Item3,39.99,Home
        """
        
        // When
        let result = try sut.parseCSV(csv)
        
        // Then
        XCTAssertEqual(result.rows.count, 3)
        XCTAssertEqual(result.rows[0], ["Item1", "", "Electronics"])
        XCTAssertEqual(result.rows[1], ["", "29.99", ""])
        XCTAssertEqual(result.rows[2], ["Item3", "39.99", "Home"])
    }
    
    func testParseCSVWithQuotedFields() throws {
        // Given
        let csv = """
        Name,Description
        "Laptop, Pro","High-end computer with 16GB RAM"
        "TV 55""","Large screen television"
        """
        
        // When
        let result = try sut.parseCSV(csv)
        
        // Then
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["Laptop, Pro", "High-end computer with 16GB RAM"])
        XCTAssertEqual(result.rows[1], ["TV 55\"", "Large screen television"])
    }
    
    func testParseEmptyCSV() {
        // Given
        let csv = ""
        
        // When/Then
        XCTAssertThrowsError(try sut.parseCSV(csv)) { error in
            XCTAssertEqual(error as? CSVImportService.ImportError, .emptyFile)
        }
    }
    
    func testParseCSVWithOnlyHeaders() throws {
        // Given
        let csv = "Name,Price,Category"
        
        // When
        let result = try sut.parseCSV(csv)
        
        // Then
        XCTAssertEqual(result.headers, ["Name", "Price", "Category"])
        XCTAssertTrue(result.rows.isEmpty)
    }
    
    // MARK: - Import Tests
    
    func testImportWithValidMappings() async throws {
        // Given
        let data = CSVImportService.ParsedCSVData(
            headers: ["Item Name", "Cost", "Type"],
            rows: [
                ["Book", "19.99", "Media"],
                ["Pen", "2.99", "Office"]
            ]
        )
        
        let mappings: [String: String] = [
            "name": "Item Name",
            "purchasePrice": "Cost",
            "category": "Type"
        ]
        
        // When
        let results = try await sut.importItems(from: data, mappings: mappings)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].item.name, "Book")
        XCTAssertEqual(results[0].item.purchasePrice, 19.99)
        XCTAssertEqual(results[0].item.category, .other)
        XCTAssertTrue(results[0].warnings.isEmpty)
        
        XCTAssertEqual(results[1].item.name, "Pen")
        XCTAssertEqual(results[1].item.purchasePrice, 2.99)
    }
    
    func testImportWithInvalidPriceFormat() async throws {
        // Given
        let data = CSVImportService.ParsedCSVData(
            headers: ["Name", "Price"],
            rows: [
                ["Item1", "invalid"],
                ["Item2", "$29.99"]
            ]
        )
        
        let mappings: [String: String] = [
            "name": "Name",
            "purchasePrice": "Price"
        ]
        
        // When
        let results = try await sut.importItems(from: data, mappings: mappings)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertFalse(results[0].warnings.isEmpty)
        XCTAssertTrue(results[0].warnings.contains { $0.contains("price format") })
        XCTAssertEqual(results[1].item.purchasePrice, 29.99)
    }
    
    func testImportWithCategoryMapping() async throws {
        // Given
        let data = CSVImportService.ParsedCSVData(
            headers: ["Name", "Category"],
            rows: [
                ["Laptop", "Electronics"],
                ["Shirt", "Clothing"],
                ["Unknown", "InvalidCategory"]
            ]
        )
        
        let mappings: [String: String] = [
            "name": "Name",
            "category": "Category"
        ]
        
        // When
        let results = try await sut.importItems(from: data, mappings: mappings)
        
        // Then
        XCTAssertEqual(results[0].item.category, .electronics)
        XCTAssertEqual(results[1].item.category, .clothing)
        XCTAssertEqual(results[2].item.category, .other)
        XCTAssertFalse(results[2].warnings.isEmpty)
    }
    
    func testImportWithDateParsing() async throws {
        // Given
        let data = CSVImportService.ParsedCSVData(
            headers: ["Name", "Purchase Date"],
            rows: [
                ["Item1", "2024-01-15"],
                ["Item2", "01/15/2024"],
                ["Item3", "invalid date"]
            ]
        )
        
        let mappings: [String: String] = [
            "name": "Name",
            "purchaseDate": "Purchase Date"
        ]
        
        // When
        let results = try await sut.importItems(from: data, mappings: mappings)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[0].item.purchaseDate)
        XCTAssertNotNil(results[1].item.purchaseDate)
        XCTAssertNil(results[2].item.purchaseDate)
        XCTAssertFalse(results[2].warnings.isEmpty)
    }
    
    // MARK: - Validation Tests
    
    func testValidateMappingsWithMissingRequired() {
        // Given
        let headers = ["Description", "Price"]
        let mappings: [String: String] = [
            "description": "Description",
            "purchasePrice": "Price"
        ]
        
        // When
        let errors = sut.validateMappings(mappings, headers: headers)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.contains("name") })
    }
    
    func testValidateMappingsWithInvalidColumn() {
        // Given
        let headers = ["Name", "Price"]
        let mappings: [String: String] = [
            "name": "Name",
            "purchasePrice": "Cost" // Column doesn't exist
        ]
        
        // When
        let errors = sut.validateMappings(mappings, headers: headers)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.contains("Cost") })
    }
    
    // MARK: - Error Tests
    
    func testImportErrorDescriptions() {
        let errors: [CSVImportService.ImportError] = [
            .emptyFile,
            .invalidFormat,
            .missingRequiredColumn("name"),
            .parsingError("Test error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}