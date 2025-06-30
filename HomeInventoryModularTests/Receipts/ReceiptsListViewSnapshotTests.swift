//
//  ReceiptsListViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for ReceiptsListView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Receipts
@testable import Core
@testable import SharedUI

final class ReceiptsListViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockReceipts: [Receipt] {
        [
            Receipt(
                id: UUID(),
                itemId: UUID(),
                storeName: "Apple Store",
                purchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                totalAmount: 2499.00,
                taxAmount: 224.91,
                currency: "USD",
                paymentMethod: "Credit Card",
                receiptNumber: "R-2024-001234",
                category: .electronics,
                items: [
                    ReceiptItem(
                        name: "MacBook Pro 16\"",
                        quantity: 1,
                        unitPrice: 2499.00,
                        totalPrice: 2499.00,
                        sku: "MKGR3LL/A"
                    )
                ],
                imageData: nil,
                ocrText: nil,
                tags: ["electronics", "apple", "laptop"],
                notes: "Business purchase - tax deductible",
                warranty: ReceiptWarranty(
                    duration: 12,
                    startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60)
                ),
                returnPolicy: ReturnPolicy(
                    days: 14,
                    conditions: "Original packaging required"
                ),
                digitalCopy: true,
                isVerified: true,
                source: .manual,
                createdAt: Date(),
                modifiedAt: Date()
            ),
            Receipt(
                id: UUID(),
                itemId: UUID(),
                storeName: "Best Buy",
                purchaseDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                totalAmount: 399.99,
                taxAmount: 35.99,
                currency: "USD",
                paymentMethod: "Debit Card",
                receiptNumber: "BB-20240115-789",
                category: .electronics,
                items: [
                    ReceiptItem(
                        name: "Sony WH-1000XM5",
                        quantity: 1,
                        unitPrice: 399.99,
                        totalPrice: 399.99,
                        sku: "6505727"
                    )
                ],
                imageData: nil,
                ocrText: nil,
                tags: ["audio", "headphones"],
                notes: nil,
                warranty: ReceiptWarranty(
                    duration: 24,
                    startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60)
                ),
                returnPolicy: ReturnPolicy(
                    days: 30,
                    conditions: "Unopened items only"
                ),
                digitalCopy: true,
                isVerified: false,
                source: .scanned,
                createdAt: Date(),
                modifiedAt: Date()
            ),
            Receipt(
                id: UUID(),
                itemId: nil, // Unlinked receipt
                storeName: "Home Depot",
                purchaseDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                totalAmount: 156.78,
                taxAmount: 14.10,
                currency: "USD",
                paymentMethod: "Cash",
                receiptNumber: "HD-2023-456789",
                category: .homeGarden,
                items: [
                    ReceiptItem(
                        name: "Drill Set",
                        quantity: 1,
                        unitPrice: 89.99,
                        totalPrice: 89.99,
                        sku: "1001234567"
                    ),
                    ReceiptItem(
                        name: "Screwdriver Set",
                        quantity: 1,
                        unitPrice: 29.99,
                        totalPrice: 29.99,
                        sku: "1007654321"
                    ),
                    ReceiptItem(
                        name: "Tool Box",
                        quantity: 1,
                        unitPrice: 22.70,
                        totalPrice: 22.70,
                        sku: "1009876543"
                    )
                ],
                imageData: nil,
                ocrText: nil,
                tags: ["tools", "home improvement"],
                notes: "Home renovation project",
                warranty: nil,
                returnPolicy: ReturnPolicy(
                    days: 90,
                    conditions: "With receipt"
                ),
                digitalCopy: false,
                isVerified: true,
                source: .email,
                createdAt: Date(),
                modifiedAt: Date()
            )
        ]
    }
    
    // MARK: - Tests
    
    func testReceiptsList_Default() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_Empty() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: [],
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_WithSearch() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant("Apple"),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_Filtered() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(
                    ReceiptFilterOptions(
                        categories: [.electronics],
                        dateRange: .lastMonth,
                        minAmount: 100,
                        maxAmount: 3000,
                        verifiedOnly: true
                    )
                )
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_MultipleSelection() {
        withSnapshotTesting(record: .all) {
            let selectedIds = Set(mockReceipts.prefix(2).map { $0.id })
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(selectedIds),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_GroupedByMonth() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions()),
                groupBy: .month
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_UnlinkedOnly() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(
                    ReceiptFilterOptions(showUnlinkedOnly: true)
                )
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptsList_iPad() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testReceiptsList_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptsListView(
                receipts: mockReceipts,
                selectedReceipts: .constant(Set()),
                searchText: .constant(""),
                filterOptions: .constant(ReceiptFilterOptions())
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}