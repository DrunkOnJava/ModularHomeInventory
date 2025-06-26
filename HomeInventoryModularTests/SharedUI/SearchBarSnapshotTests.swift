import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class SearchBarSnapshotTests: SnapshotTestCase {
    
    func testSearchBar_Empty() {
        let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
            .frame(height: 60)
            .padding()
        
        assertSnapshot(matching: searchBar, as: .image)
    }
    
    func testSearchBar_WithText() {
        let searchBar = SearchBar(text: .constant("MacBook Pro"), placeholder: "Search items...")
            .frame(height: 60)
            .padding()
        
        assertSnapshot(matching: searchBar, as: .image)
    }
    
    func testSearchBar_BothModes() {
        let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
            .frame(height: 60)
            .padding()
        
        assertSnapshotInBothModes(matching: searchBar)
    }
    
    func testSearchBar_CustomPlaceholder() {
        let searchBar = SearchBar(
            text: .constant(""),
            placeholder: "Find by name, barcode, or location..."
        )
        .frame(height: 60)
        .padding()
        
        assertSnapshot(matching: searchBar, as: .image)
    }
    
    func testSearchBar_Focused() {
        // Note: Testing focused state requires a more complex setup
        // For now, we'll test the appearance
        let searchBar = SearchBar(text: .constant("typing..."), placeholder: "Search")
            .frame(height: 60)
            .padding()
        
        assertSnapshot(matching: searchBar, as: .image)
    }
}