//
//  ItemsListViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for ItemsListView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class ItemsListViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockItems: [Item] {
        [
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
                notes: "Work laptop with AppleCare+",
                tags: ["work", "electronics", "apple"],
                photos: [],
                documents: [],
                receipts: [],
                warranty: Warranty(
                    expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    provider: "Apple",
                    coverage: "AppleCare+"
                ),
                maintenanceHistory: [],
                manuals: [],
                currentValue: 2100.00,
                condition: "Excellent",
                quantity: 1,
                barcode: "194253082194",
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
            ),
            Item(
                id: UUID(),
                name: "Sony WH-1000XM5",
                brand: "Sony",
                model: "WH-1000XM5",
                serialNumber: "4901780157532",
                purchaseDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                purchasePrice: 399.99,
                currency: "USD",
                category: .electronics,
                location: "Living Room",
                storageUnitId: nil,
                notes: "Noise cancelling headphones",
                tags: ["audio", "electronics"],
                photos: [],
                documents: [],
                receipts: [],
                warranty: Warranty(
                    expirationDate: Date().addingTimeInterval(305 * 24 * 60 * 60),
                    provider: "Sony",
                    coverage: "Standard Warranty"
                ),
                maintenanceHistory: [],
                manuals: [],
                currentValue: 350.00,
                condition: "Like New",
                quantity: 1,
                barcode: "4901780157532",
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
            ),
            Item(
                id: UUID(),
                name: "Kitchen Aid Stand Mixer",
                brand: "KitchenAid",
                model: "KSM150PSER",
                serialNumber: "W10834523",
                purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                purchasePrice: 279.99,
                currency: "USD",
                category: .appliances,
                location: "Kitchen",
                storageUnitId: nil,
                notes: "Red color, 5-quart bowl",
                tags: ["kitchen", "cooking"],
                photos: [],
                documents: [],
                receipts: [],
                warranty: nil,
                maintenanceHistory: [],
                manuals: [],
                currentValue: 200.00,
                condition: "Good",
                quantity: 1,
                barcode: "883049521428",
                qrCode: nil,
                customFields: [:],
                dateAdded: Date(),
                lastModified: Date(),
                createdBy: "user123",
                isShared: true,
                sharedWith: ["family"],
                isDeleted: false,
                syncMetadata: nil,
                attachments: [],
                versionHistory: [],
                linkedItems: [],
                insuranceInfo: nil,
                customAttributes: nil
            )
        ]
    }
    
    // MARK: - Tests
    
    func testItemsList_Default() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_Empty() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant([]),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_WithSearch() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant("Sony"),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_WithCategoryFilter() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(.electronics),
                sortOption: .constant(.name),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_MultipleSelection() {
        withSnapshotTesting(record: .all) {
            let selectedIds = Set(mockItems.prefix(2).map { $0.id })
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(selectedIds),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_iPad() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testItemsList_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testItemsList_Accessibility() {
        withSnapshotTesting(record: .all) {
            let view = ItemsListView(
                items: .constant(mockItems),
                selectedItems: .constant(Set()),
                searchText: .constant(""),
                selectedCategory: .constant(nil),
                sortOption: .constant(.dateAdded),
                showingAddItem: .constant(false)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(
                of: hostingController,
                as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .accessibilityLarge))
            )
        }
    }
}