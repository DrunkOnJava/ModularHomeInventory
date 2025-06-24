import XCTest

final class ScreenshotDebug: XCTestCase {
    func testTakeSingleScreenshot() throws {
        let app = XCUIApplication()
        
        setupSnapshot(app)
        app.launch()
        
        // Wait for app to fully launch
        sleep(2)
        
        // 1. Items List Screen
        snapshot("01_ItemsList")
        
        // 2. Navigate to Analytics tab
        app.tabBars["Tab Bar"].buttons["Analytics"].tap()
        sleep(1)
        snapshot("02_Analytics")
        
        // 3. Navigate to Scanner tab
        app.tabBars["Tab Bar"].buttons["Scanner"].tap()
        sleep(1)
        snapshot("03_Scanner")
        
        // 4. Navigate to Receipts tab
        app.tabBars["Tab Bar"].buttons["Receipts"].tap()
        sleep(1)
        snapshot("04_Receipts")
        
        // 5. Navigate to Settings tab
        app.tabBars["Tab Bar"].buttons["Settings"].tap()
        sleep(1)
        snapshot("05_Settings")
        
        // 6. Go back to Items and tap on an item if available
        app.tabBars["Tab Bar"].buttons["Items"].tap()
        sleep(1)
        
        // Try to tap on the first item in the list
        let itemsTable = app.tables.firstMatch
        if itemsTable.exists && itemsTable.cells.count > 0 {
            itemsTable.cells.element(boundBy: 0).tap()
            sleep(1)
            snapshot("06_ItemDetail")
        }
        
        // Final wait
        sleep(2)
    }
}