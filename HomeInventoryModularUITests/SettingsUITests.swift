//
//  SettingsUITests.swift
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
//  Description: UI Tests for settings and configuration screens
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest

final class SettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToSettings() throws {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        
        // Verify settings screen appears
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        // Check for profile header
        XCTAssertTrue(app.images["ProfilePhoto"].exists ||
                     app.buttons["ProfilePhoto"].exists ||
                     app.staticTexts["Guest User"].exists)
    }
    
    // MARK: - Profile Tests
    
    func testEditProfile() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Tap on profile section
        let profileSection = app.cells["ProfileCell"].firstMatch
        if profileSection.waitForExistence(timeout: 3) {
            profileSection.tap()
        } else if app.buttons["Edit Profile"].exists {
            app.buttons["Edit Profile"].tap()
        }
        
        // Edit profile screen should appear
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 3) ||
                     app.navigationBars["Profile"].waitForExistence(timeout: 3))
        
        // Edit name
        let nameField = app.textFields["Name"]
        if nameField.exists {
            nameField.tap()
            nameField.clearText()
            nameField.typeText("Test User")
        }
        
        // Edit email
        let emailField = app.textFields["Email"]
        if emailField.exists {
            emailField.tap()
            emailField.clearText()
            emailField.typeText("test@example.com")
        }
        
        // Save changes
        app.navigationBars.buttons["Save"].tap()
        
        // Verify changes saved
        XCTAssertTrue(app.staticTexts["Test User"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Category Management Tests
    
    func testManageCategories() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Categories
        let categoriesCell = app.tables.cells.staticTexts["Categories"]
        categoriesCell.tap()
        
        // Categories screen should appear
        XCTAssertTrue(app.navigationBars["Categories"].waitForExistence(timeout: 3))
        
        // Test adding a category
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            
            // Fill in category details
            let nameField = app.textFields["Category Name"]
            nameField.tap()
            nameField.typeText("Test Category")
            
            // Select icon if available
            if app.buttons["Select Icon"].exists {
                app.buttons["Select Icon"].tap()
                app.collectionViews.cells.element(boundBy: 0).tap()
            }
            
            // Save
            app.buttons["Save"].tap()
            
            // Verify category added
            XCTAssertTrue(app.tables.cells.staticTexts["Test Category"].waitForExistence(timeout: 3))
        }
    }
    
    func testEditCategory() throws {
        // Navigate to Categories
        app.tabBars.buttons["Settings"].tap()
        app.tables.cells.staticTexts["Categories"].tap()
        
        // Select a category to edit
        let electronicsCell = app.tables.cells.staticTexts["Electronics"]
        if electronicsCell.waitForExistence(timeout: 3) {
            electronicsCell.tap()
            
            // Edit screen should appear
            XCTAssertTrue(app.navigationBars["Edit Category"].exists ||
                         app.textFields["Category Name"].exists)
        }
    }
    
    // MARK: - Location Management Tests
    
    func testManageLocations() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Locations
        let locationsCell = app.tables.cells.staticTexts["Locations"]
        locationsCell.tap()
        
        // Locations screen should appear
        XCTAssertTrue(app.navigationBars["Locations"].waitForExistence(timeout: 3))
        
        // Add a location
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            
            let nameField = app.textFields["Location Name"]
            nameField.tap()
            nameField.typeText("Test Room")
            
            app.buttons["Save"].tap()
            
            // Verify location added
            XCTAssertTrue(app.tables.cells.staticTexts["Test Room"].waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Notification Settings Tests
    
    func testNotificationSettings() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Notifications
        let notificationsCell = app.tables.cells.staticTexts["Notifications"]
        notificationsCell.tap()
        
        // Notification settings should appear
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 3))
        
        // Toggle notification switches
        let switches = [
            "Warranty Alerts",
            "Price Drops",
            "Maintenance Reminders"
        ]
        
        for switchName in switches {
            if app.switches[switchName].exists {
                app.switches[switchName].tap()
                // Verify state changed
                XCTAssertTrue(app.switches[switchName].isSelected != app.switches[switchName].isSelected)
            }
        }
        
        // Test quiet hours
        if app.switches["Quiet Hours"].exists {
            app.switches["Quiet Hours"].tap()
            
            // Time pickers should appear
            XCTAssertTrue(app.datePickers["Start Time"].exists ||
                         app.buttons["Start Time"].exists)
        }
    }
    
    // MARK: - Privacy Settings Tests
    
    func testPrivacySettings() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Privacy
        let privacyCell = app.tables.cells.staticTexts["Privacy"]
        privacyCell.tap()
        
        // Privacy settings should appear
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 3))
        
        // Check biometric authentication toggle
        if app.switches["Use Face ID"].exists || app.switches["Use Touch ID"].exists {
            let biometricSwitch = app.switches["Use Face ID"].exists ? app.switches["Use Face ID"] : app.switches["Use Touch ID"]
            biometricSwitch.tap()
            
            // Might show authentication prompt
            if app.alerts.element.exists {
                app.alerts.buttons["OK"].tap()
            }
        }
    }
    
    // MARK: - Data Management Tests
    
    func testDataExport() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find and tap Data & Storage
        let dataCell = app.tables.cells.staticTexts["Data & Storage"]
        dataCell.tap()
        
        // Export options should be available
        if app.buttons["Export Data"].exists {
            app.buttons["Export Data"].tap()
            
            // Export options should appear
            XCTAssertTrue(app.sheets.element.exists ||
                         app.navigationBars["Export Data"].exists)
            
            // Select CSV if available
            if app.buttons["Export as CSV"].exists {
                app.buttons["Export as CSV"].tap()
                
                // Share sheet should appear
                XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 3) ||
                             app.sheets.element.waitForExistence(timeout: 3))
                
                // Cancel share
                app.buttons["Cancel"].tap()
            }
        }
    }
    
    func testDataBackup() throws {
        // Navigate to Data & Storage
        app.tabBars.buttons["Settings"].tap()
        app.tables.cells.staticTexts["Data & Storage"].tap()
        
        // Check backup options
        if app.cells.staticTexts["iCloud Backup"].exists {
            // Verify backup status shown
            XCTAssertTrue(app.staticTexts["Last backup:"].exists ||
                         app.staticTexts["Never backed up"].exists)
            
            // Trigger manual backup
            if app.buttons["Back Up Now"].exists {
                app.buttons["Back Up Now"].tap()
                
                // Should show progress
                XCTAssertTrue(app.activityIndicators.element.exists ||
                             app.progressIndicators.element.exists ||
                             app.staticTexts["Backing up..."].exists)
            }
        }
    }
    
    // MARK: - About Section Tests
    
    func testAboutSection() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Scroll to bottom for About section
        app.tables.firstMatch.swipeUp()
        
        // Tap About
        if app.tables.cells.staticTexts["About"].exists {
            app.tables.cells.staticTexts["About"].tap()
            
            // About screen should show app info
            XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["Home Inventory"].exists)
            XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'Version'")).exists)
        }
    }
    
    // MARK: - Premium Features Tests
    
    func testPremiumSettings() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Look for Premium option
        if app.tables.cells.staticTexts["Premium"].exists {
            app.tables.cells.staticTexts["Premium"].tap()
            
            // Premium screen should appear
            XCTAssertTrue(app.navigationBars["Premium"].waitForExistence(timeout: 3) ||
                         app.navigationBars["Home Inventory Pro"].waitForExistence(timeout: 3))
            
            // Should show premium features
            XCTAssertTrue(app.staticTexts["Unlimited Items"].exists ||
                         app.staticTexts["Premium Features"].exists)
            
            // Purchase button should exist
            XCTAssertTrue(app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Subscribe'")).exists ||
                         app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Upgrade'")).exists)
        }
    }
}