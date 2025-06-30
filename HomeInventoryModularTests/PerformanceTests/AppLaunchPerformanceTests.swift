import XCTest
@testable import HomeInventoryModular

/// Performance tests for app launch time measurement
final class AppLaunchPerformanceTests: XCTestCase {
    
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
            app.launchArguments = ["--testing", "--skip-onboarding"]
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
        app.launchArguments = ["--testing", "--skip-onboarding"]
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
        guard ProcessInfo.processInfo.environment["CI"] != nil else {
            throw XCTSkip("Performance tests only run on CI")
        }
        
        let app = XCUIApplication()
        app.launchArguments = [
            "--testing",
            "--skip-onboarding",
            "--load-test-data",
            "--item-count-10000"
        ]
        
        measure(metrics: [
            XCTApplicationLaunchMetric(),
            XCTMemoryMetric(application: app),
            XCTStorageMetric(application: app)
        ]) {
            app.launch()
            
            // Wait for data to load
            let itemCountLabel = app.staticTexts.matching(identifier: "item-count").firstMatch
            _ = itemCountLabel.waitForExistence(timeout: 10)
            
            app.terminate()
        }
    }
    
    /// Test time to first meaningful paint
    func testTimeToFirstMeaningfulPaint() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--testing", "--skip-onboarding", "--trace-launch"]
        
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        
        measure(options: options) {
            app.launch()
            
            startMeasuring()
            
            // Wait for first item to appear (meaningful content)
            let firstItem = app.cells.element(boundBy: 0)
            _ = firstItem.waitForExistence(timeout: 5)
            
            stopMeasuring()
            
            app.terminate()
        }
    }
    
    /// Test module initialization performance
    func testModuleInitializationPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--testing", "--measure-module-init"]
        app.launch()
        
        // Wait for metrics table
        let metricsTable = app.tables["performance-metrics"]
        XCTAssertTrue(metricsTable.waitForExistence(timeout: 10))
        
        // Expected maximum initialization times (in milliseconds)
        let expectedMaxTimes: [String: Double] = [
            "Core": 50,
            "Items": 100,
            "BarcodeScanner": 200,
            "Gmail": 150,
            "Sync": 100,
            "Premium": 50,
            "Receipts": 75,
            "AppSettings": 50,
            "Onboarding": 50,
            "SharedUI": 75
        ]
        
        // Verify each module's initialization time
        for (module, maxTime) in expectedMaxTimes {
            let cell = metricsTable.cells[module]
            
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
}