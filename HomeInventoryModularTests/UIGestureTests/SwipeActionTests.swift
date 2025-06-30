import XCTest
import SwiftUI
@testable import Items
@testable import Core
@testable import TestUtilities

/// Tests for swipe actions and gestures in list views
final class SwipeActionTests: XCUITestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
        
        // Wait for app to be ready
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // MARK: - Basic Swipe Tests
    
    func testSwipeToDelete() throws {
        // Navigate to items list
        navigateToItemsList()
        
        // Create test item
        createTestItem(name: "Swipe Delete Test")
        
        // Find the item cell
        let itemCell = app.cells["Swipe Delete Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Swipe left to reveal delete button
        itemCell.swipeLeft()
        
        // Tap delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()
        
        // Confirm deletion
        let confirmButton = app.alerts.buttons["Delete"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }
        
        // Verify item is deleted
        XCTAssertFalse(itemCell.waitForExistence(timeout: 2))
    }
    
    func testSwipeToEdit() throws {
        navigateToItemsList()
        createTestItem(name: "Swipe Edit Test")
        
        let itemCell = app.cells["Swipe Edit Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Swipe right to reveal edit action
        itemCell.swipeRight()
        
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.tap()
        
        // Verify edit view appears
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 3))
        
        // Make an edit
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.clearAndTypeText("Edited Item Name")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify item name updated
        XCTAssertTrue(app.cells["Edited Item Name"].waitForExistence(timeout: 3))
    }
    
    func testMultipleSwipeActions() throws {
        navigateToItemsList()
        createTestItem(name: "Multi Action Test", value: 500)
        
        let itemCell = app.cells["Multi Action Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Full swipe left for quick delete
        itemCell.swipeLeft(velocity: .fast)
        
        // Should show immediate delete confirmation
        let deleteConfirmation = app.alerts["Delete Item?"]
        XCTAssertTrue(deleteConfirmation.waitForExistence(timeout: 2))
        
        // Cancel
        deleteConfirmation.buttons["Cancel"].tap()
        
        // Partial swipe left for action menu
        itemCell.swipeLeft(velocity: .slow)
        
        // Should show multiple actions
        XCTAssertTrue(app.buttons["Delete"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
        XCTAssertTrue(app.buttons["Duplicate"].exists)
        
        // Test duplicate action
        app.buttons["Duplicate"].tap()
        
        // Verify duplicate created
        let duplicateCells = app.cells.matching(NSPredicate(format: "label CONTAINS[c] 'Multi Action Test'"))
        XCTAssertEqual(duplicateCells.count, 2)
    }
    
    // MARK: - Advanced Swipe Gesture Tests
    
    func testSwipeVelocityDetection() throws {
        navigateToItemsList()
        createTestItem(name: "Velocity Test")
        
        let itemCell = app.cells["Velocity Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Slow swipe - should reveal actions
        itemCell.swipeLeft(velocity: .slow)
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 1))
        
        // Tap away to dismiss
        app.tap()
        
        // Fast swipe - should trigger immediate action
        itemCell.swipeLeft(velocity: .fast)
        
        // Should show quick delete confirmation
        XCTAssertTrue(app.alerts["Delete Item?"].waitForExistence(timeout: 2))
    }
    
    func testSwipeDistanceThresholds() throws {
        navigateToItemsList()
        createTestItem(name: "Distance Test")
        
        let itemCell = app.cells["Distance Test"]
        let startPoint = itemCell.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        
        // Test different swipe distances
        let swipeDistances: [(distance: CGFloat, expectedAction: String)] = [
            (0.1, "none"),      // Too short
            (0.3, "actions"),   // Show actions
            (0.7, "fullswipe") // Full swipe action
        ]
        
        for (distance, expected) in swipeDistances {
            let endPoint = itemCell.coordinate(withNormalizedOffset: CGVector(dx: 0.9 - distance, dy: 0.5))
            
            startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
            
            switch expected {
            case "none":
                // No actions should be visible
                XCTAssertFalse(app.buttons["Delete"].exists)
                
            case "actions":
                // Action buttons should be visible
                XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 1))
                app.tap() // Dismiss
                
            case "fullswipe":
                // Full swipe action triggered
                XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 1))
                app.alerts.buttons["Cancel"].tap()
                
            default:
                break
            }
            
            // Wait for animation
            sleep(1)
        }
    }
    
    func testSwipeGestureConflictResolution() throws {
        // Test swipe in scrollable list
        navigateToItemsList()
        
        // Create many items to enable scrolling
        for i in 0..<20 {
            createTestItem(name: "Scroll Test \(i)")
        }
        
        // Find middle item
        let targetItem = app.cells["Scroll Test 10"]
        
        // Scroll to make it visible
        app.swipeUp(velocity: .slow)
        app.swipeUp(velocity: .slow)
        
        XCTAssertTrue(targetItem.waitForExistence(timeout: 3))
        
        // Horizontal swipe should trigger action, not scroll
        targetItem.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        
        // Dismiss swipe action
        app.tap()
        
        // Vertical swipe should scroll
        let initialY = targetItem.frame.origin.y
        app.swipeUp()
        
        if targetItem.exists {
            let newY = targetItem.frame.origin.y
            XCTAssertLessThan(newY, initialY, "List should have scrolled up")
        }
    }
    
    // MARK: - Accessibility Swipe Tests
    
    func testSwipeActionsAccessibility() throws {
        // Enable VoiceOver mode simulation
        app.launchArguments.append("--voiceover-mode")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Accessibility Test")
        
        let itemCell = app.cells["Accessibility Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // With VoiceOver, swipe actions should be accessible via rotor
        itemCell.tap() // Focus on cell
        
        // Perform VoiceOver custom action gesture (swipe up/down)
        itemCell.swipeUp()
        
        // Should announce available actions
        let actionsMenu = app.otherElements["Actions"]
        XCTAssertTrue(actionsMenu.waitForExistence(timeout: 2))
        
        // Verify all actions have accessibility labels
        let deleteAction = app.buttons["Delete Item"]
        XCTAssertTrue(deleteAction.exists)
        XCTAssertNotNil(deleteAction.label)
        XCTAssertNotNil(deleteAction.accessibilityHint)
    }
    
    // MARK: - Swipe Customization Tests
    
    func testCustomSwipeActions() throws {
        navigateToItemsList()
        
        // Create item with specific category for custom actions
        createTestItem(name: "Custom Action Test", category: "Electronics")
        
        let itemCell = app.cells["Custom Action Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Electronics items should have warranty action
        itemCell.swipeLeft()
        
        XCTAssertTrue(app.buttons["Warranty"].waitForExistence(timeout: 2))
        app.buttons["Warranty"].tap()
        
        // Verify warranty view appears
        XCTAssertTrue(app.navigationBars["Warranty Information"].waitForExistence(timeout: 3))
    }
    
    func testContextualSwipeActions() throws {
        navigateToItemsList()
        
        // Create items with different states
        createTestItem(name: "Active Item", value: 100)
        createTestItem(name: "Archived Item", archived: true)
        
        // Test active item actions
        let activeCell = app.cells["Active Item"]
        activeCell.swipeLeft()
        
        XCTAssertTrue(app.buttons["Archive"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)
        
        app.tap() // Dismiss
        
        // Switch to archived view
        app.buttons["Filter"].tap()
        app.buttons["Show Archived"].tap()
        
        // Test archived item actions
        let archivedCell = app.cells["Archived Item"]
        archivedCell.swipeLeft()
        
        XCTAssertTrue(app.buttons["Unarchive"].exists)
        XCTAssertTrue(app.buttons["Delete Permanently"].exists)
    }
    
    // MARK: - Swipe Animation Tests
    
    func testSwipeAnimationSmoothing() throws {
        navigateToItemsList()
        createTestItem(name: "Animation Test")
        
        let itemCell = app.cells["Animation Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Record animation performance
        let metrics = XCTOSSignpostMetric.applicationLaunch
        
        measure(metrics: [metrics]) {
            // Perform multiple swipes
            for _ in 0..<5 {
                itemCell.swipeLeft()
                sleep(1)
                app.tap() // Dismiss
                sleep(1)
            }
        }
    }
    
    func testSwipeRubberBandEffect() throws {
        navigateToItemsList()
        createTestItem(name: "Rubber Band Test")
        
        let itemCell = app.cells["Rubber Band Test"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        
        // Swipe beyond maximum distance
        let startPoint = itemCell.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let endPoint = itemCell.coordinate(withNormalizedOffset: CGVector(dx: -0.5, dy: 0.5))
        
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint, withVelocity: .slow)
        
        // Should bounce back to maximum swipe distance
        sleep(1)
        
        // Verify actions are still visible at correct position
        XCTAssertTrue(app.buttons["Delete"].exists)
        
        let deleteFrame = app.buttons["Delete"].frame
        XCTAssertTrue(deleteFrame.origin.x > itemCell.frame.origin.x + itemCell.frame.width * 0.5)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToItemsList() {
        // Assuming main screen shows items list or has navigation
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
        }
    }
    
    private func createTestItem(name: String, value: Double = 100, category: String = "General", archived: Bool = false) {
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
        
        if archived {
            app.switches["Archived"].tap()
        }
        
        app.buttons["Save"].tap()
        
        // Wait for list to update
        sleep(1)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    enum SwipeVelocity {
        case slow
        case normal
        case fast
        
        var duration: TimeInterval {
            switch self {
            case .slow: return 1.0
            case .normal: return 0.5
            case .fast: return 0.1
            }
        }
    }
    
    func swipeLeft(velocity: SwipeVelocity = .normal) {
        let startPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let endPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        startPoint.press(forDuration: 0.05, thenDragTo: endPoint, withVelocity: velocity.xcTestVelocity)
    }
    
    func swipeRight(velocity: SwipeVelocity = .normal) {
        let startPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let endPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        startPoint.press(forDuration: 0.05, thenDragTo: endPoint, withVelocity: velocity.xcTestVelocity)
    }
    
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String else {
            typeText(text)
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}

extension XCUIElement.SwipeVelocity {
    var xcTestVelocity: XCUIGestureVelocity {
        switch self {
        case .slow: return XCUIGestureVelocity(100)
        case .normal: return XCUIGestureVelocity.default
        case .fast: return XCUIGestureVelocity(1000)
        }
    }
}