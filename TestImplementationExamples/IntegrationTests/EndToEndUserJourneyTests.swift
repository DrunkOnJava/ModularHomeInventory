import XCTest
@testable import Core
@testable import Items
@testable import BarcodeScanner
@testable import Receipts
@testable import Gmail
@testable import Sync
@testable import Premium

/// End-to-end tests for complete user journeys
class EndToEndUserJourneyTests: XCTestCase {
    
    var testUser: TestUser!
    var app: XCUIApplication!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Reset app state
        try await TestDataManager.resetAllData()
        
        // Create test user
        testUser = try await TestUser.create(
            email: "test@example.com",
            isPremium: true
        )
        
        // Launch app
        app = XCUIApplication()
        app.launchArguments = ["--testing", "--skip-onboarding"]
        app.launchEnvironment = ["TEST_USER_ID": testUser.id.uuidString]
        app.launch()
    }
    
    override func tearDown() async throws {
        try await TestDataManager.resetAllData()
        try await super.tearDown()
    }
    
    // MARK: - Complete Item Lifecycle Journey
    
    func testCompleteItemLifecycleJourney() async throws {
        // Step 1: Scan barcode to create item
        app.tabBars.buttons["Scan"].tap()
        
        // Grant camera permission if needed
        springboard.alerts.buttons["OK"].tapIfExists()
        
        // Simulate barcode scan
        MockBarcodeScanner.mockScanResult = .success(
            Barcode(value: "9780134190440", type: .ean13)
        )
        
        // Wait for product lookup
        let productName = app.staticTexts["The Swift Programming Language"]
        XCTAssertTrue(productName.waitForExistence(timeout: 5))
        
        // Confirm item creation
        app.buttons["Add Item"].tap()
        
        // Step 2: Edit item details
        let itemCell = app.cells["The Swift Programming Language"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3))
        itemCell.tap()
        
        // Add custom fields
        app.buttons["Edit"].tap()
        
        let priceField = app.textFields["Price"]
        priceField.tap()
        priceField.clearAndType("49.99")
        
        let notesField = app.textViews["Notes"]
        notesField.tap()
        notesField.typeText("Birthday gift from Sarah")
        
        // Add location
        app.buttons["Add Location"].tap()
        app.textFields["Location Name"].typeText("Home Office")
        app.buttons["Save Location"].tap()
        
        app.buttons["Save"].tap()
        
        // Step 3: Add receipt via Gmail
        app.buttons["Add Receipt"].tap()
        app.buttons["Import from Gmail"].tap()
        
        // Mock Gmail API response
        MockGmailService.mockEmails = [
            EmailMessage(
                id: "msg123",
                subject: "Your Amazon order",
                from: "auto-confirm@amazon.com",
                date: Date(),
                snippet: "Order #123-4567890",
                attachments: [
                    Attachment(
                        filename: "receipt.pdf",
                        mimeType: "application/pdf",
                        data: TestData.sampleReceiptPDF
                    )
                ]
            )
        ]
        
        // Select receipt
        let receiptCell = app.cells["Your Amazon order"]
        XCTAssertTrue(receiptCell.waitForExistence(timeout: 5))
        receiptCell.tap()
        
        app.buttons["Import Receipt"].tap()
        
        // Verify receipt attached
        XCTAssertTrue(app.images["receipt-thumbnail"].waitForExistence(timeout: 3))
        
        // Step 4: Set warranty
        app.buttons["Warranty"].tap()
        app.buttons["Add Warranty"].tap()
        
        // Set 2-year warranty
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "2")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "Years")
        
        app.switches["Set Reminder"].tap()
        app.buttons["Save Warranty"].tap()
        
        // Step 5: Add to collection
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Add to Collection"].tap()
        
        // Create new collection
        app.buttons["Create New Collection"].tap()
        app.textFields["Collection Name"].typeText("Programming Books")
        app.buttons["Create"].tap()
        
        // Step 6: Share with family
        app.buttons["Share"].tap()
        app.buttons["Share with Family"].tap()
        
        // Select family member
        let familyMemberCell = app.cells["spouse@example.com"]
        XCTAssertTrue(familyMemberCell.waitForExistence(timeout: 3))
        familyMemberCell.tap()
        
        app.buttons["Share"].tap()
        
        // Step 7: Verify sync across devices
        // Simulate another device
        let otherDevice = SimulatedDevice(deviceId: "device2")
        try await otherDevice.launch(asUser: testUser)
        
        // Verify item appears on other device
        let syncedItem = try await otherDevice.waitForItem(
            named: "The Swift Programming Language",
            timeout: 10
        )
        
        XCTAssertNotNil(syncedItem)
        XCTAssertEqual(syncedItem.price, 49.99)
        XCTAssertTrue(syncedItem.hasReceipt)
        XCTAssertTrue(syncedItem.hasWarranty)
        XCTAssertEqual(syncedItem.collections.first?.name, "Programming Books")
        
        // Step 8: Test warranty notification
        // Fast-forward time to near warranty expiration
        try await TimeSimulator.advance(by: .days(700))
        
        // Check for warranty notification
        let notifications = try await NotificationCenter.getPendingNotifications()
        let warrantyNotification = notifications.first { 
            $0.content.title.contains("Warranty Expiring")
        }
        
        XCTAssertNotNil(warrantyNotification)
        XCTAssertTrue(warrantyNotification!.content.body.contains("The Swift Programming Language"))
    }
    
    // MARK: - Family Sharing Journey
    
    func testFamilySharingCompleteJourney() async throws {
        // Step 1: Set up family
        app.tabBars.buttons["Settings"].tap()
        app.cells["Family Sharing"].tap()
        app.buttons["Set Up Family"].tap()
        
        // Create family group
        app.textFields["Family Name"].typeText("The Smiths")
        app.buttons["Create Family"].tap()
        
        // Step 2: Invite family members
        app.buttons["Invite Members"].tap()
        
        let emailField = app.textFields["Email"]
        emailField.typeText("spouse@example.com")
        app.buttons["Send Invite"].tap()
        
        emailField.clearAndType("child@example.com")
        app.buttons["Send Invite"].tap()
        
        app.buttons["Done"].tap()
        
        // Step 3: Simulate acceptance
        let spouseDevice = SimulatedDevice(deviceId: "spouse-device")
        try await spouseDevice.acceptFamilyInvitation(
            token: MockFamilyService.mockInvitationToken
        )
        
        // Step 4: Create shared lists
        app.navigationBars.buttons["Back"].tap()
        app.tabBars.buttons["Items"].tap()
        app.buttons["Lists"].tap()
        app.buttons["Create List"].tap()
        
        app.textFields["List Name"].typeText("Household Items")
        app.switches["Share with Family"].tap()
        app.buttons["Create"].tap()
        
        // Step 5: Add items to shared list
        for itemName in ["Vacuum Cleaner", "Coffee Maker", "Microwave"] {
            app.buttons["Add Item"].tap()
            app.textFields["Item Name"].typeText(itemName)
            app.buttons["Save"].tap()
        }
        
        // Step 6: Test concurrent editing
        // Spouse adds item simultaneously
        Task {
            try await spouseDevice.addItemToList(
                "Household Items",
                itemName: "Toaster"
            )
        }
        
        // Current user adds item
        app.buttons["Add Item"].tap()
        app.textFields["Item Name"].typeText("Blender")
        app.buttons["Save"].tap()
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        
        // Verify both items appear
        XCTAssertTrue(app.cells["Toaster"].exists)
        XCTAssertTrue(app.cells["Blender"].exists)
        
        // Step 7: Test permissions
        // Create child device with restricted permissions
        let childDevice = SimulatedDevice(deviceId: "child-device")
        try await childDevice.launch(
            asUser: TestUser(email: "child@example.com", role: .child)
        )
        
        // Child should see items but not be able to edit
        let sharedList = try await childDevice.getList("Household Items")
        XCTAssertEqual(sharedList.items.count, 5)
        XCTAssertFalse(sharedList.canEdit)
        
        // Step 8: Test family analytics
        app.navigationBars.buttons["Back"].tap()
        app.tabBars.buttons["Analytics"].tap()
        app.segmentedControls.buttons["Family"].tap()
        
        // Verify family statistics
        XCTAssertTrue(app.staticTexts["Total Family Items: 5"].exists)
        XCTAssertTrue(app.staticTexts["Active Members: 3"].exists)
        
        // Check contribution breakdown
        let contributionChart = app.otherElements["contribution-chart"]
        XCTAssertTrue(contributionChart.exists)
    }
    
    // MARK: - Premium Features Journey
    
    func testPremiumFeaturesCompleteJourney() async throws {
        // Ensure user is premium
        XCTAssertTrue(testUser.isPremium)
        
        // Step 1: Advanced search
        app.searchFields.element.tap()
        app.searchFields.element.typeText("price:>100 warranty:active location:office")
        
        // Verify advanced search works
        let searchResults = app.tables["search-results"]
        XCTAssertTrue(searchResults.waitForExistence(timeout: 3))
        
        // Step 2: Bulk operations
        app.buttons["Select"].tap()
        
        // Select multiple items
        for i in 0..<5 {
            app.cells.element(boundBy: i).buttons["selection-circle"].tap()
        }
        
        app.buttons["Actions"].tap()
        app.buttons["Add to Collection"].tap()
        app.cells["Office Equipment"].tap()
        
        // Verify bulk operation completed
        let successBanner = app.banners["5 items added to collection"]
        XCTAssertTrue(successBanner.waitForExistence(timeout: 3))
        
        // Step 3: Custom fields
        app.buttons["Cancel"].tap() // Exit selection mode
        app.cells.firstMatch.tap()
        app.buttons["Edit"].tap()
        app.buttons["Add Custom Field"].tap()
        
        app.textFields["Field Name"].typeText("Purchase Order")
        app.textFields["Field Value"].typeText("PO-2024-001")
        app.buttons["Add"].tap()
        
        app.buttons["Save"].tap()
        
        // Step 4: Advanced export
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Export"].tap()
        
        // Configure export options
        app.buttons["Export Format"].tap()
        app.buttons["Excel (.xlsx)"].tap()
        
        app.switches["Include Photos"].tap()
        app.switches["Include Custom Fields"].tap()
        app.switches["Generate QR Codes"].tap()
        
        app.buttons["Export"].tap()
        
        // Verify export completed
        let shareSheet = app.sheets.element
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5))
        
        // Step 5: Analytics dashboard
        app.buttons["Cancel"].tap() // Dismiss share sheet
        app.tabBars.buttons["Analytics"].tap()
        
        // Check premium analytics
        app.buttons["Insights"].tap()
        
        XCTAssertTrue(app.staticTexts["Depreciation Analysis"].exists)
        XCTAssertTrue(app.staticTexts["Category Trends"].exists)
        XCTAssertTrue(app.staticTexts["Warranty ROI"].exists)
        
        // Step 6: Automation rules
        app.tabBars.buttons["Settings"].tap()
        app.cells["Automation"].tap()
        app.buttons["Create Rule"].tap()
        
        // Create warranty reminder rule
        app.textFields["Rule Name"].typeText("Warranty Expiration Alert")
        
        app.buttons["When"].tap()
        app.cells["Warranty Expires In"].tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "30 days")
        app.buttons["Done"].tap()
        
        app.buttons["Then"].tap()
        app.cells["Send Notification"].tap()
        app.cells["Create Task"].tap()
        app.buttons["Done"].tap()
        
        app.buttons["Save Rule"].tap()
        
        // Step 7: Backup to cloud
        app.navigationBars.buttons["Settings"].tap()
        app.cells["Backup & Restore"].tap()
        app.buttons["Backup Now"].tap()
        
        // Select cloud provider
        app.buttons["iCloud Drive"].tap()
        
        // Monitor backup progress
        let progressView = app.progressIndicators["backup-progress"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 3))
        
        // Wait for completion
        let completionLabel = app.staticTexts["Backup Complete"]
        XCTAssertTrue(completionLabel.waitForExistence(timeout: 30))
    }
    
    // MARK: - Offline to Online Journey
    
    func testOfflineToOnlineSyncJourney() async throws {
        // Step 1: Go offline
        NetworkSimulator.setConnectivity(.offline)
        
        // Step 2: Create items offline
        let offlineItems = [
            "Offline Camera",
            "Offline Laptop",
            "Offline Headphones"
        ]
        
        for itemName in offlineItems {
            app.buttons["Add Item"].tap()
            app.textFields["Item Name"].typeText(itemName)
            app.textFields["Price"].typeText("99.99")
            app.buttons["Save"].tap()
            
            // Verify offline indicator
            XCTAssertTrue(app.images["offline-indicator"].exists)
        }
        
        // Step 3: Make edits offline
        app.cells["Offline Camera"].tap()
        app.buttons["Edit"].tap()
        app.textFields["Price"].clearAndType("199.99")
        app.textViews["Notes"].typeText("Updated while offline")
        app.buttons["Save"].tap()
        
        // Step 4: Attempt sync while offline
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Sync"].tap()
        
        // Verify sync failure message
        let offlineAlert = app.alerts["Offline Mode"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 3))
        XCTAssertTrue(offlineAlert.staticTexts["Changes will sync when online"].exists)
        offlineAlert.buttons["OK"].tap()
        
        // Step 5: Check offline queue
        app.tabBars.buttons["Settings"].tap()
        app.cells["Sync Status"].tap()
        
        XCTAssertTrue(app.staticTexts["Pending Operations: 4"].exists)
        XCTAssertTrue(app.cells["Create: Offline Camera"].exists)
        XCTAssertTrue(app.cells["Update: Offline Camera"].exists)
        
        // Step 6: Go online
        app.navigationBars.buttons["Settings"].tap()
        NetworkSimulator.setConnectivity(.wifi)
        
        // Step 7: Monitor auto-sync
        let syncIndicator = app.activityIndicators["syncing"]
        XCTAssertTrue(syncIndicator.waitForExistence(timeout: 3))
        
        // Wait for sync completion
        XCTAssertTrue(syncIndicator.waitForNonExistence(timeout: 10))
        
        // Step 8: Verify successful sync
        app.cells["Sync Status"].tap()
        XCTAssertTrue(app.staticTexts["Last Sync: Just now"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Pending Operations: 0"].exists)
        
        // Step 9: Verify on another device
        let otherDevice = SimulatedDevice(deviceId: "verify-device")
        try await otherDevice.launch(asUser: testUser)
        
        for itemName in offlineItems {
            let syncedItem = try await otherDevice.getItem(named: itemName)
            XCTAssertNotNil(syncedItem)
        }
        
        // Verify edited item
        let editedItem = try await otherDevice.getItem(named: "Offline Camera")
        XCTAssertEqual(editedItem.price, 199.99)
        XCTAssertEqual(editedItem.notes, "Updated while offline")
    }
}

// MARK: - Test Helpers

extension XCUIElement {
    func clearAndType(_ text: String) {
        guard self.exists else { return }
        
        self.tap()
        
        // Select all and delete
        self.press(forDuration: 1.0)
        
        if let selectAll = self.app.menuItems["Select All"].waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        
        self.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 50))
        self.typeText(text)
    }
    
    func tapIfExists() {
        if self.exists {
            self.tap()
        }
    }
}

var springboard: XCUIApplication {
    return XCUIApplication(bundleIdentifier: "com.apple.springboard")
}