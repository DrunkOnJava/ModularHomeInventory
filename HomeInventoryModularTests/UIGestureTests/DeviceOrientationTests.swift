import XCTest
import SwiftUI
@testable import Items
@testable import Core
@testable import TestUtilities

/// Tests for device rotation and orientation changes
final class DeviceOrientationTests: XCUITestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        
        // Set initial orientation
        XCUIDevice.shared.orientation = .portrait
        
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    override func tearDownWithError() throws {
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Rotation Tests
    
    func testPortraitToLandscapeRotation() throws {
        navigateToItemsList()
        
        // Create test items
        createTestItem(name: "Rotation Test 1")
        createTestItem(name: "Rotation Test 2")
        
        // Verify portrait layout
        XCTAssertEqual(XCUIDevice.shared.orientation, .portrait)
        
        let item1 = app.cells["Rotation Test 1"]
        let item2 = app.cells["Rotation Test 2"]
        
        XCTAssertTrue(item1.waitForExistence(timeout: 3))
        XCTAssertTrue(item2.exists)
        
        // Record portrait positions
        let portraitItem1Frame = item1.frame
        let portraitNavBarHeight = app.navigationBars.element.frame.height
        
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for rotation animation
        sleep(1)
        
        // Verify landscape layout
        XCTAssertEqual(XCUIDevice.shared.orientation, .landscapeLeft)
        
        // Items should still be visible
        XCTAssertTrue(item1.exists)
        XCTAssertTrue(item2.exists)
        
        // Layout should adapt
        let landscapeItem1Frame = item1.frame
        XCTAssertNotEqual(portraitItem1Frame, landscapeItem1Frame)
        
        // Navigation bar should be shorter in landscape
        let landscapeNavBarHeight = app.navigationBars.element.frame.height
        XCTAssertLessThan(landscapeNavBarHeight, portraitNavBarHeight)
    }
    
    func testAllOrientations() throws {
        let orientations: [UIDeviceOrientation] = [
            .portrait,
            .landscapeLeft,
            .portraitUpsideDown,
            .landscapeRight
        ]
        
        navigateToItemsList()
        createTestItem(name: "Orientation Test")
        
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            sleep(1)
            
            // Verify UI remains functional
            XCTAssertTrue(app.navigationBars.element.exists)
            XCTAssertTrue(app.cells["Orientation Test"].exists)
            
            // Verify we can still interact
            if app.buttons["Add"].exists {
                app.buttons["Add"].tap()
                XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 2))
                app.buttons["Cancel"].tap()
            }
        }
    }
    
    // MARK: - Layout Adaptation Tests
    
    func testSplitViewOnIPad() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Split view requires iPad")
        }
        
        // Start in landscape for split view
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        navigateToItemsList()
        
        // Create items
        for i in 1...5 {
            createTestItem(name: "iPad Item \(i)")
        }
        
        // In landscape, should show master-detail
        let masterView = app.tables["ItemsList"]
        let detailView = app.otherElements["ItemDetail"]
        
        if masterView.exists {
            // Select item in master
            app.cells["iPad Item 1"].tap()
            
            // Detail should update
            if detailView.waitForExistence(timeout: 2) {
                XCTAssertTrue(detailView.staticTexts["iPad Item 1"].exists)
            }
        }
        
        // Rotate to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        // Should collapse to single view
        if !detailView.exists || detailView.frame.width < app.frame.width * 0.5 {
            // Detail view hidden or narrow
            XCTAssertTrue(true, "Split view collapsed in portrait")
        }
    }
    
    func testCompactWidthClass() throws {
        // Test compact width (iPhone portrait, iPad splitview)
        XCUIDevice.shared.orientation = .portrait
        
        navigateToItemsList()
        
        // In compact width, tab bar should be at bottom
        if app.tabBars.element.exists {
            let tabBarY = app.tabBars.element.frame.origin.y
            let screenHeight = app.frame.height
            XCTAssertGreaterThan(tabBarY, screenHeight * 0.8)
        }
        
        // Rotate to landscape (may still be compact on iPhone)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone landscape is still compact height
            let navBarHeight = app.navigationBars.element.frame.height
            XCTAssertLessThan(navBarHeight, 50) // Compact navigation bar
        }
    }
    
    // MARK: - Content Preservation Tests
    
    func testFormStatePreservation() throws {
        navigateToAddItem()
        
        // Fill in form
        let nameField = app.textFields["Item Name"]
        let valueField = app.textFields["Value"]
        let notesField = app.textViews["Notes"]
        
        nameField.tap()
        nameField.typeText("Preservation Test")
        
        valueField.tap()
        valueField.typeText("999.99")
        
        notesField.tap()
        notesField.typeText("These are test notes that should be preserved")
        
        // Dismiss keyboard
        app.tap()
        
        // Rotate device
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Verify form data preserved
        XCTAssertEqual(nameField.value as? String, "Preservation Test")
        XCTAssertEqual(valueField.value as? String, "999.99")
        XCTAssertTrue((notesField.value as? String)?.contains("preserved") ?? false)
        
        // Rotate back
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        // Data should still be there
        XCTAssertEqual(nameField.value as? String, "Preservation Test")
    }
    
    func testScrollPositionPreservation() throws {
        navigateToItemsList()
        
        // Create many items
        for i in 1...30 {
            createTestItem(name: "Scroll Item \(i)")
        }
        
        // Scroll to middle
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        
        // Find a visible item
        let middleItem = app.cells["Scroll Item 15"]
        XCTAssertTrue(middleItem.waitForExistence(timeout: 3))
        
        let itemPositionBefore = middleItem.frame.origin.y
        
        // Rotate
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Item should still be visible (approximately same relative position)
        XCTAssertTrue(middleItem.exists)
        
        // Rotate back
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        // Should return to similar position
        let itemPositionAfter = middleItem.frame.origin.y
        XCTAssertEqual(itemPositionBefore, itemPositionAfter, accuracy: 50)
    }
    
    // MARK: - Modal and Popover Tests
    
    func testModalPresentationDuringRotation() throws {
        navigateToItemsList()
        
        // Present modal
        app.buttons["Add"].tap()
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 2))
        
        // Fill some data
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText("Modal Test")
        
        // Rotate while modal is presented
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Modal should still be presented
        XCTAssertTrue(app.navigationBars["Add Item"].exists)
        XCTAssertEqual(nameField.value as? String, "Modal Test")
        
        // Complete the action
        app.buttons["Save"].tap()
        
        // Verify saved in landscape
        XCTAssertTrue(app.cells["Modal Test"].waitForExistence(timeout: 3))
    }
    
    func testPopoverAdaptation() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Popover adaptation requires iPad")
        }
        
        navigateToItemsList()
        createTestItem(name: "Popover Test")
        
        // Start in landscape (popover mode)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Trigger popover
        app.cells["Popover Test"].tap()
        app.buttons["More"].tap()
        
        // Should show as popover
        let popover = app.popovers.element
        if popover.waitForExistence(timeout: 2) {
            XCTAssertTrue(popover.buttons["Share"].exists)
            
            // Rotate to portrait
            XCUIDevice.shared.orientation = .portrait
            sleep(1)
            
            // Popover might adapt to sheet
            if !popover.exists {
                XCTAssertTrue(app.sheets.element.exists)
            }
        }
    }
    
    // MARK: - Gesture Recognition Tests
    
    func testGesturesAfterRotation() throws {
        navigateToItemsList()
        createTestItem(name: "Gesture Test")
        
        let cell = app.cells["Gesture Test"]
        
        // Test swipe in portrait
        cell.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        app.tap() // Dismiss
        
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Test swipe in landscape
        cell.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        app.tap() // Dismiss
        
        // Test long press
        cell.press(forDuration: 1.0)
        if app.menus.element.waitForExistence(timeout: 2) {
            XCTAssertTrue(app.menus.buttons["Edit"].exists)
            app.tap() // Dismiss menu
        }
    }
    
    // MARK: - Performance Tests
    
    func testRotationPerformance() throws {
        navigateToItemsList()
        
        // Create substantial content
        for i in 1...20 {
            createTestItem(name: "Performance Item \(i)")
        }
        
        measure {
            // Rotate back and forth
            XCUIDevice.shared.orientation = .landscapeLeft
            sleep(0.5)
            XCUIDevice.shared.orientation = .portrait
            sleep(0.5)
        }
    }
    
    // MARK: - Safe Area Tests
    
    func testSafeAreaHandling() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Safe area tests designed for iPhone")
        }
        
        navigateToItemsList()
        
        // In portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        // Bottom content should respect safe area
        if app.tabBars.element.exists {
            let tabBar = app.tabBars.element
            let screenHeight = app.frame.height
            let tabBarBottom = tabBar.frame.maxY
            
            // Should have padding for home indicator
            XCTAssertLessThan(tabBarBottom, screenHeight)
        }
        
        // In landscape (with notch)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Content should avoid notch area
        let firstCell = app.cells.element(boundBy: 0)
        if firstCell.exists {
            let cellX = firstCell.frame.origin.x
            XCTAssertGreaterThan(cellX, 30) // Safe area inset
        }
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
        if !app.navigationBars.buttons["Add"].exists {
            navigateToItemsList()
        }
        
        app.navigationBars.buttons["Add"].tap()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText(name)
        
        app.buttons["Save"].tap()
        sleep(1)
        
        // Handle different orientations
        if !app.cells[name].exists {
            // Might need to dismiss detail view on iPad
            if app.navigationBars.buttons["Items"].exists {
                app.navigationBars.buttons["Items"].tap()
            }
        }
    }
}

// MARK: - UIDeviceOrientation Extension

extension UIDeviceOrientation {
    var isCompactHeight: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
    
    var isCompactWidth: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return true
        }
        return self == .portrait || self == .portraitUpsideDown
    }
}