import XCTest
import SnapshotTesting
import SwiftUI

// Simple working snapshot test
class MinimalSnapshotDemo: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Force recording mode
        isRecording = false
    }
    
    func testBasicText() {
        let view = Text("Hello, SwiftUI!")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        
        assertSnapshot(matching: AnyView(view), as: .image(on: .init(size: CGSize(width: 200, height: 100))))
    }
    
    func testButton() {
        let view = Button("Tap Me") {
            print("Tapped")
        }
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(8)
        
        assertSnapshot(matching: AnyView(view), as: .image(on: .init(size: CGSize(width: 150, height: 60))))
    }
    
    func testList() {
        let items = ["Apple", "Banana", "Orange"]
        let view = List(items, id: \.self) { item in
            Text(item)
        }
        .frame(width: 200, height: 150)
        
        assertSnapshot(matching: AnyView(view), as: .image(on: .init(size: CGSize(width: 200, height: 150))))
    }
}