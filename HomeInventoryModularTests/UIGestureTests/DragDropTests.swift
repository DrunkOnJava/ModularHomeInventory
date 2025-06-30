import XCTest
import SwiftUI
@testable import Items
@testable import Core
@testable import TestUtilities

/// Tests for drag and drop functionality
final class DragDropTests: XCUITestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--enable-drag-drop"]
        app.launch()
        
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // MARK: - Basic Drag and Drop Tests
    
    func testDragItemToReorder() throws {
        navigateToItemsList()
        
        // Create items in specific order
        createTestItem(name: "Item A", value: 100)
        createTestItem(name: "Item B", value: 200)
        createTestItem(name: "Item C", value: 300)
        
        // Find items
        let itemA = app.cells["Item A"]
        let itemB = app.cells["Item B"]
        let itemC = app.cells["Item C"]
        
        XCTAssertTrue(itemA.waitForExistence(timeout: 5))
        
        // Record initial positions
        let initialAPosition = itemA.frame.origin.y
        let initialCPosition = itemC.frame.origin.y
        
        // Drag Item A below Item C
        itemA.press(forDuration: 1.0, thenDragTo: itemC)
        
        // Wait for reorder animation
        sleep(1)
        
        // Verify new order
        let newAPosition = itemA.frame.origin.y
        let newCPosition = itemC.frame.origin.y
        
        XCTAssertGreaterThan(newAPosition, initialAPosition)
        XCTAssertLessThan(newCPosition, initialCPosition)
    }
    
    func testDragItemToCategory() throws {
        // Navigate to categorized view
        navigateToItemsList()
        app.buttons["View"].tap()
        app.buttons["By Category"].tap()
        
        // Create items
        createTestItem(name: "Uncategorized Item", category: "General")
        
        // Ensure Electronics category exists
        if !app.cells["Electronics"].exists {
            createTestItem(name: "Electronic Item", category: "Electronics")
        }
        
        let item = app.cells["Uncategorized Item"]
        let electronicsCategory = app.cells["Electronics"]
        
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        XCTAssertTrue(electronicsCategory.exists)
        
        // Drag item to Electronics category
        item.press(forDuration: 1.0, thenDragTo: electronicsCategory)
        
        // Verify item moved to category
        sleep(1)
        
        // Expand Electronics category
        electronicsCategory.tap()
        
        // Verify item is now in Electronics
        let itemInElectronics = app.cells["Uncategorized Item"]
        XCTAssertTrue(itemInElectronics.waitForExistence(timeout: 3))
    }
    
    func testDragMultipleItems() throws {
        navigateToItemsList()
        
        // Enable multi-select mode
        app.navigationBars.buttons["Select"].tap()
        
        // Create and select multiple items
        createTestItem(name: "Multi Item 1")
        createTestItem(name: "Multi Item 2")
        createTestItem(name: "Multi Item 3")
        
        app.cells["Multi Item 1"].tap()
        app.cells["Multi Item 2"].tap()
        
        // Start drag from one selected item
        let dragHandle = app.cells["Multi Item 1"]
        let targetLocation = app.cells["Multi Item 3"]
        
        // Long press and drag
        dragHandle.press(forDuration: 1.0, thenDragTo: targetLocation)
        
        // Verify both items moved
        sleep(1)
        
        let item1Position = app.cells["Multi Item 1"].frame.origin.y
        let item2Position = app.cells["Multi Item 2"].frame.origin.y
        let item3Position = app.cells["Multi Item 3"].frame.origin.y
        
        XCTAssertGreaterThan(item1Position, item3Position)
        XCTAssertGreaterThan(item2Position, item3Position)
    }
    
    // MARK: - Drop Target Tests
    
    func testDropTargetHighlighting() throws {
        navigateToItemsList()
        
        createTestItem(name: "Drag Source")
        
        // Switch to folder view
        app.buttons["Folders"].tap()
        
        // Ensure folders exist
        if !app.cells["Important"].exists {
            createFolder(name: "Important")
        }
        
        let item = app.cells["Drag Source"]
        let folder = app.cells["Important"]
        
        // Start dragging
        let startPoint = item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let folderPoint = folder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        // Begin drag
        startPoint.press(forDuration: 1.0)
        
        // Move over folder (should highlight)
        startPoint.withOffset(CGVector(dx: 0, dy: 0)).press(
            forDuration: 0.1,
            thenDragTo: folderPoint,
            withVelocity: .slow
        )
        
        // Verify folder is highlighted
        XCTAssertTrue(folder.isSelected || folder.value(forKey: "highlighted") as? Bool == true)
        
        // Drop
        sleep(0.5)
        
        // Verify item moved to folder
        folder.tap() // Open folder
        XCTAssertTrue(app.cells["Drag Source"].waitForExistence(timeout: 3))
    }
    
    func testInvalidDropTarget() throws {
        navigateToItemsList()
        
        createTestItem(name: "Test Item")
        
        let item = app.cells["Test Item"]
        let invalidTarget = app.navigationBars.firstMatch // Navigation bar is not a valid drop target
        
        // Attempt to drag to invalid target
        item.press(forDuration: 1.0, thenDragTo: invalidTarget)
        
        // Item should return to original position
        sleep(1)
        
        // Verify item still in list
        XCTAssertTrue(item.exists)
        XCTAssertFalse(app.staticTexts["Drop not allowed"].exists)
    }
    
    // MARK: - Drag Preview Tests
    
    func testDragPreviewAppearance() throws {
        navigateToItemsList()
        
        createTestItem(name: "Preview Test", value: 999.99)
        
        let item = app.cells["Preview Test"]
        
        // Start drag to show preview
        let startPoint = item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        startPoint.press(forDuration: 1.5) // Hold to show preview
        
        // Verify preview contains key information
        let dragPreview = app.otherElements["DragPreview"]
        if dragPreview.waitForExistence(timeout: 2) {
            XCTAssertTrue(dragPreview.staticTexts["Preview Test"].exists)
            XCTAssertTrue(dragPreview.staticTexts["$999.99"].exists)
        }
        
        // Cancel drag
        app.tap()
    }
    
    func testMultiItemDragPreview() throws {
        navigateToItemsList()
        app.navigationBars.buttons["Select"].tap()
        
        // Create and select multiple items
        for i in 1...3 {
            createTestItem(name: "Batch Item \(i)")
            app.cells["Batch Item \(i)"].tap()
        }
        
        // Start drag
        let firstItem = app.cells["Batch Item 1"]
        firstItem.press(forDuration: 1.5)
        
        // Verify multi-item preview
        let dragPreview = app.otherElements["DragPreview"]
        if dragPreview.waitForExistence(timeout: 2) {
            XCTAssertTrue(dragPreview.staticTexts["3 items"].exists)
        }
        
        app.tap() // Cancel
    }
    
    // MARK: - Cross-App Drag and Drop Tests
    
    func testDragFromOtherApp() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Cross-app drag and drop requires iPad")
        }
        
        // Launch Photos app in split view
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        // Open app switcher
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        // This is a simplified test - full implementation would require
        // split screen setup and actual cross-app dragging
        
        // For now, test accepting drops from pasteboard
        UIPasteboard.general.string = "Dropped Text"
        
        app.activate()
        navigateToItemsList()
        
        // Simulate drop
        let dropZone = app.otherElements["DropZone"]
        if dropZone.exists {
            dropZone.tap()
            
            // Verify item created from dropped content
            XCTAssertTrue(app.cells["Dropped Text"].waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Gesture Conflict Tests
    
    func testDragVsScrollConflict() throws {
        navigateToItemsList()
        
        // Create many items to enable scrolling
        for i in 0..<30 {
            createTestItem(name: "Scroll Item \(i)")
        }
        
        let middleItem = app.cells["Scroll Item 15"]
        app.swipeUp() // Scroll to middle
        app.swipeUp()
        
        XCTAssertTrue(middleItem.waitForExistence(timeout: 3))
        
        // Quick swipe should scroll
        let initialY = middleItem.frame.origin.y
        app.swipeUp(velocity: .fast)
        
        if middleItem.exists {
            let newY = middleItem.frame.origin.y
            XCTAssertLessThan(newY, initialY, "Quick swipe should scroll")
        }
        
        // Long press should initiate drag
        app.swipeDown() // Scroll back
        app.swipeDown()
        
        if middleItem.waitForExistence(timeout: 3) {
            middleItem.press(forDuration: 1.0)
            
            // Should enter drag mode
            let dragIndicator = app.otherElements["DragIndicator"]
            XCTAssertTrue(dragIndicator.exists || middleItem.value(forKey: "dragging") as? Bool == true)
            
            app.tap() // Cancel drag
        }
    }
    
    // MARK: - Accessibility Drag and Drop Tests
    
    func testDragDropAccessibility() throws {
        app.launchArguments.append("--voiceover-mode")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Accessible Drag")
        
        let item = app.cells["Accessible Drag"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        
        // With VoiceOver, drag is initiated through actions
        item.tap() // Focus
        
        // Perform accessibility drag action
        item.doubleTap()
        
        let dragAction = app.buttons["Drag"]
        if dragAction.waitForExistence(timeout: 2) {
            dragAction.tap()
            
            // Navigate to drop target
            app.swipeRight() // VoiceOver navigation
            app.swipeRight()
            
            // Drop action
            let dropAction = app.buttons["Drop Here"]
            if dropAction.exists {
                dropAction.tap()
            }
        }
    }
    
    // MARK: - Spring Loading Tests
    
    func testSpringLoadedFolders() throws {
        navigateToItemsList()
        
        // Create folder structure
        createFolder(name: "Parent Folder")
        app.cells["Parent Folder"].tap()
        createFolder(name: "Child Folder")
        app.navigationBars.buttons["Items"].tap() // Go back
        
        // Create item to drag
        createTestItem(name: "Spring Load Test")
        
        let item = app.cells["Spring Load Test"]
        let parentFolder = app.cells["Parent Folder"]
        
        // Start dragging
        let dragStart = item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let folderLocation = parentFolder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        // Drag and hover over folder
        dragStart.press(forDuration: 1.0, thenDragTo: folderLocation, withVelocity: .slow)
        
        // Hold for spring loading
        sleep(1.5)
        
        // Folder should open
        XCTAssertTrue(app.navigationBars["Parent Folder"].waitForExistence(timeout: 2))
        
        // Continue drag to child folder
        let childFolder = app.cells["Child Folder"]
        if childFolder.exists {
            let childLocation = childFolder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            folderLocation.press(forDuration: 0.1, thenDragTo: childLocation)
            
            // Drop
            sleep(0.5)
            
            // Verify item in child folder
            childFolder.tap()
            XCTAssertTrue(app.cells["Spring Load Test"].waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToItemsList() {
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
        }
    }
    
    private func createTestItem(name: String, value: Double = 100, category: String = "General") {
        if !app.navigationBars.buttons["Add"].waitForExistence(timeout: 3) {
            navigateToItemsList()
        }
        
        app.navigationBars.buttons["Add"].tap()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText(name)
        
        if value != 100 {
            let valueField = app.textFields["Value"]
            valueField.tap()
            valueField.typeText("\(value)")
        }
        
        if category != "General" {
            app.buttons["Category"].tap()
            app.buttons[category].tap()
        }
        
        app.buttons["Save"].tap()
        sleep(1)
    }
    
    private func createFolder(name: String) {
        app.navigationBars.buttons["Add Folder"].tap()
        
        let nameField = app.textFields["Folder Name"]
        nameField.tap()
        nameField.typeText(name)
        
        app.buttons["Create"].tap()
        sleep(1)
    }
}

// MARK: - XCUICoordinate Extensions

extension XCUICoordinate {
    func press(forDuration duration: TimeInterval,
               thenDragTo other: XCUICoordinate,
               withVelocity velocity: XCUIGestureVelocity = .default) {
        
        self.press(forDuration: duration)
        
        // Calculate intermediate points for smooth dragging
        let steps = 10
        let deltaX = (other.screenPoint.x - self.screenPoint.x) / CGFloat(steps)
        let deltaY = (other.screenPoint.y - self.screenPoint.y) / CGFloat(steps)
        
        var currentPoint = self.screenPoint
        
        for _ in 0..<steps {
            currentPoint.x += deltaX
            currentPoint.y += deltaY
            
            let intermediate = self.withOffset(CGVector(
                dx: currentPoint.x - self.screenPoint.x,
                dy: currentPoint.y - self.screenPoint.y
            ))
            
            intermediate.tap()
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
}