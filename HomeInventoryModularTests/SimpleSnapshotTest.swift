import XCTest
import SnapshotTesting
import SwiftUI

final class SimpleSnapshotTest: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    func testSimpleView() {
        let view = Text("Hello, Snapshot Testing!")
            .font(.largeTitle)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}
