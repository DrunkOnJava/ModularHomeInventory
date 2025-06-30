import XCTest
import SnapshotTesting
import SwiftUI

final class MinimalWorkingSnapshot: XCTestCase {
    
    func testMinimalSnapshot() {
        withSnapshotTesting(record: .all) {
            let view = Text("Hello Snapshot Testing!")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            
            let vc = UIHostingController(rootView: view)
            vc.view.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            
            assertSnapshot(matching: vc, as: .image)
        }
    }
}