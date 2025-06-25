import XCTest

final class HomeInventoryModularUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Initialize app with the correct bundle identifier
        app = XCUIApplication(bundleIdentifier: "com.homeinventory.app")
        app.launchArguments = ["-AppleLocale", "en_US"]
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"]
        app.launchArguments += ["-FASTLANE_SNAPSHOT"]
        
        // Setup snapshot before launch
        setupSnapshot(app)
        
        // Terminate any existing instance
        app.terminate()
        
        // Launch the app
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testTakeScreenshots() throws {
        // Create screenshot directory
        let screenshotDir = getScreenshotDirectory()
        
        // Wait for app to fully load
        XCTAssert(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        
        // 1. Main Items List
        captureScreenshot(named: "01_ItemsList", directory: screenshotDir)
        
        // 2. Add Item Flow
        if app.navigationBars.buttons["plus"].waitForExistence(timeout: 2) {
            app.navigationBars.buttons["plus"].tap()
            sleep(1)
            captureScreenshot(named: "02_AddItem", directory: screenshotDir)
            
            // Fill in some item details for a more realistic screenshot
            let nameField = app.textFields.firstMatch
            if nameField.exists {
                nameField.tap()
                nameField.typeText("MacBook Pro 16\"")
            }
            
            // Cancel to go back
            if app.navigationBars.buttons["Cancel"].exists {
                app.navigationBars.buttons["Cancel"].tap()
                sleep(1)
            }
        }
        
        // 3. Scanner Tab
        navigateToTab("Scanner")
        captureScreenshot(named: "03_BarcodeScanner", directory: screenshotDir)
        
        // 4. Receipts Tab
        navigateToTab("Receipts")
        captureScreenshot(named: "04_Receipts", directory: screenshotDir)
        
        // 5. Analytics Tab (if exists)
        if app.tabBars.buttons["Analytics"].exists {
            navigateToTab("Analytics")
            captureScreenshot(named: "05_Analytics", directory: screenshotDir)
        }
        
        // 6. Settings Tab
        navigateToTab("Settings")
        captureScreenshot(named: "06_Settings", directory: screenshotDir)
        
        // 7. Settings Sub-screens
        captureSettingsScreens(directory: screenshotDir)
        
        // 8. Premium Features (if accessible)
        capturePremiumScreens(directory: screenshotDir)
        
        print("✅ Screenshot capture completed. Saved to: \(screenshotDir.path)")
    }
    
    // MARK: - Helper Methods
    
    private func getScreenshotDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsDir = documentsDirectory.appendingPathComponent("UITestScreenshots")
        try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        return screenshotsDir
    }
    
    private func navigateToTab(_ tabName: String) {
        let tabButton = app.tabBars.buttons[tabName]
        if tabButton.waitForExistence(timeout: 2) {
            tabButton.tap()
            sleep(1) // Allow UI to settle
        }
    }
    
    private func captureScreenshot(named name: String, directory: URL) {
        let screenshot = app.screenshot()
        
        // Save to file if possible
        let fileURL = directory.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Captured: \(name)")
        } catch {
            print("❌ Failed to save screenshot: \(name)")
        }
        
        // Also use snapshot for Fastlane compatibility
        snapshot(name, waitForLoadingIndicator: false)
        
        // Attach to test results
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    private func captureSettingsScreens(directory: URL) {
        // Navigate through various settings screens
        let settingsOptions = [
            "Categories": "07_Categories",
            "Locations": "08_Locations",
            "Data & Storage": "09_DataStorage",
            "Premium": "10_Premium"
        ]
        
        for (optionName, screenshotName) in settingsOptions {
            let cell = app.tables.cells.containing(.staticText, identifier: optionName).firstMatch
            if cell.waitForExistence(timeout: 2) {
                cell.tap()
                sleep(1)
                captureScreenshot(named: screenshotName, directory: directory)
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                    sleep(1)
                }
            }
        }
    }
    
    private func capturePremiumScreens(directory: URL) {
        // Try to access premium features showcase
        navigateToTab("Settings")
        
        let premiumCell = app.tables.cells.containing(.staticText, identifier: "Premium").firstMatch
        if premiumCell.waitForExistence(timeout: 2) {
            premiumCell.tap()
            sleep(1)
            captureScreenshot(named: "11_PremiumFeatures", directory: directory)
            
            // Back to settings
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
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