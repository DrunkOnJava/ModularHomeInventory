import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class ItemDetailViewSnapshotTests: SnapshotTestCase {
    
    func testItemDetailView_Complete() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15ProMax))
    }
    
    func testItemDetailView_Minimal() {
        let item = Item.sampleMinimal
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15ProMax))
    }
    
    func testItemDetailView_DarkMode() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone15ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testItemDetailView_iPad() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
    
    func testItemDetailView_AccessibilityLarge() {
        let item = Item.sampleComplete
        let view = NavigationStack {
            ItemDetailView(item: item)
        }
        
        assertSnapshot(
            matching: view,
            as: .image(
                on: .iPhone15ProMax,
                traits: .init(preferredContentSizeCategory: .accessibilityLarge)
            )
        )
    }
}

// Extended sample data
extension Item {
    static var sampleComplete: Item {
        Item(
            id: UUID(),
            name: "Sony A7R V Camera",
            description: "Professional full-frame mirrorless camera with 61MP sensor",
            category: .electronics,
            locationId: UUID(),
            purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
            purchasePrice: 3899.99,
            currency: "USD",
            serialNumber: "SN1234567890",
            modelNumber: "ILCE-7RM5",
            manufacturer: "Sony",
            photos: [
                Photo(id: UUID(), data: Data(), thumbnailData: nil),
                Photo(id: UUID(), data: Data(), thumbnailData: nil),
                Photo(id: UUID(), data: Data(), thumbnailData: nil)
            ],
            tags: ["camera", "photography", "professional", "sony"],
            quantity: 1,
            notes: "Purchased with 2-year warranty. Includes original box and all accessories.",
            warranty: Warranty(
                id: UUID(),
                itemId: UUID(),
                provider: "Sony",
                startDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(550 * 24 * 60 * 60), // ~1.5 years from now
                type: .manufacturer,
                notes: "Extended warranty purchased"
            ),
            receipt: Receipt(
                id: UUID(),
                itemId: UUID(),
                storeName: "B&H Photo",
                purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                totalAmount: 3899.99,
                taxAmount: 312.00,
                currency: "USD"
            ),
            createdAt: Date().addingTimeInterval(-180 * 24 * 60 * 60),
            updatedAt: Date()
        )
    }
    
    static var sampleMinimal: Item {
        Item(
            id: UUID(),
            name: "Coffee Maker",
            description: nil,
            category: .appliances,
            locationId: UUID(),
            purchaseDate: nil,
            purchasePrice: nil,
            currency: "USD",
            serialNumber: nil,
            modelNumber: nil,
            manufacturer: nil,
            photos: [],
            tags: [],
            quantity: 1,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}