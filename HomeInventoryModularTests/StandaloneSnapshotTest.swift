//
//  StandaloneSnapshotTest.swift
//  HomeInventoryModularTests
//
//  Standalone snapshot test to generate app UI snapshots
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import HomeInventoryModular
@testable import Items
@testable import Core
@testable import SharedUI

final class StandaloneSnapshotTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Record mode for generating snapshots
        isRecording = false
    }
    
    func testMainTabView() {
        let tabView = ContentView()
            .environmentObject(AppState())
        
        let hostingController = UIHostingController(rootView: tabView)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testItemsListView() {
        let mockItems = [
            Item(
                name: "MacBook Pro",
                brand: "Apple",
                model: "16-inch",
                purchasePrice: 2499,
                currency: "USD",
                category: .electronics,
                location: "Office"
            ),
            Item(
                name: "iPhone 15 Pro",
                brand: "Apple", 
                model: "A3102",
                purchasePrice: 999,
                currency: "USD",
                category: .electronics,
                location: "Personal"
            )
        ]
        
        let view = NavigationView {
            ItemsListView(items: .constant(mockItems))
        }
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAddItemView() {
        let view = NavigationView {
            AddItemView(isPresented: .constant(true))
                .environmentObject(AppState())
        }
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}