import XCTest

final class ScreenshotDebug: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testTakeSingleScreenshot() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // Wait for app to fully launch
        sleep(2)
        
        // 1. Items List Screen
        Snapshot.snapshot("01_ItemsList")
        
        // 2. Navigate to Collections tab
        if app.tabBars["Tab Bar"].buttons["Collections"].exists {
            app.tabBars["Tab Bar"].buttons["Collections"].tap()
            sleep(1)
            Snapshot.snapshot("02_Collections")
        }
        
        // 3. Navigate to Analytics tab
        if app.tabBars["Tab Bar"].buttons["Analytics"].exists {
            app.tabBars["Tab Bar"].buttons["Analytics"].tap()
            sleep(1)
            Snapshot.snapshot("03_Analytics")
        }
        
        // 4. Navigate to Scanner tab
        if app.tabBars["Tab Bar"].buttons["Scanner"].exists {
            app.tabBars["Tab Bar"].buttons["Scanner"].tap()
            sleep(1)
            Snapshot.snapshot("04_Scanner")
        }
        
        // 5. Navigate to Settings tab
        if app.tabBars["Tab Bar"].buttons["Settings"].exists {
            app.tabBars["Tab Bar"].buttons["Settings"].tap()
            sleep(1)
            Snapshot.snapshot("05_Settings")
        }
        
        // 6. Go back to Items and tap on an item if available
        if app.tabBars["Tab Bar"].buttons["Items"].exists {
            app.tabBars["Tab Bar"].buttons["Items"].tap()
            sleep(1)
            
            // Try to tap on the first item in the list
            let itemsTable = app.tables.firstMatch
            if itemsTable.exists && itemsTable.cells.count > 0 {
                itemsTable.cells.element(boundBy: 0).tap()
                sleep(1)
                Snapshot.snapshot("06_ItemDetail")
            }
        }
        
        // Final wait
        sleep(2)
    }
}