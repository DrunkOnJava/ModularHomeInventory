import XCTest
@testable import Core
@testable import Items
@testable import BarcodeScanner
@testable import Receipts
@testable import Gmail
@testable import Sync
@testable import Premium
@testable import AppSettings
@testable import TestUtilities

/// Tests for cross-module integration scenarios
final class CrossModuleIntegrationTests: IntegrationTestCase {
    
    // MARK: - Barcode Scanner + Items Integration
    
    func testBarcodeScannerToItemCreation() async throws {
        let barcodeService = BarcodeScannerService()
        let itemService = ItemService(database: testDatabase)
        let productLookupService = ProductLookupService(session: testSession)
        
        // Mock barcode scan result
        let barcode = "1234567890123"
        
        // Mock product lookup
        let mockProduct = Product(
            barcode: barcode,
            name: "iPhone 15 Pro",
            category: .electronics,
            price: 999.99,
            manufacturer: "Apple Inc.",
            imageURL: URL(string: "https://example.com/iphone.jpg")
        )
        
        MockURLProtocol.mockResponses[.test("/products/\(barcode)")] = try .json(mockProduct)
        
        // Scan barcode and create item
        let product = try await productLookupService.lookup(barcode: barcode)
        XCTAssertEqual(product.name, mockProduct.name)
        
        // Create item from product
        let item = try await itemService.createFromProduct(product)
        
        XCTAssertEqual(item.name, product.name)
        XCTAssertEqual(item.value, product.price)
        XCTAssertEqual(item.category, product.category)
        XCTAssertEqual(item.barcode, barcode)
        
        // Verify item stored in database
        let storedItem = try await itemService.getItem(id: item.id)
        XCTAssertNotNil(storedItem)
    }
    
    // MARK: - Gmail + Receipts Integration
    
    func testGmailReceiptImportIntegration() async throws {
        let gmailService = GmailService(session: testSession)
        let receiptService = ReceiptService()
        let itemService = ItemService(database: testDatabase)
        
        // Mock Gmail messages
        let mockMessages = [
            GmailMessage(
                id: "msg1",
                threadId: "thread1",
                subject: "Your Amazon Order #123-456",
                from: "auto-confirm@amazon.com",
                date: Date(),
                snippet: "Order confirmation for MacBook Pro",
                attachments: [
                    GmailAttachment(
                        id: "att1",
                        filename: "receipt.pdf",
                        mimeType: "application/pdf",
                        size: 50000
                    )
                ]
            )
        ]
        
        MockURLProtocol.mockResponses[.test("/gmail/messages")] = try .json(mockMessages)
        
        // Mock attachment download
        MockURLProtocol.mockResponses[.test("/gmail/attachments/att1")] = MockResponse(
            data: TestFixtures.sampleReceiptPDF,
            headers: ["Content-Type": "application/pdf"]
        )
        
        // Import receipts
        let importedReceipts = try await gmailService.importReceipts(
            since: Date().addingTimeInterval(-7 * 24 * 60 * 60)
        )
        
        XCTAssertEqual(importedReceipts.count, 1)
        
        // Process receipt
        let receipt = importedReceipts[0]
        let extractedData = try await receiptService.extractData(from: receipt)
        
        // Create items from receipt
        let items = try await itemService.createFromReceiptData(extractedData)
        XCTAssertGreaterThan(items.count, 0)
        
        // Verify receipt attached to items
        for item in items {
            XCTAssertNotNil(item.receipt)
            XCTAssertEqual(item.receipt?.source, .gmail)
        }
    }
    
    // MARK: - Settings + Sync Integration
    
