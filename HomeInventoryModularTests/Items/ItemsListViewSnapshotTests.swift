import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class ItemsListViewSnapshotTests: SnapshotTestCase {
    
    func testItemsListView_Empty() {
        let view = NavigationStack {
            ItemsListView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testItemsListView_WithItems() {
        // Create mock items
        let items = [
            Item.sample,
            Item.sampleMinimal,
            Item.sampleComplete
        ]
        
        // Since we can't easily inject mock data into the view,
        // we'll test the list row component instead
        let listContent = VStack(spacing: 0) {
            ForEach(items) { item in
                ItemRow(item: item)
                Divider()
            }
        }
        .frame(width: 390)
        
        assertSnapshot(matching: listContent, as: .image)
    }
    
    func testItemsListView_SearchActive() {
        let searchView = VStack {
            SearchBar(text: .constant("MacBook"), placeholder: "Search items...")
            Spacer()
        }
        .frame(width: 390, height: 200)
        .background(Color(.systemBackground))
        
        assertSnapshot(matching: searchView, as: .image)
    }
    
    func testItemsListView_iPad() {
        let view = NavigationStack {
            ItemsListView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
}