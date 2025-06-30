import XCTest
@testable import Core
@testable import Items
@testable import BarcodeScanner
@testable import Receipts
@testable import Gmail
@testable import Sync
@testable import Premium
@testable import TestUtilities

/// End-to-end tests for complete user journeys
final class EndToEndUserJourneyTests: IntegrationTestCase {
    
    var itemService: ItemService!
    var syncService: SyncService!
    var receiptService: ReceiptService!
    var warrantyService: WarrantyService!
    
    override func setupAsync() async {
        await super.setupAsync()
        
        itemService = ItemService(database: testDatabase)
        syncService = SyncService(session: testSession)
        receiptService = ReceiptService()
        warrantyService = WarrantyService()
    }
    
    // MARK: - Complete Item Lifecycle Journey
    
    func testCompleteItemLifecycle() async throws {
        // Step 1: Create item from barcode
        let barcode = "9780134190440"
        let mockProduct = Product(
            barcode: barcode,
            name: "The Swift Programming Language",
            category: .books,
            price: 49.99,
            manufacturer: "Apple Inc."
        )
        
        // Mock barcode lookup
        MockURLProtocol.mockResponses[.test("/products/\(barcode)")] = try .json(mockProduct)
        
        let item = try await itemService.createFromBarcode(barcode)
        XCTAssertEqual(item.name, mockProduct.name)
        XCTAssertEqual(item.value, mockProduct.price)
        
        // Step 2: Add receipt
        let receiptData = TestDataBuilder.createReceipt(
            storeName: "Amazon",
            total: 49.99,
            items: [
                ReceiptItem(name: item.name, price: item.value!, quantity: 1)
            ]
        )
        
        let receipt = try await receiptService.attachReceipt(receiptData, to: item)
        XCTAssertNotNil(receipt)
        XCTAssertEqual(receipt.itemId, item.id)
        
        // Step 3: Set warranty
        let warranty = try await warrantyService.create(
            for: item,
            duration: .years(2),
            provider: "AppleCare"
        )
        XCTAssertNotNil(warranty)
        XCTAssertTrue(warranty.reminderEnabled)
        
        // Step 4: Add to collection
        let collection = try await itemService.createCollection(
            name: "Programming Books",
            description: "Technical books and references"
        )
        
        try await itemService.addToCollection(item, collection: collection)
        
        let updatedCollection = try await itemService.getCollection(id: collection.id)
        XCTAssertTrue(updatedCollection!.itemIds.contains(item.id))
        
        // Step 5: Sync item
        MockURLProtocol.mockResponses[.test("/sync")] = .json(["success": true])
        
        try await syncService.syncItem(item)
        
        let syncStatus = try await syncService.getSyncStatus(for: item)
        XCTAssertEqual(syncStatus, .synced)
        
        // Step 6: Verify complete item state
        let finalItem = try await itemService.getItem(id: item.id)!
        XCTAssertNotNil(finalItem.receipt)
        XCTAssertNotNil(finalItem.warranty)
        XCTAssertFalse(finalItem.collections.isEmpty)
        XCTAssertEqual(finalItem.syncStatus, .synced)
    }
    
    // MARK: - Family Sharing Journey
    
    func testFamilySharingJourney() async throws {
        // Step 1: Create family
        let family = try await FamilyService.createFamily(name: "The Smiths")
        XCTAssertNotNil(family)
        
        // Step 2: Invite members
        let invitations = try await family.inviteMembers([
            "spouse@example.com",
            "child@example.com"
        ])
        XCTAssertEqual(invitations.count, 2)
        
        // Step 3: Accept invitations (simulate)
        for invitation in invitations {
            MockURLProtocol.mockResponses[.test("/family/accept/\(invitation.token)")] = .json([
                "success": true,
                "memberId": UUID().uuidString
            ])
            
            try await FamilyService.acceptInvitation(token: invitation.token)
        }
        
        // Step 4: Create shared list
        let sharedList = try await itemService.createList(
            name: "Household Items",
            shared: true,
            familyId: family.id
        )
        
        // Step 5: Add items to shared list
        let items = try await createTestItems(count: 5)
        for item in items {
            try await sharedList.addItem(item)
        }
        
        // Step 6: Test concurrent editing
        let member1Task = Task {
            try await sharedList.addItem(
                TestDataBuilder.createItem(name: "Member 1 Item")
            )
        }
        
        let member2Task = Task {
            try await sharedList.addItem(
                TestDataBuilder.createItem(name: "Member 2 Item")
            )
        }
        
        _ = try await (member1Task.value, member2Task.value)
        
        // Verify both items added
        let finalList = try await itemService.getList(id: sharedList.id)!
        XCTAssertEqual(finalList.items.count, 7)
        
        // Step 7: Test permissions
        let childMember = family.members.first { $0.email == "child@example.com" }!
        XCTAssertFalse(childMember.canEdit)
        
        // Child should not be able to delete items
        do {
            try await sharedList.removeItem(items[0], asUser: childMember)
            XCTFail("Child should not be able to delete items")
        } catch {
            XCTAssertTrue(error is PermissionError)
        }
    }
    
    // MARK: - Offline to Online Sync Journey
    
