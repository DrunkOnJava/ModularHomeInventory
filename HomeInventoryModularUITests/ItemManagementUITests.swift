//
//  ItemManagementUITests.swift
//  HomeInventoryModularUITests
//
//  UI Tests for item creation, editing, and deletion flows
//

import XCTest

final class ItemManagementUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["--reset-data"] // Clean state for tests
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Add Item Tests
    
    func testAddItemBasic() throws {
        // Navigate to add item
        XCTAssertTrue(app.navigationBars.buttons["plus"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["plus"].tap()
        
        // Fill in basic details
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test iPhone")
        
        // Select category
        app.buttons["Category"].tap()
        app.buttons["Electronics"].tap()
        
        // Add price
        let priceField = app.textFields["Price"]
        if priceField.exists {
            priceField.tap()
            priceField.typeText("999.99")
        }
        
        // Save item
        app.navigationBars.buttons["Save"].tap()
        
        // Verify item appears in list
        XCTAssertTrue(app.tables.cells.staticTexts["Test iPhone"].waitForExistence(timeout: 3))
    }
    
    func testAddItemWithPhoto() throws {
        // Navigate to add item
        app.navigationBars.buttons["plus"].tap()
        
        // Add photo
        let addPhotoButton = app.buttons["Add Photo"]
        if addPhotoButton.waitForExistence(timeout: 3) {
            addPhotoButton.tap()
            
            // Select from library option
            if app.buttons["Photo Library"].exists {
                app.buttons["Photo Library"].tap()
                
                // In simulator, we can't actually select a photo
                // but we can test the flow
                app.navigationBars.buttons["Cancel"].tap()
            }
        }
        
        // Fill required fields
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("Item with Photo")
        
        // Save
        app.navigationBars.buttons["Save"].tap()
    }
    
    func testAddItemWithAllDetails() throws {
        // Navigate to add item
        app.navigationBars.buttons["plus"].tap()
        
        // Fill all fields
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("MacBook Pro 16-inch")
        
        // Brand
        if let brandField = app.textFields["Brand"] {
            brandField.tap()
            brandField.typeText("Apple")
        }
        
        // Model
        if let modelField = app.textFields["Model"] {
            modelField.tap()
            modelField.typeText("A2991")
        }
        
        // Serial Number
        if let serialField = app.textFields["Serial Number"] {
            serialField.tap()
            serialField.typeText("C02XL1234567")
        }
        
        // Price
        if let priceField = app.textFields["Price"] {
            priceField.tap()
            priceField.typeText("3499.00")
        }
        
        // Category
        app.buttons["Category"].tap()
        app.buttons["Electronics"].tap()
        
        // Location
        if app.buttons["Location"].exists {
            app.buttons["Location"].tap()
            if app.buttons["Home Office"].exists {
                app.buttons["Home Office"].tap()
            } else {
                app.navigationBars.buttons["Cancel"].tap()
            }
        }
        
        // Notes
        if let notesField = app.textViews["Notes"] {
            notesField.tap()
            notesField.typeText("Work laptop with AppleCare+")
        }
        
        // Save
        app.navigationBars.buttons["Save"].tap()
        
        // Verify
        XCTAssertTrue(app.tables.cells.staticTexts["MacBook Pro 16-inch"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Edit Item Tests
    
    func testEditItem() throws {
        // First create an item
        createTestItem(name: "Original Item")
        
        // Tap on the item
        app.tables.cells.staticTexts["Original Item"].tap()
        
        // Tap edit button
        app.navigationBars.buttons["Edit"].tap()
        
        // Change name
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.clearText()
        nameField.typeText("Updated Item")
        
        // Save changes
        app.navigationBars.buttons["Save"].tap()
        
        // Verify update
        XCTAssertTrue(app.navigationBars["Updated Item"].waitForExistence(timeout: 3))
    }
    
    func testEditItemPrice() throws {
        // Create item with price
        createTestItem(name: "Priced Item", price: "100.00")
        
        // Edit item
        app.tables.cells.staticTexts["Priced Item"].tap()
        app.navigationBars.buttons["Edit"].tap()
        
        // Update price
        let priceField = app.textFields["Price"]
        priceField.tap()
        priceField.clearText()
        priceField.typeText("150.00")
        
        // Save
        app.navigationBars.buttons["Save"].tap()
        
        // Verify price updated (would need to check detail view)
        XCTAssertTrue(app.staticTexts["$150.00"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteItemSwipe() throws {
        // Create test item
        createTestItem(name: "Item to Delete")
        
        // Swipe to delete
        let cell = app.tables.cells.staticTexts["Item to Delete"]
        cell.swipeLeft()
        
        // Tap delete button
        app.buttons["Delete"].tap()
        
        // Confirm deletion if prompted
        if app.alerts.buttons["Delete"].exists {
            app.alerts.buttons["Delete"].tap()
        }
        
        // Verify item is gone
        XCTAssertFalse(app.tables.cells.staticTexts["Item to Delete"].exists)
    }
    
    func testDeleteItemFromDetail() throws {
        // Create test item
        createTestItem(name: "Detail Delete Item")
        
        // Open item detail
        app.tables.cells.staticTexts["Detail Delete Item"].tap()
        
        // Look for delete button (might be in toolbar or nav bar)
        if app.toolbars.buttons["Delete"].exists {
            app.toolbars.buttons["Delete"].tap()
        } else if app.navigationBars.buttons["Delete"].exists {
            app.navigationBars.buttons["Delete"].tap()
        }
        
        // Confirm deletion
        if app.alerts.buttons["Delete"].exists {
            app.alerts.buttons["Delete"].tap()
        }
        
        // Should return to list
        XCTAssertTrue(app.navigationBars["Items"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.tables.cells.staticTexts["Detail Delete Item"].exists)
    }
    
    // MARK: - Validation Tests
    
    func testAddItemValidation() throws {
        // Try to add item without name
        app.navigationBars.buttons["plus"].tap()
        app.navigationBars.buttons["Save"].tap()
        
        // Should show validation error
        XCTAssertTrue(app.alerts.staticTexts["Item name is required"].exists ||
                     app.staticTexts["Item name is required"].exists)
        
        // Dismiss alert if present
        if app.alerts.buttons["OK"].exists {
            app.alerts.buttons["OK"].tap()
        }
    }
    
    func testPriceValidation() throws {
        app.navigationBars.buttons["plus"].tap()
        
        // Enter invalid price
        let priceField = app.textFields["Price"]
        priceField.tap()
        priceField.typeText("abc")
        
        // Try to save
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("Test Item")
        
        app.navigationBars.buttons["Save"].tap()
        
        // Should show price validation error
        XCTAssertTrue(app.alerts.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'price'")).exists ||
                     app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'price'")).exists)
    }
    
    // MARK: - Helper Methods
    
    private func createTestItem(name: String, price: String? = nil) {
        app.navigationBars.buttons["plus"].tap()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText(name)
        
        if let price = price {
            let priceField = app.textFields["Price"]
            priceField.tap()
            priceField.typeText(price)
        }
        
        app.navigationBars.buttons["Save"].tap()
        
        // Wait for item to appear
        _ = app.tables.cells.staticTexts[name].waitForExistence(timeout: 3)
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}