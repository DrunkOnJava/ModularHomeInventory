//
//  ReceiptDetailViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for ReceiptDetailView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Receipts
@testable import Core
@testable import SharedUI

final class ReceiptDetailViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockReceipt: Receipt {
        Receipt(
            id: UUID(),
            itemId: UUID(),
            storeName: "Apple Store",
            purchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            totalAmount: 2723.91,
            taxAmount: 224.91,
            currency: "USD",
            paymentMethod: "Apple Card",
            receiptNumber: "R-2024-001234",
            category: .electronics,
            items: [
                ReceiptItem(
                    name: "MacBook Pro 16\" M2 Max",
                    quantity: 1,
                    unitPrice: 2499.00,
                    totalPrice: 2499.00,
                    sku: "MKGR3LL/A",
                    description: "32GB RAM, 1TB SSD, Space Gray"
                ),
                ReceiptItem(
                    name: "AppleCare+ for MacBook Pro",
                    quantity: 1,
                    unitPrice: 399.00,
                    totalPrice: 399.00,
                    sku: "S8536LL/A",
                    description: "3-year protection plan"
                ),
                ReceiptItem(
                    name: "USB-C to MagSafe 3 Cable",
                    quantity: 1,
                    unitPrice: 49.00,
                    totalPrice: 49.00,
                    sku: "MLYV3AM/A",
                    description: "2m cable"
                )
            ],
            imageData: nil,
            ocrText: "APPLE STORE\nReceipt #R-2024-001234\n...",
            tags: ["electronics", "apple", "laptop", "business"],
            notes: "Business purchase - tax deductible. Includes extended warranty.",
            warranty: ReceiptWarranty(
                duration: 36,
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                provider: "AppleCare+",
                terms: "Covers hardware repairs and software support"
            ),
            returnPolicy: ReturnPolicy(
                days: 14,
                conditions: "Original packaging required, no damage",
                restockingFee: 0
            ),
            digitalCopy: true,
            isVerified: true,
            source: .email,
            merchantInfo: MerchantInfo(
                name: "Apple Store",
                address: "One Apple Park Way, Cupertino, CA 95014",
                phone: "1-800-MY-APPLE",
                email: "receipt@apple.com",
                website: "apple.com"
            ),
            createdAt: Date(),
            modifiedAt: Date()
        )
    }
    
    private var mockReceiptMinimal: Receipt {
        Receipt(
            id: UUID(),
            itemId: nil,
            storeName: "Local Store",
            purchaseDate: Date(),
            totalAmount: 25.99,
            taxAmount: 2.34,
            currency: "USD",
            paymentMethod: "Cash",
            receiptNumber: nil,
            category: .other,
            items: [
                ReceiptItem(
                    name: "Miscellaneous Item",
                    quantity: 1,
                    unitPrice: 23.65,
                    totalPrice: 23.65
                )
            ],
            imageData: nil,
            ocrText: nil,
            tags: [],
            notes: nil,
            warranty: nil,
            returnPolicy: nil,
            digitalCopy: false,
            isVerified: false,
            source: .manual,
            merchantInfo: nil,
            createdAt: Date(),
            modifiedAt: Date()
        )
    }
    
    // MARK: - Tests
    
    func testReceiptDetail_Complete() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptDetailView(receipt: mockReceipt)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_Minimal() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptDetailView(receipt: mockReceiptMinimal)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_WithImage() {
        withSnapshotTesting(record: .all) {
            var receipt = mockReceipt
            // Simulate receipt with image
            receipt.hasImage = true
            
            let view = ReceiptDetailView(receipt: receipt)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_Unverified() {
        withSnapshotTesting(record: .all) {
            var receipt = mockReceipt
            receipt.isVerified = false
            
            let view = ReceiptDetailView(receipt: receipt)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_ReturnPeriodActive() {
        withSnapshotTesting(record: .all) {
            var receipt = mockReceipt
            receipt.purchaseDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            receipt.returnPolicy = ReturnPolicy(
                days: 14,
                conditions: "Original packaging required"
            )
            
            let view = ReceiptDetailView(receipt: receipt)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_ReturnPeriodExpired() {
        withSnapshotTesting(record: .all) {
            var receipt = mockReceipt
            receipt.returnPolicy = ReturnPolicy(
                days: 14,
                conditions: "Original packaging required"
            )
            // purchaseDate is 30 days ago, so return period expired
            
            let view = ReceiptDetailView(receipt: receipt)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_iPad() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptDetailView(receipt: mockReceipt)
                .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testReceiptDetail_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptDetailView(receipt: mockReceipt)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testReceiptDetail_EditMode() {
        withSnapshotTesting(record: .all) {
            let view = ReceiptDetailView(
                receipt: mockReceipt,
                isEditing: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}