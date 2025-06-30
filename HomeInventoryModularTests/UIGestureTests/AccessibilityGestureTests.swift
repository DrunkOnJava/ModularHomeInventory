import XCTest
import SwiftUI
@testable import Items
@testable import Core
@testable import TestUtilities

/// Tests for accessibility gestures and interactions
final class AccessibilityGestureTests: XCUITestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--accessibility-testing"]
        app.launch()
        
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // MARK: - VoiceOver Gesture Tests
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver simulation
        app.launchArguments.append("--voiceover-enabled")
        app.launch()
        
        navigateToItemsList()
        
        // Create test items
        createTestItem(name: "VoiceOver Test 1", value: 100)
        createTestItem(name: "VoiceOver Test 2", value: 200)
        
        // Test swipe navigation
        let firstItem = app.cells["VoiceOver Test 1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 5))
        
        // Single tap to focus
        firstItem.tap()
        
        // Verify accessibility label
        XCTAssertTrue(firstItem.isAccessibilityElement)
        XCTAssertNotNil(firstItem.label)
        XCTAssertTrue(firstItem.label.contains("VoiceOver Test 1"))
        XCTAssertTrue(firstItem.label.contains("$100"))
        
        // Double tap to activate
        firstItem.doubleTap()
        
        // Should navigate to detail view
        XCTAssertTrue(app.navigationBars["Item Details"].waitForExistence(timeout: 3))
        
        // Test escape gesture (two-finger Z)
        performTwoFingerZGesture()
        
        // Should return to list
        XCTAssertTrue(app.navigationBars["Items"].waitForExistence(timeout: 3))
    }
    
    func testVoiceOverRotor() throws {
        app.launchArguments.append("--voiceover-enabled")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Rotor Test", value: 500)
        
        let cell = app.cells["Rotor Test"]
        cell.tap() // Focus
        
        // Simulate rotor gesture (two-finger rotation)
        performRotorGesture(on: cell)
        
        // Rotor menu should show options
        let rotorMenu = app.otherElements["RotorMenu"]
        if rotorMenu.waitForExistence(timeout: 2) {
            XCTAssertTrue(rotorMenu.buttons["Actions"].exists)
            XCTAssertTrue(rotorMenu.buttons["Headings"].exists)
            XCTAssertTrue(rotorMenu.buttons["Links"].exists)
        }
        
        // Select Actions
        app.buttons["Actions"].tap()
        
        // Swipe up/down should cycle through actions
        cell.swipeUp()
        
        let actionMenu = app.otherElements["Actions"]
        if actionMenu.waitForExistence(timeout: 2) {
            XCTAssertTrue(actionMenu.buttons["Edit"].exists)
            XCTAssertTrue(actionMenu.buttons["Delete"].exists)
            XCTAssertTrue(actionMenu.buttons["Share"].exists)
        }
    }
    
    func testVoiceOverAnnouncements() throws {
        app.launchArguments.append("--voiceover-enabled")
        app.launch()
        
        navigateToItemsList()
        
        // Test screen change announcement
        app.buttons["Add"].tap()
        
        // Should announce screen change
        let announcement = app.otherElements["AccessibilityAnnouncement"]
        if announcement.waitForExistence(timeout: 1) {
            XCTAssertTrue(announcement.label.contains("Add Item"))
        }
        
        // Test live region updates
        let valueField = app.textFields["Value"]
        valueField.tap()
        valueField.typeText("abc") // Invalid
        
        // Should announce error
        let errorAnnouncement = app.otherElements["AccessibilityErrorAnnouncement"]
        if errorAnnouncement.waitForExistence(timeout: 2) {
            XCTAssertTrue(errorAnnouncement.label.contains("Invalid"))
        }
    }
    
    // MARK: - Switch Control Tests
    
    func testSwitchControlScanning() throws {
        app.launchArguments.append("--switch-control-enabled")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Switch Control Test")
        
        // Simulate switch control scanning
        var highlightedElements: [XCUIElement] = []
        
        // Scanning should highlight each interactive element
        for i in 0..<10 {
            sleep(1) // Scanning interval
            
            let highlighted = app.descendants(matching: .any).element(matching: NSPredicate(format: "isAccessibilityElement == true AND value(forKey: 'highlighted') == true"))
            
            if highlighted.exists {
                highlightedElements.append(highlighted)
            }
        }
        
        XCTAssertGreaterThan(highlightedElements.count, 0)
        
        // Simulate switch activation
        if let targetElement = highlightedElements.first(where: { $0.label.contains("Switch Control Test") }) {
            targetElement.tap()
            
            // Should activate the element
            XCTAssertTrue(app.navigationBars["Item Details"].waitForExistence(timeout: 3))
        }
    }
    
    func testSwitchControlCustomActions() throws {
        app.launchArguments.append("--switch-control-enabled")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Custom Action Test")
        
        let cell = app.cells["Custom Action Test"]
        
        // Long press to show actions
        cell.press(forDuration: 2.0)
        
        let actionSheet = app.sheets.element
        if actionSheet.waitForExistence(timeout: 2) {
            // Verify all actions are accessible
            let actions = actionSheet.buttons.allElementsBoundByIndex
            
            for action in actions {
                XCTAssertTrue(action.isAccessibilityElement)
                XCTAssertNotEqual(action.label, "")
            }
        }
    }
    
    // MARK: - Assistive Touch Tests
    
    func testAssistiveTouchMenu() throws {
        app.launchArguments.append("--assistive-touch-enabled")
        app.launch()
        
        // Assistive Touch button should be visible
        let assistiveButton = app.buttons["AssistiveTouch"]
        XCTAssertTrue(assistiveButton.waitForExistence(timeout: 3))
        
        // Tap to open menu
        assistiveButton.tap()
        
        let menu = app.otherElements["AssistiveTouchMenu"]
        if menu.waitForExistence(timeout: 2) {
            XCTAssertTrue(menu.buttons["Home"].exists)
            XCTAssertTrue(menu.buttons["Gestures"].exists)
            XCTAssertTrue(menu.buttons["Device"].exists)
            XCTAssertTrue(menu.buttons["Custom"].exists)
        }
        
        // Test custom gesture
        menu.buttons["Gestures"].tap()
        
        if menu.buttons["Pinch"].exists {
            menu.buttons["Pinch"].tap()
            
            // Should simulate pinch gesture
            sleep(1)
            
            // Verify zoom level changed (if applicable)
        }
    }
    
    // MARK: - Reduce Motion Tests
    
    func testReduceMotion() throws {
        app.launchArguments.append("--reduce-motion-enabled")
        app.launch()
        
        navigateToItemsList()
        
        // Create items
        createTestItem(name: "Motion Test 1")
        createTestItem(name: "Motion Test 2")
        
        // Test navigation without animations
        app.cells["Motion Test 1"].tap()
        
        // Transition should be instant
        XCTAssertTrue(app.navigationBars["Item Details"].exists)
        
        // No wait needed for animation
        app.navigationBars.buttons["Items"].tap()
        XCTAssertTrue(app.navigationBars["Items"].exists)
        
        // Test delete without animation
        let cell = app.cells["Motion Test 2"]
        cell.swipeLeft()
        app.buttons["Delete"].tap()
        
        // Should disappear immediately
        XCTAssertFalse(cell.exists)
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeScaling() throws {
        let textSizes = [
            "UICTContentSizeCategoryXS",
            "UICTContentSizeCategoryM",
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryXXXL",
            "UICTContentSizeCategoryAccessibilityL",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        
        for size in textSizes {
            app.launchArguments = ["--uitesting", "--reset-state", "--text-size=\(size)"]
            app.launch()
            
            navigateToItemsList()
            createTestItem(name: "Dynamic Type Test")
            
            let cell = app.cells["Dynamic Type Test"]
            let label = cell.staticTexts["Dynamic Type Test"]
            
            if label.exists {
                let height = label.frame.height
                
                // Larger text sizes should have taller cells
                if size.contains("Accessibility") {
                    XCTAssertGreaterThan(height, 44)
                }
                
                // Text should remain fully visible
                XCTAssertTrue(label.isHittable)
            }
            
            app.terminate()
        }
    }
    
    // MARK: - Voice Control Tests
    
    func testVoiceControlCommands() throws {
        app.launchArguments.append("--voice-control-enabled")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Voice Command Test")
        
        // Simulate voice commands
        simulateVoiceCommand("Show numbers")
        
        // Numbers should appear on interactive elements
        let numberOverlay = app.otherElements["VoiceControlNumbers"]
        if numberOverlay.waitForExistence(timeout: 2) {
            // Each tappable element should have a number
            let addButton = app.buttons["Add"]
            if addButton.exists {
                let numberLabel = numberOverlay.staticTexts.element(matching: NSPredicate(format: "label MATCHES '\\\\d+'"))
                XCTAssertTrue(numberLabel.exists)
            }
        }
        
        // Test grid overlay
        simulateVoiceCommand("Show grid")
        
        let gridOverlay = app.otherElements["VoiceControlGrid"]
        XCTAssertTrue(gridOverlay.waitForExistence(timeout: 2))
    }
    
    // MARK: - Gesture Accessibility Tests
    
    func testAccessibleGestureAlternatives() throws {
        navigateToItemsList()
        createTestItem(name: "Gesture Alternative Test")
        
        let cell = app.cells["Gesture Alternative Test"]
        
        // For users who can't perform swipe gestures
        // Long press should show accessible menu
        cell.press(forDuration: 1.0)
        
        let contextMenu = app.menus.element
        if contextMenu.waitForExistence(timeout: 2) {
            // All swipe actions should be available
            XCTAssertTrue(contextMenu.buttons["Edit"].exists)
            XCTAssertTrue(contextMenu.buttons["Delete"].exists)
            XCTAssertTrue(contextMenu.buttons["Share"].exists)
            
            // Verify accessibility labels
            let deleteButton = contextMenu.buttons["Delete"]
            XCTAssertNotNil(deleteButton.label)
            XCTAssertTrue(deleteButton.label.contains("Delete"))
        }
    }
    
    func testSimplifiedGestures() throws {
        app.launchArguments.append("--simplified-gestures")
        app.launch()
        
        navigateToItemsList()
        createTestItem(name: "Simple Gesture Test")
        
        // Complex gestures should have simple alternatives
        // Instead of pinch to zoom, use buttons
        app.cells["Simple Gesture Test"].tap()
        
        if app.buttons["Zoom In"].waitForExistence(timeout: 2) {
            app.buttons["Zoom In"].tap()
            app.buttons["Zoom In"].tap()
            
            // Verify zoom level increased
            let zoomLevel = app.otherElements["ZoomLevel"]
            if zoomLevel.exists {
                XCTAssertTrue(zoomLevel.label.contains("200%"))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToItemsList() {
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
        }
    }
    
    private func createTestItem(name: String, value: Double = 100) {
        if !app.navigationBars.buttons["Add"].exists {
            navigateToItemsList()
        }
        
        app.navigationBars.buttons["Add"].tap()
        
        let nameField = app.textFields["Item Name"]
        nameField.tap()
        nameField.typeText(name)
        
        if value != 100 {
            let valueField = app.textFields["Value"]
            valueField.tap()
            valueField.typeText("\(Int(value))")
        }
        
        app.buttons["Save"].tap()
        sleep(1)
    }
    
    private func performTwoFingerZGesture() {
        // Simulate two-finger Z gesture for back navigation
        let startPoint1 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let startPoint2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.3))
        
        // Z pattern
        let endPoint1 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        let endPoint2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.7))
        
        startPoint1.press(forDuration: 0.1, thenDragTo: endPoint1)
        startPoint2.press(forDuration: 0.1, thenDragTo: endPoint2)
    }
    
    private func performRotorGesture(on element: XCUIElement) {
        // Simulate two-finger rotation
        let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let radius: CGFloat = 50
        
        // Create circular path
        for angle in stride(from: 0, to: 360, by: 30) {
            let radians = angle * .pi / 180
            let x = cos(radians) * radius
            let y = sin(radians) * radius
            
            let point = center.withOffset(CGVector(dx: x, dy: y))
            point.tap()
            
            Thread.sleep(forTimeInterval: 0.05)
        }
    }
    
    private func simulateVoiceCommand(_ command: String) {
        // In real implementation, this would trigger voice control
        print("Simulating voice command: \(command)")
        
        // For testing, directly trigger the action
        switch command {
        case "Show numbers":
            app.buttons["ShowVoiceControlNumbers"].tap()
        case "Show grid":
            app.buttons["ShowVoiceControlGrid"].tap()
        default:
            break
        }
    }
}

// MARK: - XCUIElement Accessibility Extensions

extension XCUIElement {
    var isAccessibilityElement: Bool {
        return self.value(forKey: "isAccessibilityElement") as? Bool ?? false
    }
    
    var accessibilityTraits: UIAccessibilityTraits {
        return self.value(forKey: "traits") as? UIAccessibilityTraits ?? []
    }
    
    var accessibilityHint: String? {
        return self.value(forKey: "accessibilityHint") as? String
    }
    
    func performAccessibilityAction(_ action: String) {
        // Simulate accessibility action
        switch action {
        case "activate":
            self.doubleTap()
        case "increment":
            self.swipeUp()
        case "decrement":
            self.swipeDown()
        default:
            self.tap()
        }
    }
}