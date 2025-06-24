import XCTest

final class HomeInventoryModularUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add launch arguments for better screenshots
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"]
        
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testTakeScreenshots() throws {
        // Log that we're starting
        print("Starting screenshot test")
        XCTContext.runActivity(named: "Debug Environment") { _ in
            print("FASTLANE_SNAPSHOT: \(ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT"] ?? "NOT SET")")
            print("SIMULATOR_DEVICE_NAME: \(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "NOT SET")")
            print("SIMULATOR_HOST_HOME: \(ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] ?? "NOT SET")")
        }
        
        // Wait for app to load
        sleep(2)
        
        // Take screenshot of main screen
        XCTContext.runActivity(named: "Take Main Screen Screenshot") { _ in
            print("Taking screenshot: 01_MainScreen")
            
            // Test if we're in Fastlane environment
            if ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT"] == "YES" {
                print("✅ FASTLANE_SNAPSHOT is set correctly")
            } else {
                print("❌ FASTLANE_SNAPSHOT is not set")
            }
            
            // Take a manual screenshot for debugging
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Debug_MainScreen"
            attachment.lifetime = .keepAlways
            add(attachment)
            print("Added XCTest screenshot attachment")
            
            snapshot("01_MainScreen", waitForLoadingIndicator: false)
            print("Called snapshot function")
        }
        
        // Navigate to Items tab if not already there
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
            sleep(1)
            print("Taking screenshot: 02_ItemsList")
            snapshot("02_ItemsList", waitForLoadingIndicator: false)
        }
        
        // Tap add button to show add item screen
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            sleep(1)
            print("Taking screenshot: 03_AddItem")
            snapshot("03_AddItem", waitForLoadingIndicator: false)
            
            // Go back
            if app.navigationBars.buttons["Cancel"].exists {
                app.navigationBars.buttons["Cancel"].tap()
            }
        }
        
        // Navigate to Scanner tab
        if app.tabBars.buttons["Scanner"].exists {
            app.tabBars.buttons["Scanner"].tap()
            sleep(1)
            print("Taking screenshot: 04_Scanner")
            snapshot("04_Scanner", waitForLoadingIndicator: false)
        }
        
        // Navigate to Receipts tab
        if app.tabBars.buttons["Receipts"].exists {
            app.tabBars.buttons["Receipts"].tap()
            sleep(1)
            print("Taking screenshot: 05_Receipts")
            snapshot("05_Receipts", waitForLoadingIndicator: false)
        }
        
        // Navigate to Settings tab
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
            print("Taking screenshot: 06_Settings")
            snapshot("06_Settings", waitForLoadingIndicator: false)
            
            // Try to navigate to a settings subsection
            let settingsCells = app.tables.cells
            if settingsCells.count > 0 {
                settingsCells.element(boundBy: 0).tap()
                sleep(1)
                print("Taking screenshot: 07_SettingsDetail")
                snapshot("07_SettingsDetail", waitForLoadingIndicator: false)
                
                // Go back
                if app.navigationBars.buttons.element(boundBy: 0).exists {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                }
            }
        }
        
        // Navigate back to Items and show detail if possible
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
            sleep(1)
            
            // If there are items in the list, tap the first one
            let itemCells = app.tables.cells
            if itemCells.count > 0 {
                itemCells.element(boundBy: 0).tap()
                sleep(1)
                print("Taking screenshot: 08_ItemDetail")
                snapshot("08_ItemDetail", waitForLoadingIndicator: false)
            }
        }
        
        print("Finished screenshot test")
    }
    
    func testAccessibilityScreenshots() throws {
        // Enable larger text for accessibility screenshots
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        
        sleep(2)
        snapshot("09_AccessibilityLargeText", waitForLoadingIndicator: false)
        
        // Navigate to Settings for accessibility options
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
            
            // Look for Accessibility settings
            let tables = app.tables
            let accessibilityCell = tables.cells.containing(.staticText, identifier: "Accessibility").element
            if accessibilityCell.exists {
                accessibilityCell.tap()
                sleep(1)
                snapshot("10_AccessibilitySettings", waitForLoadingIndicator: false)
            }
        }
    }
}