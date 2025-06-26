import XCTest
import SnapshotTesting
import SwiftUI

final class SimpleSnapshotTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        isRecording = true // Always record for initial setup
    }
    
    func testSimpleView() {
        let view = Text("Hello, Snapshot Testing!")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .frame(width: 200, height: 50)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testSimpleView_DarkMode() {
        let view = Text("Hello, Dark Mode!")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .frame(width: 200, height: 50)
        
        assertSnapshot(
            matching: view,
            as: .image(traits: .init(userInterfaceStyle: .dark))
        )
    }
}