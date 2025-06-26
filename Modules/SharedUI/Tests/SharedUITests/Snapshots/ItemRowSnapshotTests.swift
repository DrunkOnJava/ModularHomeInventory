//
//  ItemRowSnapshotTests.swift
//  SharedUITests
//
//  Example snapshot test for ItemRow component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core

final class ItemRowSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Uncomment to record new snapshots
        // isRecording = true
    }
    
    // MARK: - Basic Tests
    
    func testItemRow_default() {
        let item = Item(
            name: "MacBook Pro",
            category: .electronics,
            purchasePrice: 2499.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_withWarranty() {
        var item = Item(
            name: "Coffee Maker",
            category: .appliances,
            purchasePrice: 149.99,
            brand: "Breville"
        )
        item.warrantyExpiration = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_multiplePhotos() {
        var item = Item(
            name: "Gaming Console",
            category: .electronics,
            purchasePrice: 499.99,
            brand: "Sony"
        )
        item.photos = [
            ItemPhoto(data: Data(), isMainPhoto: true),
            ItemPhoto(data: Data(), isMainPhoto: false),
            ItemPhoto(data: Data(), isMainPhoto: false)
        ]
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Dark Mode Tests
    
    func testItemRow_darkMode() {
        let item = Item(
            name: "iPhone 15 Pro",
            category: .electronics,
            purchasePrice: 999.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
            .environment(\.colorScheme, .dark)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Accessibility Tests
    
    func testItemRow_largeText() {
        let item = Item(
            name: "Desk Lamp with Adjustable Brightness",
            category: .furniture,
            purchasePrice: 89.99,
            brand: "IKEA"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
            .environment(\.sizeCategory, .accessibilityLarge)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Edge Cases
    
    func testItemRow_longName() {
        let item = Item(
            name: "Ultra-Wide 49-inch Curved Gaming Monitor with HDR1000 and 240Hz Refresh Rate",
            category: .electronics,
            purchasePrice: 1299.99,
            brand: "Samsung"
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testItemRow_noPrice() {
        let item = Item(
            name: "Gift Item",
            category: .other,
            purchasePrice: nil,
            brand: nil
        )
        
        let view = ItemRow(item: item) {}
            .frame(width: 375)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    // MARK: - Device Specific Tests
    
    func testItemRow_iPhone() {
        let item = Item(
            name: "AirPods Pro",
            category: .electronics,
            purchasePrice: 249.99,
            brand: "Apple"
        )
        
        let view = ItemRow(item: item) {}
        
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(config: .iPhone13))
        )
    }
    
    func testItemRow_iPad() {
        let item = Item(
            name: "Smart Home Hub",
            category: .electronics,
            purchasePrice: 199.99,
            brand: "Google"
        )
        
        let view = ItemRow(item: item) {}
        
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(config: .iPadPro11))
        )
    }
}