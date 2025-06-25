import XCTest

// MARK: - Accessibility Identifiers
enum AccessibilityIdentifiers {
    enum TabBar {
        static let items = "tab_items"
        static let scanner = "tab_scanner"
        static let receipts = "tab_receipts"
        static let analytics = "tab_analytics"
        static let settings = "tab_settings"
    }
    
    enum Navigation {
        static let addButton = "nav_add_button"
        static let backButton = "nav_back_button"
        static let cancelButton = "nav_cancel_button"
        static let saveButton = "nav_save_button"
    }
    
    enum Settings {
        static let categoriesCell = "settings_categories"
        static let locationsCell = "settings_locations"
        static let dataStorageCell = "settings_data_storage"
        static let premiumCell = "settings_premium"
        static let appearanceCell = "settings_appearance"
        static let notificationsCell = "settings_notifications"
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    /// Wait for element to exist and be hittable
    func waitForExistenceAndTap(timeout: TimeInterval = 5) -> Bool {
        if waitForExistence(timeout: timeout) && isHittable {
            tap()
            return true
        }
        return false
    }
    
    /// Clear text field and type new text
    func clearAndType(_ text: String) {
        guard exists else { return }
        tap()
        
        // Select all and delete
        if let stringValue = value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(deleteString)
        }
        
        typeText(text)
    }
}

// MARK: - Screenshot Helpers
extension XCTestCase {
    /// Take a screenshot with proper naming and organization
    func takeScreenshot(named name: String, waitTime: TimeInterval = 0.5) {
        // Allow UI to settle
        Thread.sleep(forTimeInterval: waitTime)
        
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also use snapshot for Fastlane
        snapshot(name, waitForLoadingIndicator: false)
    }
    
    /// Navigate to a tab and wait for it to load
    func navigateToTab(_ tabIdentifier: String, in app: XCUIApplication) {
        let tabButton = app.tabBars.buttons[tabIdentifier]
        if tabButton.waitForExistenceAndTap() {
            Thread.sleep(forTimeInterval: 1) // Allow tab content to load
        }
    }
}