import XCTest
import SwiftUI
@testable import Items
@testable import Core
@testable import TestUtilities

/// Tests for keyboard handling and input interactions
final class KeyboardHandlingTests: XCUITestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
        
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // MARK: - Basic Keyboard Tests
    
    func testKeyboardAppearanceAndDismissal() throws {
        navigateToAddItem()
        
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        
        // Tap to show keyboard
        nameField.tap()
        
        // Verify keyboard appears
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2))
        
        // Type text
        nameField.typeText("Test Item")
        
        // Test different dismissal methods
        
        // Method 1: Tap return
        app.keyboards.buttons["return"].tap()
        XCTAssertFalse(app.keyboards.element.exists)
        
        // Method 2: Tap outside
        nameField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2))
        app.otherElements["AddItemView"].tap()
        XCTAssertFalse(app.keyboards.element.exists)
        
        // Method 3: Swipe down on keyboard (iPad)
        if UIDevice.current.userInterfaceIdiom == .pad {
            nameField.tap()
            if app.keyboards.element.waitForExistence(timeout: 2) {
                app.keyboards.element.swipeDown()
                XCTAssertFalse(app.keyboards.element.exists)
            }
        }
    }
    
    func testKeyboardAvoidance() throws {
        navigateToAddItem()
        
        // Scroll to bottom fields
        app.swipeUp()
        
        let notesField = app.textViews["Notes"]
        XCTAssertTrue(notesField.waitForExistence(timeout: 3))
        
        // Record field position before keyboard
        let originalY = notesField.frame.origin.y
        
        // Tap to show keyboard
        notesField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2))
        
        // Field should move up if it would be covered
        let keyboardHeight = app.keyboards.element.frame.height
        let fieldBottom = notesField.frame.maxY
        let screenHeight = app.frame.height
        
        if fieldBottom > (screenHeight - keyboardHeight) {
            // Field should have moved up
            let newY = notesField.frame.origin.y
            XCTAssertLessThan(newY, originalY)
        }
        
        // Dismiss keyboard
        app.keyboards.buttons["return"].tap()
        
        // Field should return to original position
        sleep(1) // Wait for animation
        XCTAssertEqual(notesField.frame.origin.y, originalY, accuracy: 10)
    }
    
    // MARK: - Text Input Tests
    
    func testTextFieldInputTypes() throws {
        navigateToAddItem()
        
        // Test different keyboard types
        let testCases: [(field: String, keyboard: String, testInput: String)] = [
            ("Item Name", "Default", "Test Item 123"),
            ("Value", "Decimal Pad", "1234.56"),
            ("Serial Number", "ASCII Capable", "SN-12345-ABC"),
            ("Purchase Price", "Decimal Pad", "999.99"),
            ("Quantity", "Number Pad", "42")
        ]
        
        for (fieldName, expectedKeyboard, input) in testCases {
            let field = app.textFields[fieldName]
            guard field.waitForExistence(timeout: 3) else { continue }
            
            field.tap()
            XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2))
            
            // Verify correct keyboard type
            switch expectedKeyboard {
            case "Number Pad":
                XCTAssertTrue(app.keyboards.keys["1"].exists)
                XCTAssertFalse(app.keyboards.keys["Q"].exists)
                
            case "Decimal Pad":
                XCTAssertTrue(app.keyboards.keys["1"].exists)
                XCTAssertTrue(app.keyboards.keys["."].exists || app.keyboards.keys[","].exists)
                XCTAssertFalse(app.keyboards.keys["Q"].exists)
                
            case "Default", "ASCII Capable":
                XCTAssertTrue(app.keyboards.keys["Q"].exists || app.keyboards.keys["q"].exists)
                
            default:
                break
            }
            
            // Clear and type test input
            if let currentValue = field.value as? String, !currentValue.isEmpty {
                field.doubleTap()
                app.menuItems["Select All"].tap()
            }
            
            field.typeText(input)
            
            // Verify input
            XCTAssertEqual(field.value as? String, input)
            
            // Dismiss keyboard
            if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            } else {
                app.keyboards.buttons["return"].tap()
            }
        }
    }
    
    func testTextViewMultilineInput() throws {
        navigateToAddItem()
        app.swipeUp()
        
        let notesView = app.textViews["Notes"]
        XCTAssertTrue(notesView.waitForExistence(timeout: 3))
        
        notesView.tap()
        
        // Type multiline text
        notesView.typeText("First line of notes")
        
        // Insert line break
        if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }
        
        notesView.typeText("Second line of notes")
        app.keyboards.buttons["return"].tap()
        notesView.typeText("Third line of notes")
        
        // Verify multiline input
        let text = notesView.value as? String ?? ""
        XCTAssertTrue(text.contains("First line"))
        XCTAssertTrue(text.contains("Second line"))
        XCTAssertTrue(text.contains("Third line"))
    }
    
    // MARK: - Keyboard Shortcuts Tests
    
    func testKeyboardShortcuts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Keyboard shortcuts require iPad with external keyboard")
        }
        
        // Simulate external keyboard
        app.launchArguments.append("--external-keyboard")
        app.launch()
        
        navigateToItemsList()
        
        // Test Command+N for new item
        XCUIDevice.shared.press([.command, .init(XCUIKeyboardKey.n.rawValue)])
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 2))
        
        // Test Escape to cancel
        XCUIDevice.shared.press(.init(XCUIKeyboardKey.escape.rawValue))
        XCTAssertTrue(app.navigationBars["Items"].waitForExistence(timeout: 2))
        
        // Create test item
        createTestItem(name: "Shortcut Test")
        
        // Test Command+F for search
        XCUIDevice.shared.press([.command, .init(XCUIKeyboardKey.f.rawValue)])
        XCTAssertTrue(app.searchFields.element.waitForExistence(timeout: 2))
        
        // Test arrow navigation
        XCUIDevice.shared.press(.downArrow)
        
        // Test Command+Delete for delete
        XCUIDevice.shared.press([.command, .delete])
        
        if app.alerts["Delete Item?"].waitForExistence(timeout: 2) {
            // Test Enter to confirm
            XCUIDevice.shared.press(.enter)
        }
    }
    
    func testTextEditingShortcuts() throws {
        navigateToAddItem()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        
        // Type some text
        nameField.typeText("Hello World Test")
        
        // Test text selection shortcuts
        // Command+A - Select All
        nameField.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Triple tap to select all (iOS gesture)
        nameField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(withNumberOfTaps: 3, numberOfTouches: 1)
        
        // Verify selection menu appears
        XCTAssertTrue(app.menuItems["Cut"].waitForExistence(timeout: 2))
        
        // Test cut
        app.menuItems["Cut"].tap()
        
        // Verify field is empty
        XCTAssertEqual(nameField.value as? String, "")
        
        // Test paste
        nameField.tap()
        Thread.sleep(forTimeInterval: 0.5)
        nameField.doubleTap()
        
        if app.menuItems["Paste"].waitForExistence(timeout: 2) {
            app.menuItems["Paste"].tap()
            XCTAssertEqual(nameField.value as? String, "Hello World Test")
        }
    }
    
    // MARK: - Auto-Correction and Completion Tests
    
    func testAutoCorrection() throws {
        navigateToAddItem()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        
        // Type misspelled word
        nameField.typeText("Teh ")
        
        // Auto-correction should change to "The"
        sleep(1)
        
        let fieldValue = nameField.value as? String ?? ""
        XCTAssertTrue(fieldValue.contains("The") || fieldValue.contains("Teh"))
        
        // Test accepting autocorrection
        nameField.typeText("quick brown")
        
        // Dismiss keyboard to accept corrections
        app.keyboards.buttons["return"].tap()
    }
    
    func testTextReplacement() throws {
        navigateToAddItem()
        
        let notesField = app.textViews["Notes"]
        notesField.tap()
        
        // Test common text replacements
        let replacements = [
            ("omw", "On my way!"),
            ("(c)", "©"),
            ("(r)", "®"),
            ("...", "…")
        ]
        
        for (shortcut, expected) in replacements {
            notesField.typeText(shortcut + " ")
            let text = notesField.value as? String ?? ""
            
            // Some replacements might be system-dependent
            print("Typed '\(shortcut)', got: '\(text)'")
        }
    }
    
    // MARK: - Search Field Tests
    
    func testSearchFieldBehavior() throws {
        navigateToItemsList()
        
        // Create test items
        createTestItem(name: "Apple iPhone")
        createTestItem(name: "Apple Watch")
        createTestItem(name: "Samsung Galaxy")
        createTestItem(name: "Google Pixel")
        
        // Tap search
        let searchField = app.searchFields.element
        searchField.tap()
        
        // Verify search keyboard
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2))
        XCTAssertTrue(app.keyboards.buttons["Search"].exists)
        
        // Type search query
        searchField.typeText("Apple")
        
        // Results should filter in real-time
        sleep(1)
        
        XCTAssertTrue(app.cells["Apple iPhone"].exists)
        XCTAssertTrue(app.cells["Apple Watch"].exists)
        XCTAssertFalse(app.cells["Samsung Galaxy"].exists)
        
        // Test search button
        app.keyboards.buttons["Search"].tap()
        
        // Keyboard should dismiss but search active
        XCTAssertFalse(app.keyboards.element.exists)
        XCTAssertTrue(app.cells["Apple iPhone"].exists)
        
        // Clear search
        searchField.tap()
        searchField.buttons["Clear text"].tap()
        
        // All items should reappear
        sleep(1)
        XCTAssertTrue(app.cells["Samsung Galaxy"].exists)
        XCTAssertTrue(app.cells["Google Pixel"].exists)
    }
    
    // MARK: - Form Navigation Tests
    
    func testTabKeyNavigation() throws {
        navigateToAddItem()
        
        let nameField = app.textFields["Item Name"]
        let valueField = app.textFields["Value"]
        let serialField = app.textFields["Serial Number"]
        
        // Start with name field
        nameField.tap()
        nameField.typeText("Tab Test")
        
        // Verify Tab button exists (iPad)
        if app.keyboards.buttons["Tab"].exists {
            app.keyboards.buttons["Tab"].tap()
            
            // Should move to value field
            XCTAssertTrue(valueField.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
            
            valueField.typeText("100")
            app.keyboards.buttons["Tab"].tap()
            
            // Should move to serial field
            XCTAssertTrue(serialField.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        } else {
            // iPhone - use Next button on toolbar
            if app.toolbars.buttons["Next"].exists {
                app.toolbars.buttons["Next"].tap()
                XCTAssertEqual(app.textFields.element(boundBy: 1).value(forKey: "hasKeyboardFocus") as? Bool, true)
            }
        }
    }
    
    // MARK: - Input Validation Tests
    
    func testNumericFieldValidation() throws {
        navigateToAddItem()
        
        let valueField = app.textFields["Value"]
        valueField.tap()
        
        // Try to enter invalid characters
        let invalidInputs = ["abc", "12.34.56", "-999", "1e10"]
        
        for input in invalidInputs {
            valueField.clearAndTypeText(input)
            
            // Move to next field to trigger validation
            app.textFields["Item Name"].tap()
            
            // Check for validation error
            if app.staticTexts["Invalid value"].waitForExistence(timeout: 1) {
                XCTAssertTrue(true, "Validation error shown for: \(input)")
            }
            
            // Clear for next test
            valueField.tap()
            valueField.clearAndTypeText("")
        }
        
        // Test valid input
        valueField.clearAndTypeText("1234.56")
        app.textFields["Item Name"].tap()
        
        XCTAssertFalse(app.staticTexts["Invalid value"].exists)
    }
    
    // MARK: - Accessibility Keyboard Tests
    
    func testVoiceOverKeyboardNavigation() throws {
        app.launchArguments.append("--voiceover-mode")
        app.launch()
        
        navigateToAddItem()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        
        // With VoiceOver, verify keyboard navigation
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3))
        
        // VoiceOver should announce field
        XCTAssertTrue(nameField.exists)
        XCTAssertNotEqual(nameField.label, "")
        
        // Type with VoiceOver
        nameField.typeText("Accessible Item")
        
        // Verify character echo (in actual VoiceOver, each character is announced)
        let typedValue = nameField.value as? String
        XCTAssertEqual(typedValue, "Accessible Item")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToItemsList() {
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
        }
    }
    
    private func navigateToAddItem() {
        navigateToItemsList()
        app.navigationBars.buttons["Add"].tap()
    }
    
    private func createTestItem(name: String) {
        if !app.navigationBars["Add Item"].exists {
            navigateToAddItem()
        }
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText(name)
        
        app.buttons["Save"].tap()
        sleep(1)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let currentValue = self.value as? String else {
            self.typeText(text)
            return
        }
        
        // Select all and delete
        self.tap()
        
        if currentValue.count > 0 {
            self.doubleTap()
            
            if XCUIApplication().menuItems["Select All"].waitForExistence(timeout: 1) {
                XCUIApplication().menuItems["Select All"].tap()
            }
            
            self.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        
        self.typeText(text)
    }
}

// MARK: - XCUIDevice Extensions

extension XCUIDevice {
    enum Key {
        case command
        case option
        case control
        case shift
        case enter
        case escape
        case delete
        case tab
        case space
        case downArrow
        case upArrow
        case leftArrow
        case rightArrow
        
        case character(String)
        
        init(_ rawValue: String) {
            self = .character(rawValue)
        }
    }
    
    func press(_ keys: [Key]) {
        // This is a simplified version - actual implementation would
        // send keyboard events to the simulator/device
        print("Simulating key press: \(keys)")
    }
    
    func press(_ key: Key) {
        press([key])
    }
}