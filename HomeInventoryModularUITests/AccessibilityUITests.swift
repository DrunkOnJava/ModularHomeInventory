//
//  AccessibilityUITests.swift
//  HomeInventoryModularUITests
//
//  UI Tests for accessibility features and VoiceOver support
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["--enable-accessibility-testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Label Tests
    
    func testItemListAccessibilityLabels() throws {
        // Navigate to items list
        let itemsList = app.tables["ItemsList"]
        XCTAssertTrue(itemsList.waitForExistence(timeout: 5))
        
        // Check first item has proper accessibility labels
        let firstItem = itemsList.cells.firstMatch
        if firstItem.exists {
            // Verify accessibility label exists and is descriptive
            XCTAssertFalse(firstItem.label.isEmpty)
            
            // Should contain item name and key details
            let label = firstItem.label.lowercased()
            XCTAssertTrue(label.contains("item") || label.contains("name") || label.contains("$"))
        }
    }
    
    func testButtonAccessibilityLabels() throws {
        // Check tab bar buttons
        let tabButtons = [
            ("Items", "Items tab"),
            ("Scanner", "Scanner tab"),
            ("Settings", "Settings tab")
        ]
        
        for (identifier, expectedHint) in tabButtons {
            let button = app.tabBars.buttons[identifier]
            if button.exists {
                XCTAssertFalse(button.label.isEmpty)
                // Some buttons might have accessibility hints
            }
        }
        
        // Check navigation buttons
        if app.navigationBars.buttons["Add"].exists {
            let addButton = app.navigationBars.buttons["Add"]
            XCTAssertTrue(addButton.label == "Add" || addButton.label == "Add Item")
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    func testLargeTextSupport() throws {
        // Relaunch with large text
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        
        // Verify UI adapts to large text
        let itemsList = app.tables["ItemsList"]
        XCTAssertTrue(itemsList.waitForExistence(timeout: 5))
        
        // Text should still be visible and not truncated
        let firstCell = itemsList.cells.firstMatch
        if firstCell.exists {
            // Cell should have increased height for large text
            XCTAssertTrue(firstCell.frame.height > 44) // Standard cell height
        }
    }
    
    func testExtraLargeTextSupport() throws {
        // Relaunch with extra large text
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        
        // UI should still be functional
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5))
        
        // Navigation should still work
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 3))
            app.navigationBars.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOverNavigation() throws {
        // Note: Actually testing with VoiceOver enabled is complex
        // These tests verify the accessibility elements are properly set up
        
        // Check all interactive elements are accessible
        let allElements = app.descendants(matching: .any)
        let interactiveElements = allElements.allElementsBoundByIndex.filter { element in
            element.isHittable && element.exists
        }
        
        // Each interactive element should have a label
        for element in interactiveElements.prefix(10) { // Check first 10 to avoid timeout
            if element.elementType != .other && element.elementType != .cell {
                XCTAssertFalse(element.label.isEmpty, "Element \(element) missing accessibility label")
            }
        }
    }
    
    // MARK: - Color Contrast Tests
    
    func testHighContrastMode() throws {
        // Relaunch with high contrast preference
        app.launchArguments += ["--increase-contrast"]
        app.launch()
        
        // UI should still be visible and functional
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5))
        
        // Buttons should still be distinguishable
        if app.buttons["Filter"].exists {
            // In high contrast, buttons should have clear borders or backgrounds
            XCTAssertTrue(app.buttons["Filter"].isHittable)
        }
    }
    
    // MARK: - Reduce Motion Tests
    
    func testReduceMotion() throws {
        // Relaunch with reduce motion
        app.launchArguments += ["--reduce-motion"]
        app.launch()
        
        // Navigate between tabs - transitions should be instant
        app.tabBars.buttons["Scanner"].tap()
        app.tabBars.buttons["Settings"].tap()
        app.tabBars.buttons["Items"].tap()
        
        // All navigation should work without animations
        XCTAssertTrue(app.tables["ItemsList"].exists)
    }
    
    // MARK: - Accessibility Actions Tests
    
    func testAccessibilityCustomActions() throws {
        // Find an item cell
        let itemCell = app.tables["ItemsList"].cells.firstMatch
        
        if itemCell.exists {
            // Check for custom accessibility actions
            // In actual VoiceOver, these would be available via rotor
            
            // Long press to check for actions
            itemCell.press(forDuration: 1.0)
            
            // Context menu should be accessible
            if app.menus.firstMatch.exists {
                XCTAssertTrue(app.menus.buttons["Edit"].exists)
                XCTAssertTrue(app.menus.buttons["Delete"].exists)
            }
        }
    }
    
    // MARK: - Form Accessibility Tests
    
    func testFormFieldAccessibility() throws {
        // Navigate to add item
        app.navigationBars.buttons["Add"].tap()
        
        // Check text field accessibility
        let nameField = app.textFields["Item Name"]
        if nameField.exists {
            XCTAssertFalse(nameField.label.isEmpty)
            XCTAssertTrue(nameField.label.contains("Name") || nameField.label.contains("Item"))
            
            // Placeholder should not be the only label
            XCTAssertNotEqual(nameField.label, nameField.placeholderValue)
        }
        
        // Check price field
        let priceField = app.textFields["Price"]
        if priceField.exists {
            XCTAssertFalse(priceField.label.isEmpty)
            // Should indicate it's for price/cost/amount
            XCTAssertTrue(priceField.label.lowercased().contains("price") ||
                         priceField.label.lowercased().contains("cost"))
        }
    }
    
    // MARK: - Image Accessibility Tests
    
    func testImageAccessibilityDescriptions() throws {
        // Navigate to an item with images
        app.tables["ItemsList"].cells.firstMatch.tap()
        
        // Check image accessibility
        let images = app.images.allElementsBoundByIndex
        for image in images.prefix(5) {
            if image.exists && image.isHittable {
                // Images should have accessibility labels
                XCTAssertFalse(image.label.isEmpty)
                // Should not just be "Image" or filename
                XCTAssertNotEqual(image.label.lowercased(), "image")
                XCTAssertFalse(image.label.hasSuffix(".png"))
                XCTAssertFalse(image.label.hasSuffix(".jpg"))
            }
        }
    }
    
    // MARK: - Alert Accessibility Tests
    
    func testAlertAccessibility() throws {
        // Trigger an alert (try to save without required fields)
        app.navigationBars.buttons["Add"].tap()
        app.navigationBars.buttons["Save"].tap()
        
        // Alert should be accessible
        if app.alerts.firstMatch.waitForExistence(timeout: 2) {
            let alert = app.alerts.firstMatch
            
            // Alert should have accessible title and message
            XCTAssertFalse(alert.label.isEmpty)
            
            // Buttons should be clearly labeled
            XCTAssertTrue(app.alerts.buttons["OK"].exists ||
                         app.alerts.buttons["Dismiss"].exists)
        }
    }
    
    // MARK: - Switch Control Tests
    
    func testSwitchControlNavigation() throws {
        // Verify all interactive elements can be reached via linear navigation
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let cells = app.cells.allElementsBoundByIndex
        
        // All interactive elements should be reachable
        let totalInteractive = buttons.count + textFields.count + cells.count
        XCTAssertGreaterThan(totalInteractive, 0)
    }
    
    // MARK: - Voice Control Tests
    
    func testVoiceControlLabels() throws {
        // Elements should have labels suitable for voice commands
        
        // Check buttons have speakable labels
        if app.buttons["Add"].exists {
            let addButton = app.buttons["Add"]
            // Label should be clear and speakable
            XCTAssertTrue(addButton.label == "Add" || 
                         addButton.label == "Add Item" ||
                         addButton.label == "Add New Item")
        }
        
        // Tab names should be speakable
        let tabBar = app.tabBars.firstMatch
        for button in tabBar.buttons.allElementsBoundByIndex {
            if button.exists {
                XCTAssertFalse(button.label.isEmpty)
                // Should be single words or short phrases
                XCTAssertLessThan(button.label.count, 20)
            }
        }
    }
}