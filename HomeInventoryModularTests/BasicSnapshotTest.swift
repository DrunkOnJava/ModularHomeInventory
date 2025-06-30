import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class BasicSnapshotTest: XCTestCase {
    
    func testBasicSnapshot() {
        // Enable recording mode
        withSnapshotTesting(record: .all) {
            // Create a simple view
            let view = VStack {
                Text("Home Inventory")
                    .font(.largeTitle)
                    .padding()
                
                SearchBar(text: .constant(""), placeholder: "Search items...")
                    .padding()
                
                PrimaryButton(title: "Add Item", action: {})
                    .padding()
            }
            .frame(width: 375, height: 300)
            .background(Color.white)
            
            // Create hosting controller
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 300)
            
            // Take snapshot
            assertSnapshot(matching: hostingController, as: .image)
        }
    }
}