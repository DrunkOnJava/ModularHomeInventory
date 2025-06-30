import XCTest
import SnapshotTesting
import SwiftUI

final class ItemsSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testItemsMainView() {
        let view = createItemsView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testItemsDarkMode() {
        let view = createItemsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testItemsComponents() {
        // Test individual components
        let itemslistView = createItemsListView()
        assertSnapshot(
            of: UIHostingController(rootView: itemslistView), 
            as: .image(on: .iPhone13),
            named: "ItemsList"
        )

        let itemdetailView = createItemDetailView()
        assertSnapshot(
            of: UIHostingController(rootView: itemdetailView), 
            as: .image(on: .iPhone13),
            named: "ItemDetail"
        )

        let additemView = createAddItemView()
        assertSnapshot(
            of: UIHostingController(rootView: additemView), 
            as: .image(on: .iPhone13),
            named: "AddItem"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createItemsView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "house.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Items")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack(spacing: 16) {
                // Sample item card
                HStack {
                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("MacBook Pro")
                            .font(.headline)
                        Text("Electronics • $2,499")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Another item
                HStack {
                    Image(systemName: "tv")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Smart TV")
                            .font(.headline)
                        Text("Electronics • $899")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createItemsListView() -> some View {
        // Mock ItemsList view
        VStack {
            Text("ItemsList")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("ItemsList Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createItemDetailView() -> some View {
        // Mock ItemDetail view
        VStack {
            Text("ItemDetail")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("ItemDetail Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createAddItemView() -> some View {
        // Mock AddItem view
        VStack {
            Text("AddItem")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("AddItem Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}