    func testSettingsSyncIntegration() async throws {
        let settingsService = SettingsService()
        let syncService = SyncService(session: testSession)
        
        // Update settings
        try await settingsService.update { settings in
            settings.defaultCurrency = .EUR
            settings.enableBiometrics = true
            settings.autoBackupEnabled = true
            settings.theme = .dark
        }
        
        // Mock sync endpoint
        var capturedSettings: Settings?
        MockURLProtocol.mockHandler = { request in
            if request.url?.path == "/sync/settings" {
                let data = request.httpBody!
                capturedSettings = try JSONDecoder().decode(Settings.self, from: data)
            }
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        // Sync settings
        try await syncService.syncSettings()
        
        // Verify settings were synced
        XCTAssertNotNil(capturedSettings)
        XCTAssertEqual(capturedSettings?.defaultCurrency, .EUR)
        XCTAssertEqual(capturedSettings?.enableBiometrics, true)
        
        // Simulate settings sync from another device
        let remoteSettings = Settings(
            defaultCurrency: .GBP,
            enableBiometrics: true,
            autoBackupEnabled: false,
            theme: .light
        )
        
        MockURLProtocol.mockResponses[.test("/sync/settings")] = try .json(remoteSettings)
        
        // Pull settings
        try await syncService.pullSettings()
        
        // Verify merged settings
        let currentSettings = await settingsService.currentSettings
        XCTAssertEqual(currentSettings.defaultCurrency, .GBP) // Remote wins for currency
        XCTAssertEqual(currentSettings.enableBiometrics, true) // Both agree
    }
    
    // MARK: - Premium + Analytics Integration
    
    func testPremiumAnalyticsIntegration() async throws {
        let premiumService = PremiumService()
        let analyticsService = AnalyticsService()
        let itemService = ItemService(database: testDatabase)
        
        // Verify premium features disabled initially
        XCTAssertFalse(await premiumService.hasAccess(to: .advancedAnalytics))
        
        // Enable premium
        try await premiumService.activatePremium(receipt: "mock-receipt")
        
        // Verify premium features enabled
        XCTAssertTrue(await premiumService.hasAccess(to: .advancedAnalytics))
        
        // Create test data
        let items = try await createTestItems(count: 100)
        
        // Use premium analytics features
        let insights = try await analyticsService.generatePremiumInsights()
        
        XCTAssertNotNil(insights.predictiveAnalysis)
        XCTAssertNotNil(insights.trendForecasting)
        XCTAssertNotNil(insights.anomalyDetection)
        
        // Test depreciation calculation (premium feature)
        let depreciationReport = try await analyticsService.calculateDepreciation(
            method: .straightLine,
            customRates: true
        )
        
        XCTAssertEqual(depreciationReport.items.count, items.count)
        XCTAssertGreaterThan(depreciationReport.totalDepreciation, 0)
    }
    
    // MARK: - Items + Warranties + Notifications Integration
    
    func testWarrantyNotificationIntegration() async throws {
        let itemService = ItemService(database: testDatabase)
        let warrantyService = WarrantyService()
        let notificationService = NotificationService()
        
        // Create item with warranty
        let item = try await itemService.create(
            name: "MacBook Pro",
            value: 2499.99,
            category: .electronics
        )
        
        // Add warranty expiring in 30 days
        let warranty = try await warrantyService.create(
            for: item,
            startDate: Date().addingTimeInterval(-335 * 24 * 60 * 60), // 335 days ago
            duration: .years(1),
            reminderDays: [30, 7, 1]
        )
        
        // Check for warranty notifications
        let notifications = await notificationService.checkWarrantyNotifications()
        
        // Should have notification for 30-day warning
        let warrantyNotification = notifications.first { 
            $0.itemId == item.id && $0.type == .warrantyExpiring
        }
        
        XCTAssertNotNil(warrantyNotification)
        XCTAssertEqual(warrantyNotification?.daysUntilExpiry, 30)
        
        // Schedule notification
        try await notificationService.schedule(warrantyNotification!)
        
        // Verify notification scheduled
        let pendingNotifications = await notificationService.getPendingNotifications()
        XCTAssertTrue(pendingNotifications.contains { $0.id == warrantyNotification?.id })
    }
    
    // MARK: - Search + Multiple Modules Integration
    
    func testUniversalSearchIntegration() async throws {
        let searchService = UniversalSearchService()
        let itemService = ItemService(database: testDatabase)
        let receiptService = ReceiptService()
        let warrantyService = WarrantyService()
        
        // Create diverse test data
        let item1 = try await itemService.create(
            name: "Sony WH-1000XM5",
            value: 399.99,
            category: .electronics,
            serialNumber: "SN123456"
        )
        
        let receipt1 = try await receiptService.create(
            storeName: "Best Buy",
            date: Date(),
            total: 399.99,
            items: [ReceiptItem(name: "Sony Headphones", price: 399.99, quantity: 1)]
        )
        
        try await receiptService.attachReceipt(receipt1, to: item1)
        
        let warranty1 = try await warrantyService.create(
            for: item1,
            duration: .years(2),
            provider: "Sony Extended Warranty"
        )
        
        // Search across all modules
        let searchResults = try await searchService.search(query: "Sony")
        
        XCTAssertTrue(searchResults.items.contains { $0.id == item1.id })
        XCTAssertTrue(searchResults.receipts.contains { $0.id == receipt1.id })
        XCTAssertTrue(searchResults.warranties.contains { $0.id == warranty1.id })
        
        // Test advanced search
        let advancedResults = try await searchService.advancedSearch(
            query: "warranty:active AND value:>300"
        )
        
        XCTAssertTrue(advancedResults.items.contains { $0.id == item1.id })
    }
    
    // MARK: - Backup + Restore Integration
    
    func testBackupRestoreIntegration() async throws {
        let backupService = BackupService()
        let itemService = ItemService(database: testDatabase)
        
        // Create test data
        let originalItems = try await createTestItems(count: 50)
        
        // Create backup
        let backup = try await backupService.createBackup(
            includeImages: true,
            compress: true,
            encrypt: true,
            password: "test-password"
        )
        
        XCTAssertNotNil(backup)
        XCTAssertGreaterThan(backup.size, 0)
        XCTAssertTrue(backup.isEncrypted)
        
        // Clear database
        try await testDatabase.deleteAll()
        
        // Verify data cleared
        let itemsAfterClear = try await itemService.getAllItems()
        XCTAssertEqual(itemsAfterClear.count, 0)
        
        // Restore from backup
        try await backupService.restore(
            from: backup,
            password: "test-password",
            merge: false
        )
        
        // Verify data restored
        let restoredItems = try await itemService.getAllItems()
        XCTAssertEqual(restoredItems.count, originalItems.count)
        
        // Verify item details preserved
        for originalItem in originalItems {
            let restoredItem = restoredItems.first { $0.id == originalItem.id }
            XCTAssertNotNil(restoredItem)
            XCTAssertEqual(restoredItem?.name, originalItem.name)
            XCTAssertEqual(restoredItem?.value, originalItem.value)
        }
    }
}