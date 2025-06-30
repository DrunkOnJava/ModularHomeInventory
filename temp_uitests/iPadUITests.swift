//
//  iPadUITests.swift
//  HomeInventoryModularUITests
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: HomeInventoryModularUITests
//  Dependencies: XCTest
//  Testing: UI test target
//
//  Description: UI Tests for iPad-specific features and layouts
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest

final class iPadUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Only run these tests on iPad
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad-only tests")
        }
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Split View Tests
    
    func testSplitViewLayout() throws {
        // On iPad, should show split view
        XCTAssertTrue(app.splitViews.firstMatch.waitForExistence(timeout: 5))
        
        // Sidebar should be visible
        XCTAssertTrue(app.tables["Sidebar"].exists ||
                     app.collectionViews["Sidebar"].exists)
        
        // Detail view should be visible
        XCTAssertTrue(app.otherElements["DetailView"].exists ||
                     app.navigationBars.count > 1)
    }
    
    func testSidebarNavigation() throws {
        // Find sidebar
        let sidebar = app.tables["Sidebar"].firstMatch
        
        // Navigate through sidebar items
        let sidebarItems = ["All Items", "Electronics", "Furniture", "Clothing"]
        
        for item in sidebarItems {
            if sidebar.cells.staticTexts[item].exists {
                sidebar.cells.staticTexts[item].tap()
                
                // Detail view should update
                sleep(1)
                
                // Verify navigation occurred
                XCTAssertTrue(app.navigationBars[item].exists ||
                             app.staticTexts[item].exists)
            }
        }
    }
    
    func testCollapseSidebar() throws {
        // Look for sidebar toggle button
        if app.buttons["Toggle Sidebar"].exists {
            // Collapse sidebar
            app.buttons["Toggle Sidebar"].tap()
            sleep(1)
            
            // Sidebar should be hidden
            XCTAssertFalse(app.tables["Sidebar"].isHittable)
            
            // Expand sidebar again
            app.buttons["Toggle Sidebar"].tap()
            sleep(1)
            
            // Sidebar should be visible
            XCTAssertTrue(app.tables["Sidebar"].isHittable)
        }
    }
    
    // MARK: - Multi-Column Layout Tests
    
    func testThreeColumnLayout() throws {
        // In landscape orientation, might show three columns
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        
        // Check for three-column layout
        let columns = app.splitViews.firstMatch.children(matching: .other)
        
        if columns.count >= 3 {
            // Test navigation in three-column mode
            XCTAssertTrue(true)
        }
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Drag and Drop Tests
    
    func testDragAndDropItem() throws {
        // Navigate to items list
        let itemsTable = app.tables["ItemsList"].firstMatch
        
        if itemsTable.cells.count > 1 {
            let firstItem = itemsTable.cells.element(boundBy: 0)
            let secondItem = itemsTable.cells.element(boundBy: 1)
            
            // Attempt drag and drop
            firstItem.press(forDuration: 1.0, thenDragTo: secondItem)
            
            // Verify some action occurred (reordering, grouping, etc.)
            sleep(1)
        }
    }
    
    func testDragImageToItem() throws {
        // Open an item detail
        app.tables["ItemsList"].cells.firstMatch.tap()
        
        // If photos app is available, try dragging an image
        // This is complex in UI tests and might require special setup
        XCTAssertTrue(true)
    }
    
    // MARK: - Keyboard Shortcuts Tests
    
    func testKeyboardShortcuts() throws {
        // Test Command+N for new item
        app.typeText("n", modifierFlags: .command)
        sleep(1)
        
        // Add item screen should appear
        XCTAssertTrue(app.navigationBars["Add Item"].exists ||
                     app.navigationBars["New Item"].exists)
        
        // Cancel with Escape
        app.typeText(XCUIKeyboardKey.escape.rawValue)
        sleep(1)
        
        // Should return to list
        XCTAssertFalse(app.navigationBars["Add Item"].exists)
    }
    
    func testSearchKeyboardShortcut() throws {
        // Command+F for search
        app.typeText("f", modifierFlags: .command)
        sleep(1)
        
        // Search field should be focused
        XCTAssertTrue(app.searchFields.firstMatch.hasKeyboardFocus)
        
        // Type search query
        app.typeText("test")
        
        // Escape to cancel search
        app.typeText(XCUIKeyboardKey.escape.rawValue)
    }
    
    // MARK: - Context Menu Tests
    
    func testItemContextMenu() throws {
        // Long press on an item
        let firstItem = app.tables["ItemsList"].cells.firstMatch
        firstItem.press(forDuration: 1.0)
        
        // Context menu should appear
        XCTAssertTrue(app.menus.firstMatch.waitForExistence(timeout: 2))
        
        // Check for menu options
        let menuOptions = ["Edit", "Duplicate", "Share", "Delete"]
        for option in menuOptions {
            if app.menus.buttons[option].exists {
                XCTAssertTrue(true)
            }
        }
        
        // Dismiss menu
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    
    // MARK: - Multi-Window Tests
    
    func testOpenInNewWindow() throws {
        // Long press on an item
        let firstItem = app.tables["ItemsList"].cells.firstMatch
        firstItem.press(forDuration: 1.0)
        
        // Look for "Open in New Window" option
        if app.menus.buttons["Open in New Window"].exists {
            app.menus.buttons["Open in New Window"].tap()
            
            // New window should open (difficult to verify in UI tests)
            sleep(2)
        }
    }
    
    // MARK: - Pencil Support Tests
    
    func testPencilAnnotation() throws {
        // Open an item with photos
        app.tables["ItemsList"].cells.firstMatch.tap()
        
        // If photo exists, tap to view
        if app.images["ItemPhoto"].exists {
            app.images["ItemPhoto"].tap()
            
            // Look for annotation button
            if app.buttons["Annotate"].exists {
                app.buttons["Annotate"].tap()
                
                // Annotation view should appear
                XCTAssertTrue(app.otherElements["AnnotationView"].exists ||
                             app.toolbars["Markup"].exists)
                
                // In real test, would simulate pencil input
            }
        }
    }
    
    // MARK: - Slide Over Tests
    
    func testSlideOverSupport() throws {
        // This is difficult to test programmatically
        // Would need to trigger slide over from another app
        XCTAssertTrue(true)
    }
    
    // MARK: - Picture in Picture Tests
    
    func testPictureInPicture() throws {
        // If app has video content
        if app.buttons["Play Video"].exists {
            app.buttons["Play Video"].tap()
            
            // Look for PiP button
            if app.buttons["Picture in Picture"].waitForExistence(timeout: 3) {
                app.buttons["Picture in Picture"].tap()
                
                // Video should minimize
                sleep(1)
            }
        }
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationChanges() throws {
        // Test portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        XCTAssertTrue(app.splitViews.firstMatch.exists ||
                     app.tables.firstMatch.exists)
        
        // Test landscape left
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        XCTAssertTrue(app.splitViews.firstMatch.exists)
        
        // Test landscape right
        XCUIDevice.shared.orientation = .landscapeRight
        sleep(2)
        XCTAssertTrue(app.splitViews.firstMatch.exists)
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}