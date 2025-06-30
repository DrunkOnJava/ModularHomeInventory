//
//  ItemDetailViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for ItemDetailView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class ItemDetailViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockItem: Item {
        Item(
            id: UUID(),
            name: "MacBook Pro 16\"",
            brand: "Apple",
            model: "A2991",
            serialNumber: "C02XG2JJMD6N",
            purchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            purchasePrice: 2499.00,
            currency: "USD",
            category: .electronics,
            location: "Home Office",
            storageUnitId: UUID(),
            notes: "Work laptop with AppleCare+. Purchased for development work. Includes Magic Mouse and keyboard.",
            tags: ["work", "electronics", "apple", "laptop", "development"],
            photos: [],
            documents: [],
            receipts: [],
            warranty: Warranty(
                expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                provider: "Apple",
                coverage: "AppleCare+ (2 years)"
            ),
            maintenanceHistory: [
                MaintenanceRecord(
                    id: UUID(),
                    itemId: UUID(),
                    date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                    type: "Cleaning",
                    description: "Professional cleaning and thermal paste replacement",
                    cost: 150.00,
                    provider: "Apple Store",
                    notes: "Running cooler after service",
                    documents: []
                )
            ],
            manuals: [],
            currentValue: 2100.00,
            condition: "Excellent",
            quantity: 1,
            barcode: "194253082194",
            qrCode: nil,
            customFields: [
                "RAM": "32GB",
                "Storage": "1TB SSD",
                "Processor": "M2 Max"
            ],
            dateAdded: Date(),
            lastModified: Date(),
            createdBy: "user123",
            isShared: false,
            sharedWith: [],
            isDeleted: false,
            syncMetadata: nil,
            attachments: [],
            versionHistory: [],
            linkedItems: [],
            insuranceInfo: InsuranceInfo(
                provider: "State Farm",
                policyNumber: "POL-123456",
                coverageAmount: 3000.00,
                deductible: 250.00,
                startDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                premium: 120.00,
                documents: []
            ),
            customAttributes: nil
        )
    }
    
    private var mockItemMinimal: Item {
        Item(
            id: UUID(),
            name: "USB Cable",
            brand: nil,
            model: nil,
            serialNumber: nil,
            purchaseDate: nil,
            purchasePrice: 9.99,
            currency: "USD",
            category: .other,
            location: "Drawer",
            storageUnitId: nil,
            notes: nil,
            tags: [],
            photos: [],
            documents: [],
            receipts: [],
            warranty: nil,
            maintenanceHistory: [],
            manuals: [],
            currentValue: 5.00,
            condition: "Good",
            quantity: 3,
            barcode: nil,
            qrCode: nil,
            customFields: [:],
            dateAdded: Date(),
            lastModified: Date(),
            createdBy: "user123",
            isShared: false,
            sharedWith: [],
            isDeleted: false,
            syncMetadata: nil,
            attachments: [],
            versionHistory: [],
            linkedItems: [],
            insuranceInfo: nil,
            customAttributes: nil
        )
    }
    
    // MARK: - Tests
    
    func testItemDetail_Complete() {
        withSnapshotTesting(record: .all) {
            let view = ItemDetailView(item: mockItem)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_Minimal() {
        withSnapshotTesting(record: .all) {
            let view = ItemDetailView(item: mockItemMinimal)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_WarrantyExpiring() {
        withSnapshotTesting(record: .all) {
            var item = mockItem
            item.warranty = Warranty(
                expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
                provider: "Apple",
                coverage: "AppleCare+"
            )
            
            let view = ItemDetailView(item: item)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_WarrantyExpired() {
        withSnapshotTesting(record: .all) {
            var item = mockItem
            item.warranty = Warranty(
                expirationDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                provider: "Apple",
                coverage: "AppleCare+"
            )
            
            let view = ItemDetailView(item: item)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_iPad() {
        withSnapshotTesting(record: .all) {
            let view = ItemDetailView(item: mockItem)
                .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testItemDetail_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = ItemDetailView(item: mockItem)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_ScrolledToBottom() {
        withSnapshotTesting(record: .all) {
            let scrollView = ScrollView {
                ItemDetailView(item: mockItem)
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: scrollView)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_Shared() {
        withSnapshotTesting(record: .all) {
            var item = mockItem
            item.isShared = true
            item.sharedWith = ["john@example.com", "jane@example.com", "family"]
            
            let view = ItemDetailView(item: item)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemDetail_MultipleQuantity() {
        withSnapshotTesting(record: .all) {
            var item = mockItem
            item.quantity = 5
            
            let view = ItemDetailView(item: item)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}