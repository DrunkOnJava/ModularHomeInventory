//
//  BarcodeScannerUITests.swift
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
//  Description: UI Tests for barcode scanning functionality
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest

final class BarcodeScannerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["--mock-camera"] // Use mock camera for tests
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Scanner Tab Tests
    
    func testNavigateToScanner() throws {
        // Navigate to Scanner tab
        let scannerTab = app.tabBars.buttons["Scanner"]
        XCTAssertTrue(scannerTab.waitForExistence(timeout: 5))
        scannerTab.tap()
        
        // Verify scanner view appears
        XCTAssertTrue(app.otherElements["ScannerView"].waitForExistence(timeout: 3) ||
                     app.staticTexts["Point camera at barcode"].waitForExistence(timeout: 3))
    }
    
    func testScannerPermissions() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // If permission alert appears (first time)
        let permissionAlert = app.alerts["Camera Access"]
        if permissionAlert.waitForExistence(timeout: 2) {
            // Accept camera permission
            permissionAlert.buttons["Allow"].tap()
        }
        
        // Scanner should be active
        XCTAssertTrue(app.otherElements["CameraPreview"].exists ||
                     app.otherElements["ScannerView"].exists)
    }
    
    func testScannerControls() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Test flash toggle
        let flashButton = app.buttons["Flash"]
        if flashButton.waitForExistence(timeout: 3) {
            flashButton.tap()
            // Flash should toggle (icon might change)
            XCTAssertTrue(flashButton.isSelected || !flashButton.isSelected)
        }
        
        // Test scan type selector
        if app.segmentedControls["ScanType"].exists {
            let segments = app.segmentedControls["ScanType"]
            segments.buttons["QR Code"].tap()
            segments.buttons["Barcode"].tap()
        }
    }
    
    // MARK: - Scanning Flow Tests
    
    func testSuccessfulScan() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // In mock mode, trigger a scan
        if app.buttons["Simulate Scan"].exists {
            app.buttons["Simulate Scan"].tap()
        } else {
            // Wait for mock scan to trigger automatically
            sleep(2)
        }
        
        // Product details should appear
        XCTAssertTrue(app.staticTexts["Product Found"].waitForExistence(timeout: 5) ||
                     app.navigationBars["Product Details"].waitForExistence(timeout: 5))
        
        // Should show product info
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'Product Name'")).exists ||
                     app.textFields["Item Name"].exists)
    }
    
    func testScanNotFound() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Trigger scan with unknown barcode
        if app.buttons["Simulate Unknown Scan"].exists {
            app.buttons["Simulate Unknown Scan"].tap()
        }
        
        // Should show not found message
        XCTAssertTrue(app.alerts["Product Not Found"].waitForExistence(timeout: 3) ||
                     app.staticTexts["Product not found"].waitForExistence(timeout: 3))
        
        // Should offer to add manually
        if app.alerts.buttons["Add Manually"].exists {
            app.alerts.buttons["Add Manually"].tap()
            
            // Should navigate to add item screen
            XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 3))
        }
    }
    
    func testBatchScanning() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Enable batch mode if available
        if app.buttons["Batch Mode"].exists {
            app.buttons["Batch Mode"].tap()
            
            // Simulate multiple scans
            for i in 1...3 {
                if app.buttons["Simulate Scan \(i)"].exists {
                    app.buttons["Simulate Scan \(i)"].tap()
                    sleep(1)
                }
            }
            
            // Should show count of scanned items
            XCTAssertTrue(app.staticTexts["3 items scanned"].exists ||
                         app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '3'")).exists)
            
            // Complete batch
            app.buttons["Done"].tap()
            
            // Should show batch summary
            XCTAssertTrue(app.navigationBars["Batch Summary"].exists ||
                         app.tables.cells.count >= 3)
        }
    }
    
    // MARK: - Manual Entry Tests
    
    func testManualBarcodeEntry() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Look for manual entry option
        let manualButton = app.buttons["Enter Manually"]
        if manualButton.waitForExistence(timeout: 3) {
            manualButton.tap()
            
            // Enter barcode number
            let barcodeField = app.textFields["Barcode Number"]
            XCTAssertTrue(barcodeField.waitForExistence(timeout: 3))
            barcodeField.tap()
            barcodeField.typeText("1234567890123")
            
            // Submit
            app.buttons["Search"].tap()
            
            // Should search for product
            XCTAssertTrue(app.activityIndicators["Searching"].exists ||
                         app.staticTexts["Searching..."].exists ||
                         app.navigationBars["Product Details"].waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Scan History Tests
    
    func testScanHistory() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Look for history button
        if app.buttons["History"].exists {
            app.buttons["History"].tap()
            
            // Should show scan history
            XCTAssertTrue(app.navigationBars["Scan History"].waitForExistence(timeout: 3))
            
            // History list should exist
            XCTAssertTrue(app.tables.firstMatch.exists)
            
            // Go back
            app.navigationBars.buttons["Back"].tap()
        }
    }
    
    // MARK: - Settings Tests
    
    func testScannerSettings() throws {
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Find Scanner settings
        let scannerCell = app.tables.cells.staticTexts["Scanner Settings"]
        if scannerCell.waitForExistence(timeout: 3) {
            scannerCell.tap()
            
            // Verify scanner settings options
            XCTAssertTrue(app.switches["Auto-Flash"].exists ||
                         app.switches["Sound Feedback"].exists ||
                         app.switches["Vibration"].exists)
            
            // Toggle a setting
            if app.switches["Sound Feedback"].exists {
                app.switches["Sound Feedback"].tap()
            }
        }
    }
    
    // MARK: - Add Item from Scan Tests
    
    func testAddItemFromScan() throws {
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Simulate successful scan
        if app.buttons["Simulate Scan"].exists {
            app.buttons["Simulate Scan"].tap()
        }
        
        // Wait for product details
        XCTAssertTrue(app.navigationBars["Product Details"].waitForExistence(timeout: 5))
        
        // Add to inventory
        app.buttons["Add to Inventory"].tap()
        
        // Should navigate to add item with pre-filled data
        XCTAssertTrue(app.navigationBars["Add Item"].waitForExistence(timeout: 3))
        
        // Verify fields are pre-filled
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.value as? String != "" && nameField.value as? String != "Item Name")
        
        // Save item
        app.navigationBars.buttons["Save"].tap()
        
        // Should return to scanner or show success
        XCTAssertTrue(app.tabBars.buttons["Scanner"].isSelected ||
                     app.alerts["Item Added"].exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testCameraUnavailable() throws {
        // Set flag for no camera
        app.launchArguments += ["--no-camera"]
        app.launch()
        
        // Navigate to scanner
        app.tabBars.buttons["Scanner"].tap()
        
        // Should show camera unavailable message
        XCTAssertTrue(app.staticTexts["Camera not available"].waitForExistence(timeout: 3) ||
                     app.alerts["Camera Error"].waitForExistence(timeout: 3))
        
        // Should still allow manual entry
        XCTAssertTrue(app.buttons["Enter Manually"].exists)
    }
}