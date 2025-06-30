//
//  UITestHelpers.swift
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
//  Description: Helper utilities and extensions for UI testing
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest

// MARK: - Snapshot Helper Functions
func setupSnapshot(_ app: XCUIApplication) {
    // Setup for Fastlane snapshot
    app.launchArguments += ["-AppleLanguages", "(en)"]
    app.launchArguments += ["-AppleLocale", "en_US"]
    app.launchArguments += ["FASTLANE_SNAPSHOT"]
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    if waitForLoadingIndicator {
        // Wait for any loading indicators to disappear
        sleep(1)
    }
    
    // Take a screenshot using XCTest
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
        activity.add(attachment)
    }
}

// MARK: - Accessibility Identifiers
enum AccessibilityIdentifiers {
    enum TabBar {
        static let items = "tab_items"
        static let scanner = "tab_scanner"
        static let receipts = "tab_receipts"
        static let analytics = "tab_analytics"
        static let settings = "tab_settings"
    }
    
    enum Navigation {
        static let addButton = "nav_add_button"
        static let backButton = "nav_back_button"
        static let cancelButton = "nav_cancel_button"
        static let saveButton = "nav_save_button"
    }
    
    enum Settings {
        static let categoriesCell = "settings_categories"
        static let locationsCell = "settings_locations"
        static let dataStorageCell = "settings_data_storage"
        static let premiumCell = "settings_premium"
        static let appearanceCell = "settings_appearance"
        static let notificationsCell = "settings_notifications"
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    /// Wait for element to exist and be hittable
    func waitForExistenceAndTap(timeout: TimeInterval = 5) -> Bool {
        if waitForExistence(timeout: timeout) && isHittable {
            tap()
            return true
        }
        return false
    }
    
    /// Clear text field and type new text
    func clearAndType(_ text: String) {
        guard exists else { return }
        tap()
        
        // Select all and delete
        if let stringValue = value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(deleteString)
        }
        
        typeText(text)
    }
}

// MARK: - Screenshot Helpers
extension XCTestCase {
    /// Take a screenshot with proper naming and organization
    func takeScreenshot(named name: String, waitTime: TimeInterval = 0.5) {
        // Allow UI to settle
        Thread.sleep(forTimeInterval: waitTime)
        
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also use snapshot for Fastlane
        snapshot(name, waitForLoadingIndicator: false)
    }
    
    /// Navigate to a tab and wait for it to load
    func navigateToTab(_ tabIdentifier: String, in app: XCUIApplication) {
        let tabButton = app.tabBars.buttons[tabIdentifier]
        if tabButton.waitForExistenceAndTap() {
            Thread.sleep(forTimeInterval: 1) // Allow tab content to load
        }
    }
}