import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core

final class ItemCardSnapshotTests: SnapshotTestCase {
    
    func testItemCard_Standard() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_DarkMode() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone15, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testItemCard_NoPhoto() {
        var item = Item.sample
        item.photos = []
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_LongName() {
        var item = Item.sample
        item.name = "This is a very long item name that should wrap to multiple lines and test the layout"
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_HighValue() {
        var item = Item.sample
        item.purchasePrice = 9999.99
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPhone15))
    }
    
    func testItemCard_iPad() {
        let item = Item.sample
        let card = ItemCard(item: item)
        let view = card
            .frame(width: 450)
            .padding()
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
}

// Helper extension for sample data
extension Item {
    static var sample: Item {
        Item(
            id: UUID(),
            name: "MacBook Pro 16\"",
            description: "2023 M3 Max MacBook Pro",
            category: .electronics,
            locationId: UUID(),
            purchaseDate: Date(),
            purchasePrice: 3499.99,
            currency: "USD",
            serialNumber: "C02XK2JKML87",
            modelNumber: "MRW33LL/A",
            manufacturer: "Apple",
            photos: [Photo(id: UUID(), data: Data(), thumbnailData: nil)],
            tags: ["laptop", "work", "apple"],
            quantity: 1,
            notes: "Primary work computer",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Define iPhone 15 device for consistency
extension ViewImageConfig {
    static let iPhone15 = ViewImageConfig.iPhone13
    static let iPhone15Pro = ViewImageConfig.iPhone13Pro
    static let iPhone15ProMax = ViewImageConfig.iPhone13ProMax
}