import XCTest

/// Performance tests for app launch time measurement
class AppLaunchPerformanceTests: XCTestCase {
    
    /// Measure cold launch time (first launch after install)
    func testColdLaunchPerformance() throws {
        // Skip if not on CI to avoid affecting local development
        guard ProcessInfo.processInfo.environment["CI"] != nil else {
            throw XCTSkip("Performance tests only run on CI")
        }
        
        measure(metrics: [
            XCTApplicationLaunchMetric(waitUntilResponsive: true)
        ]) {
            let app = XCUIApplication()
            app.launch()
            
            // Wait for main screen
            _ = app.tables.firstMatch.waitForExistence(timeout: 5)
            
            app.terminate()
        }
    }
    
    /// Measure warm launch time (subsequent launches)
    func testWarmLaunchPerformance() throws {
        guard ProcessInfo.processInfo.environment["CI"] != nil else {
            throw XCTSkip("Performance tests only run on CI")
        }
        
        // First launch to warm up
        let app = XCUIApplication()
        app.launch()
        _ = app.tables.firstMatch.waitForExistence(timeout: 5)
        
        // Measure subsequent launches
        measure(metrics: [
            XCTApplicationLaunchMetric(waitUntilResponsive: true),
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]) {
            app.terminate()
            app.launch()
            _ = app.tables.firstMatch.waitForExistence(timeout: 5)
        }
    }
    
    /// Measure launch with large dataset
    func testLaunchWithLargeDatasetPerformance() throws {
        // Preload test data
        let testDataURL = Bundle(for: type(of: self))
            .url(forResource: "large_dataset", withExtension: "json")!
        
        // Copy to app container
        let app = XCUIApplication()
        app.launchArguments = ["--load-test-data", testDataURL.path]
        
        measure(metrics: [
            XCTApplicationLaunchMetric(),
            XCTMemoryMetric(application: app),
            XCTStorageMetric(application: app)
        ]) {
            app.launch()
            
            // Verify data loaded
            let itemCount = app.staticTexts["item-count"]
            _ = itemCount.waitForExistence(timeout: 10)
            
            XCTAssertEqual(itemCount.label, "10,000 items")
        }
    }
    
    /// Test individual module initialization times
    func testModuleInitializationPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--measure-module-init"]
        app.launch()
        
        // Wait for performance data
        _ = app.tables["performance-metrics"].waitForExistence(timeout: 10)
        
        // Extract module init times
        let metrics = app.tables["performance-metrics"]
        
        // Verify each module initializes within acceptable time
        let expectedMaxTimes: [String: Double] = [
            "Core": 50,          // 50ms
            "Items": 100,        // 100ms
            "BarcodeScanner": 200, // 200ms (camera init)
            "Gmail": 150,        // 150ms
            "Sync": 100,         // 100ms
            "Premium": 50,       // 50ms
            "Receipts": 75,      // 75ms
            "AppSettings": 50,   // 50ms
            "Onboarding": 50,    // 50ms
            "SharedUI": 75       // 75ms
        ]
        
        for (module, maxTime) in expectedMaxTimes {
            let cell = metrics.cells[module]
            guard cell.exists else {
                XCTFail("Module \(module) metrics not found")
                continue
            }
            
            let timeLabel = cell.staticTexts["init-time"]
            let timeString = timeLabel.label.replacingOccurrences(of: "ms", with: "")
            let time = Double(timeString) ?? 0
            
            XCTAssertLessThan(
                time,
                maxTime,
                "\(module) initialization took \(time)ms, expected < \(maxTime)ms"
            )
        }
    }
    
    /// Measure time to first meaningful paint
    func testTimeToFirstMeaningfulPaint() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--trace-launch"]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        app.launch()
        
        // Wait for first item to appear (meaningful content)
        let firstItem = app.cells.element(boundBy: 0)
        _ = firstItem.waitForExistence(timeout: 5)
        
        let timeToFirstPaint = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log for metrics tracking
        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.json",
            name: "time_to_first_paint.json",
            payload: """
            {
                "time_to_first_paint": \(timeToFirstPaint),
                "timestamp": "\(Date())",
                "device": "\(UIDevice.current.name)"
            }
            """.data(using: .utf8)!,
            userInfo: nil
        )
        add(attachment)
        
        XCTAssertLessThan(timeToFirstPaint, 1.5, "First meaningful paint took too long")
    }
}