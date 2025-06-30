import XCTest

/// Performance tests for UI operations and scrolling
final class UIPerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        app = XCUIApplication()
        app.launchArguments = [
            "--testing",
            "--skip-onboarding",
            "--load-test-data",
            "--item-count-1000"
        ]
        
        continueAfterFailure = false
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // MARK: - Scrolling Performance
    
    func testTableViewScrollingPerformance() throws {
        app.launch()
        
        // Wait for items to load
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        
        // Ensure we have items
        let firstCell = table.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        
        measure(metrics: [
            XCTOSSignpostMetric.scrollDecelerationMetric,
            XCTOSSignpostMetric.scrollDraggingMetric
        ]) {
            // Scroll to bottom
            table.swipeUp(velocity: .fast)
            table.swipeUp(velocity: .fast)
            table.swipeUp(velocity: .fast)
            
            // Scroll to top
            table.swipeDown(velocity: .fast)
            table.swipeDown(velocity: .fast)
            table.swipeDown(velocity: .fast)
        }
    }
    
    func testCollectionViewScrollingPerformance() throws {
        app.launch()
        
        // Navigate to grid view
        app.buttons["Grid View"].tap()
        
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))
        
        measure(metrics: [
            XCTOSSignpostMetric.scrollDecelerationMetric,
            XCTMemoryMetric(application: app)
        ]) {
            // Rapid scrolling
            for _ in 0..<5 {
                collectionView.swipeUp(velocity: .fast)
            }
            
            for _ in 0..<5 {
                collectionView.swipeDown(velocity: .fast)
            }
        }
    }
    
    // MARK: - Navigation Performance
    
    func testNavigationTransitionPerformance() throws {
        app.launch()
        
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        
        measure(metrics: [XCTOSSignpostMetric.navigationTransitionMetric]) {
            // Navigate to detail view
            table.cells.element(boundBy: 0).tap()
            
            // Wait for detail view
            _ = app.navigationBars["Item Details"].waitForExistence(timeout: 2)
            
            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            
            // Wait for list view
            _ = table.waitForExistence(timeout: 2)
        }
    }
    
    func testTabSwitchingPerformance() throws {
        app.launch()
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let tabs = ["Items", "Search", "Scan", "Analytics", "Settings"]
        
        measure {
            for tab in tabs {
                tabBar.buttons[tab].tap()
                
                // Small delay to ensure view loads
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    // MARK: - Search Performance
    
    func testSearchUIPerformance() throws {
        app.launch()
        
        // Navigate to search
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        measure {
            searchField.tap()
            searchField.typeText("test item")
            
            // Wait for results
            let resultsTable = app.tables["search-results"]
            _ = resultsTable.waitForExistence(timeout: 2)
            
            // Clear search
            searchField.buttons["Clear text"].tap()
        }
    }
    
    func testFilteringPerformance() throws {
        app.launch()
        
        // Open filter sheet
        app.buttons["Filter"].tap()
        
        let filterSheet = app.sheets.firstMatch
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        measure {
            // Apply multiple filters
            filterSheet.buttons["Electronics"].tap()
            filterSheet.sliders["price-range"].adjust(toNormalizedSliderPosition: 0.7)
            filterSheet.switches["In Stock Only"].tap()
            
            // Apply filters
            filterSheet.buttons["Apply"].tap()
            
            // Wait for filtered results
            _ = app.tables.firstMatch.waitForExistence(timeout: 2)
            
            // Reset filters
            app.buttons["Filter"].tap()
            filterSheet.buttons["Reset"].tap()
            filterSheet.buttons["Apply"].tap()
        }
    }
    
    // MARK: - Image Loading Performance
    
    func testImageLoadingPerformance() throws {
        app.launch()
        
        // Navigate to grid view with images
        app.buttons["Grid View"].tap()
        
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))
        
        measure(metrics: [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]) {
            // Scroll through images
            for _ in 0..<10 {
                collectionView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5) // Allow images to load
            }
        }
    }
    
    // MARK: - Animation Performance
    
    func testAnimationPerformance() throws {
        app.launch()
        
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        
        measure(metrics: [XCTOSSignpostMetric.animationDurationMetric]) {
            // Trigger various animations
            
            // Pull to refresh
            table.swipeDown(velocity: .slow)
            Thread.sleep(forTimeInterval: 1)
            
            // Selection animation
            let cell = table.cells.element(boundBy: 0)
            cell.tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
            
            // Deletion animation
            cell.swipeLeft()
            if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap()
                app.alerts.buttons["Cancel"].tap()
            }
        }
    }
    
    // MARK: - Keyboard Performance
    
    func testKeyboardPerformance() throws {
        app.launch()
        
        // Navigate to add item
        app.buttons["Add"].tap()
        
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        
        measure {
            nameField.tap()
            
            // Type text
            nameField.typeText("Performance Test Item with a really long name")
            
            // Dismiss keyboard
            app.buttons["Done"].tap()
            
            // Clear text
            nameField.tap()
            nameField.buttons["Clear text"].tap()
        }
    }
}