import XCTest
import SnapshotTesting
import SwiftUI

final class WorkingSnapshotTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Force recording mode
        isRecording = false
    }
    
    func testSimpleText() {
        let view = Text("Home Inventory")
            .font(.largeTitle)
            .padding()
        
        assertSnapshot(
            matching: AnyView(view),
            as: .image(size: CGSize(width: 300, height: 100))
        )
    }
    
    func testPrimaryButtonExample() {
        let view = VStack(spacing: 16) {
            // Normal button
            HStack {
                Text("Save Changes")
                    .fontWeight(.semibold)
            }
            .frame(width: 200, height: 44)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            
            // Loading button
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
                Text("Loading...")
                    .fontWeight(.semibold)
            }
            .frame(width: 200, height: 44)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        
        assertSnapshot(
            matching: AnyView(view),
            as: .image(size: CGSize(width: 250, height: 150))
        )
    }
    
    func testLoadingOverlayExample() {
        let view = ZStack {
            // Background content
            VStack {
                Text("Background Content")
                    .font(.title)
                Spacer()
            }
            .frame(width: 300, height: 200)
            .background(Color.gray.opacity(0.1))
            
            // Loading overlay
            ZStack {
                Color.black.opacity(0.4)
                
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Scanning barcode...")
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            }
        }
        
        assertSnapshot(
            matching: AnyView(view),
            as: .image(size: CGSize(width: 300, height: 200))
        )
    }
}