//
//  ScreenshotCaptureTests.swift
//  HomeInventoryModularUITests
//
//  Comprehensive screenshot capture for all views
//

import XCTest

class ScreenshotCaptureTests: XCTestCase {
    
    var app: XCUIApplication!
    var screenshotCounter = 0
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
    }
    
    // MARK: - Main Test
    
    func testCaptureAllScreenshots() throws {
        // Capture main tabs
        captureMainTabs()
        
        // Capture Items module screens
        captureItemsModule()
        
        // Capture Collections module screens
        captureCollectionsModule()
        
        // Capture Analytics module screens
        captureAnalyticsModule()
        
        // Capture Scanner module screens
        captureScannerModule()
        
        // Capture Settings module screens
        captureSettingsModule()
    }
    
    // MARK: - Main Tabs
    
    func captureMainTabs() {
        // Items tab (default)
        captureScreen("01_MainScreen_ItemsList")
        
        // Collections tab
        app.tabBars.buttons["Collections"].tap()
        captureScreen("02_MainScreen_Collections")
        
        // Analytics tab
        app.tabBars.buttons["Analytics"].tap()
        captureScreen("03_MainScreen_Analytics")
        
        // Scanner tab
        app.tabBars.buttons["Scanner"].tap()
        captureScreen("04_MainScreen_Scanner")
        
        // Settings tab
        app.tabBars.buttons["Settings"].tap()
        captureScreen("05_MainScreen_Settings")
    }
    
    // MARK: - Items Module
    
    func captureItemsModule() {
        // Go to Items tab
        app.tabBars.buttons["Items"].tap()
        wait(1)
        
        // Add Item button
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            captureScreen("10_Items_AddItem")
            dismissModal()
        }
        
        // Item detail
        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            wait(1)
            captureScreen("11_Items_ItemDetail")
            
            // Try to capture edit
            if app.buttons["Edit"].exists {
                app.buttons["Edit"].tap()
                captureScreen("12_Items_EditItem")
                dismissModal()
            }
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Filters
        if app.buttons["Filter"].exists {
            app.buttons["Filter"].tap()
            captureScreen("13_Items_Filters")
            dismissModal()
        }
        
        // Search
        if app.searchFields.firstMatch.exists {
            app.searchFields.firstMatch.tap()
            captureScreen("14_Items_Search")
            app.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Collections Module
    
    func captureCollectionsModule() {
        app.tabBars.buttons["Collections"].tap()
        wait(1)
        
        // Add Collection
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            captureScreen("20_Collections_AddCollection")
            dismissModal()
        }
        
        // Collection detail
        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            wait(1)
            captureScreen("21_Collections_Detail")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Analytics Module
    
    func captureAnalyticsModule() {
        app.tabBars.buttons["Analytics"].tap()
        wait(1)
        
        captureScreen("30_Analytics_Dashboard")
        
        // Try to find analytics sub-sections
        let analyticsSections = ["Category", "Retailer", "Time", "Patterns"]
        for (index, section) in analyticsSections.enumerated() {
            if app.buttons[section].exists {
                app.buttons[section].tap()
                captureScreen("3\(index + 1)_Analytics_\(section)")
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Scanner Module
    
    func captureScannerModule() {
        app.tabBars.buttons["Scanner"].tap()
        wait(1)
        
        captureScreen("40_Scanner_Main")
        
        // Check for scanner tabs
        if app.segmentedControls.firstMatch.exists {
            let segments = app.segmentedControls.firstMatch.buttons.count
            for i in 0..<segments {
                app.segmentedControls.firstMatch.buttons.element(boundBy: i).tap()
                captureScreen("4\(i + 1)_Scanner_Tab\(i + 1)")
            }
        }
    }
    
    // MARK: - Settings Module
    
    func captureSettingsModule() {
        app.tabBars.buttons["Settings"].tap()
        wait(1)
        
        captureScreen("50_Settings_Main")
        
        // Settings sections to capture
        let settingsSections = [
            "Notifications",
            "Spotlight",
            "Accessibility",
            "Scanner Settings",
            "Biometric",
            "Privacy",
            "Export Data",
            "Sync Status"
        ]
        
        for (index, section) in settingsSections.enumerated() {
            // Try different ways to find the setting
            let cell = app.tables.cells.containing(.staticText, identifier: section).firstMatch
            if cell.exists && cell.isHittable {
                cell.tap()
                wait(1)
                captureScreen("5\(index + 1)_Settings_\(section.replacingOccurrences(of: " ", with: ""))")
                dismissModal()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func captureScreen(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        screenshotCounter += 1
        print("📸 Captured screenshot \(screenshotCounter): \(name)")
    }
    
    func wait(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
    
    func dismissModal() {
        // Try different ways to dismiss
        if app.navigationBars.buttons["Cancel"].exists {
            app.navigationBars.buttons["Cancel"].tap()
        } else if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        } else if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else if app.navigationBars.buttons["Close"].exists {
            app.navigationBars.buttons["Close"].tap()
        } else {
            // Try swipe down
            app.swipeDown()
        }
        wait(0.5)
    }
}

// MARK: - iPad-specific Screenshots

class iPadScreenshotCaptureTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Ensure we're on iPad
        XCTAssertTrue(UIDevice.current.userInterfaceIdiom == .pad, "This test is for iPad only")
        
        sleep(2)
    }
    
    func testCaptureiPadScreenshots() throws {
        captureScreen("60_iPad_Sidebar")
        
        // Navigate through sidebar sections
        let sidebarSections = [
            "Items",
            "Collections",
            "Locations",
            "Categories",
            "Analytics",
            "Reports",
            "Budget",
            "Scanner",
            "Search",
            "Import/Export",
            "Settings"
        ]
        
        for (index, section) in sidebarSections.enumerated() {
            if app.buttons[section].exists {
                app.buttons[section].tap()
                wait(1)
                captureScreen("6\(index + 1)_iPad_\(section)")
            }
        }
    }
    
    func captureScreen(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func wait(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}