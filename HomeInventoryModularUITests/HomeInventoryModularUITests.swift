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
        // Wait for app to load
        sleep(2)
        
        // Take screenshot of main screen
        snapshot("01_MainScreen")
        
        // Navigate to Items tab if not already there
        if app.tabBars.buttons["Items"].exists {
            app.tabBars.buttons["Items"].tap()
            sleep(1)
            snapshot("02_ItemsList")
        }
        
        // Tap add button to show add item screen
        if app.navigationBars.buttons["Add"].exists {
            app.navigationBars.buttons["Add"].tap()
            sleep(1)
            snapshot("03_AddItem")
            
            // Go back
            if app.navigationBars.buttons["Cancel"].exists {
                app.navigationBars.buttons["Cancel"].tap()
            }
        }
        
        // Navigate to Scanner tab
        if app.tabBars.buttons["Scanner"].exists {
            app.tabBars.buttons["Scanner"].tap()
            sleep(1)
            snapshot("04_Scanner")
        }
        
        // Navigate to Receipts tab
        if app.tabBars.buttons["Receipts"].exists {
            app.tabBars.buttons["Receipts"].tap()
            sleep(1)
            snapshot("05_Receipts")
        }
        
        // Navigate to Settings tab
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
            snapshot("06_Settings")
            
            // Try to navigate to a settings subsection
            let settingsCells = app.tables.cells
            if settingsCells.count > 0 {
                settingsCells.element(boundBy: 0).tap()
                sleep(1)
                snapshot("07_SettingsDetail")
                
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
                snapshot("08_ItemDetail")
            }
        }
    }
    
    func testAccessibilityScreenshots() throws {
        // Enable larger text for accessibility screenshots
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        
        sleep(2)
        snapshot("09_AccessibilityLargeText")
        
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
                snapshot("10_AccessibilitySettings")
            }
        }
    }
}