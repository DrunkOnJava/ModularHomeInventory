import XCTest

final class ScreenshotDebug: XCTestCase {
    func testTakeSingleScreenshot() throws {
        let app = XCUIApplication()
        
        // Verify functions exist
        print("TEST: Starting screenshot test")
        
        setupSnapshot(app)
        app.launch()
        
        // Add some debug output
        print("DEBUG: About to call snapshot")
        print("snapshot: 01_LaunchScreen") // Try printing the exact format Fastlane expects
        snapshot("01_LaunchScreen")
        print("DEBUG: Called snapshot")
        
        // Wait a moment to ensure everything processes
        sleep(2)
    }
}