    func testOfflineToOnlineSyncJourney() async throws {
        // Step 1: Go offline
        simulateNetworkCondition(.offline)
        
        // Step 2: Create items offline
        var offlineItems: [Item] = []
        for i in 0..<3 {
            let item = try await itemService.create(
                name: "Offline Item \(i)",
                value: Double(i * 100)
            )
            offlineItems.append(item)
            
            // Verify marked as pending sync
            XCTAssertEqual(item.syncStatus, .pending)
        }
        
        // Step 3: Make edits offline
        offlineItems[0].name = "Updated Offline Item"
        offlineItems[0].value = 999.99
        try await itemService.update(offlineItems[0])
        
        // Step 4: Verify offline queue
        let pendingOps = await syncService.getPendingOperations()
        XCTAssertEqual(pendingOps.count, 4) // 3 creates + 1 update
        
        // Step 5: Go online
        simulateNetworkCondition(.online)
        
        // Mock sync responses
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let data = try JSONEncoder().encode(["success": true])
            return (data, response)
        }
        
        // Step 6: Trigger sync
        try await syncService.sync()
        
        // Step 7: Verify all items synced
        for item in offlineItems {
            let syncedItem = try await itemService.getItem(id: item.id)!
            XCTAssertEqual(syncedItem.syncStatus, .synced)
        }
        
        // Verify queue cleared
        let remainingOps = await syncService.getPendingOperations()
        XCTAssertEqual(remainingOps.count, 0)
    }
    
    // MARK: - Premium Features Journey
    
    func testPremiumFeaturesJourney() async throws {
        // Ensure user is premium
        testUser.isPremium = true
        
        // Step 1: Bulk import via CSV
        let csvData = TestDataBuilder.createCSVData(itemCount: 100)
        let importService = CSVImportService()
        
        let importedItems = try await importService.importItems(from: csvData)
        XCTAssertEqual(importedItems.count, 100)
        
        // Step 2: Advanced search
        let searchService = AdvancedSearchService()
        
        let searchResults = try await searchService.search(
            query: "value:>500 AND category:electronics",
            sortBy: .value,
            ascending: false
        )
        
        XCTAssertTrue(searchResults.allSatisfy { $0.value! > 500 && $0.category == .electronics })
        
        // Step 3: Custom fields
        let customField = CustomField(
            name: "Purchase Order",
            type: .text,
            required: false
        )
        
        try await itemService.addCustomField(customField)
        
        let itemWithCustomField = importedItems[0]
        try await itemService.setCustomFieldValue(
            for: itemWithCustomField,
            field: customField,
            value: "PO-2024-001"
        )
        
        // Step 4: Analytics
        let analyticsService = AnalyticsService()
        
        let insights = try await analyticsService.generateInsights()
        XCTAssertNotNil(insights.totalValue)
        XCTAssertNotNil(insights.categoryBreakdown)
        XCTAssertNotNil(insights.depreciationReport)
        
        // Step 5: Automation rules
        let automationService = AutomationService()
        
        let rule = try await automationService.createRule(
            name: "Warranty Expiration Alert",
            trigger: .warrantyExpiring(daysBefore: 30),
            actions: [
                .sendNotification(title: "Warranty Expiring", body: "{item.name} warranty expires in 30 days"),
                .createTask(title: "Renew warranty for {item.name}")
            ]
        )
        
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule.isActive)
        
        // Step 6: Cloud backup
        let backupService = BackupService()
        
        MockURLProtocol.mockResponses[.test("/backup/upload")] = .json([
            "backupId": UUID().uuidString,
            "size": 1024 * 1024 * 10, // 10MB
            "itemCount": 100
        ])
        
        let backup = try await backupService.createBackup(
            provider: .icloud,
            encrypt: true
        )
        
        XCTAssertNotNil(backup)
        XCTAssertTrue(backup.isEncrypted)
    }
    
    // MARK: - Receipt Import Journey
    
    func testGmailReceiptImportJourney() async throws {
        // Step 1: Configure Gmail
        let gmailService = GmailService(session: testSession)
        
        // Mock Gmail auth
        MockURLProtocol.mockResponses[.test("/gmail/auth")] = .json([
            "accessToken": "mock-access-token",
            "refreshToken": "mock-refresh-token"
        ])
        
        try await gmailService.authenticate()
        
        // Step 2: Fetch receipts
        let mockEmails = [
            TestDataBuilder.createEmailMessage(
                subject: "Your Amazon order #123-456",
                from: "auto-confirm@amazon.com",
                hasAttachment: true
            ),
            TestDataBuilder.createEmailMessage(
                subject: "Best Buy Receipt",
                from: "receipts@bestbuy.com",
                hasAttachment: true
            )
        ]
        
        MockURLProtocol.mockResponses[.test("/gmail/messages")] = try .json(mockEmails)
        
        let receipts = try await gmailService.fetchReceipts(
            from: Date().addingTimeInterval(-30 * 24 * 60 * 60) // Last 30 days
        )
        
        XCTAssertEqual(receipts.count, 2)
        
        // Step 3: Process receipts
        let receiptProcessor = ReceiptProcessor()
        
        for receipt in receipts {
            let items = try await receiptProcessor.extractItems(from: receipt)
            
            // Create items from receipt
            for extractedItem in items {
                let item = try await itemService.create(
                    name: extractedItem.name,
                    value: extractedItem.price
                )
                
                // Attach receipt
                try await receiptService.attachEmailReceipt(receipt, to: item)
            }
        }
        
        // Step 4: Verify items created with receipts
        let allItems = try await itemService.getAllItems()
        let itemsWithReceipts = allItems.filter { $0.receipt != nil }
        
        XCTAssertGreaterThan(itemsWithReceipts.count, 0)
    }
}