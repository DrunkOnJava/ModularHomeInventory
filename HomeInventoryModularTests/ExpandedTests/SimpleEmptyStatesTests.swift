import XCTest
import SnapshotTesting
import SwiftUI

final class SimpleEmptyStatesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testEmptyItemsView() {
        let view = EmptyStateView(
            icon: "tray",
            title: "No Items",
            message: "Start by adding your first item"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testEmptySearchView() {
        let view = EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try adjusting your search criteria"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testEmptyNotificationsView() {
        let view = EmptyStateView(
            icon: "bell.slash",
            title: "No Notifications",
            message: "You're all caught up!"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {}) {
                Label("Get Started", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}