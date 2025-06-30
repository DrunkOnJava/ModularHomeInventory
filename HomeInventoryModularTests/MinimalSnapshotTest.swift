import XCTest
import SnapshotTesting
import SwiftUI

class MinimalSnapshotTest: XCTestCase {
    func testSimpleView() {
        isRecording = false
        
        let view = Text("Hello Snapshot Testing\!")
            .font(.largeTitle)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(matching: hostingController, as: .image(on: .iPhone13))
    }
}
EOF < /dev/null