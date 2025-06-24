import XCTest

class SimpleScreenshotTest: XCTestCase {
    
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        sleep(2)
        
        // 1. Items List (default screen)
        takeScreenshot(named: "01_ItemsList")
        
        // 2. Collections Tab
        if app.tabBars.buttons["Collections"].exists {
            app.tabBars.buttons["Collections"].tap()
            sleep(1)
            takeScreenshot(named: "02_Collections")
        }
        
        // 3. Analytics Tab  
        if app.tabBars.buttons["Analytics"].exists {
            app.tabBars.buttons["Analytics"].tap()
            sleep(1)
            takeScreenshot(named: "03_Analytics")
        }
        
        // 4. Scanner Tab
        if app.tabBars.buttons["Scanner"].exists {
            app.tabBars.buttons["Scanner"].tap()
            sleep(1)
            takeScreenshot(named: "04_Scanner")
        }
        
        // 5. Settings Tab
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
            sleep(1)
            takeScreenshot(named: "05_Settings")
        }
    }
    
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}