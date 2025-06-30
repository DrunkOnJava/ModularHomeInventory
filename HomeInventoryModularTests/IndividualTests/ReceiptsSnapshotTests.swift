import XCTest
import SnapshotTesting
import SwiftUI

final class ReceiptsSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testReceiptsMainView() {
        let view = createReceiptsView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testReceiptsDarkMode() {
        let view = createReceiptsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testReceiptsComponents() {
        // Test individual components
        let receiptslistView = createReceiptsListView()
        assertSnapshot(
            of: UIHostingController(rootView: receiptslistView), 
            as: .image(on: .iPhone13),
            named: "ReceiptsList"
        )

        let receiptdetailView = createReceiptDetailView()
        assertSnapshot(
            of: UIHostingController(rootView: receiptdetailView), 
            as: .image(on: .iPhone13),
            named: "ReceiptDetail"
        )

        let receiptscannerView = createReceiptScannerView()
        assertSnapshot(
            of: UIHostingController(rootView: receiptscannerView), 
            as: .image(on: .iPhone13),
            named: "ReceiptScanner"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createReceiptsView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("Receipts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack(spacing: 16) {
                // Receipt card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text("Apple Store")
                            .font(.headline)
                        Spacer()
                        Text("$2,499.00")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Label("Oct 15, 2024", systemImage: "calendar")
                        Spacer()
                        Label("Electronics", systemImage: "tag")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "paperclip")
                        Text("IMG_1234.jpg")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createReceiptsListView() -> some View {
        // Mock ReceiptsList view
        VStack {
            Text("ReceiptsList")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("ReceiptsList Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createReceiptDetailView() -> some View {
        // Mock ReceiptDetail view
        VStack {
            Text("ReceiptDetail")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("ReceiptDetail Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createReceiptScannerView() -> some View {
        // Mock ReceiptScanner view
        VStack {
            Text("ReceiptScanner")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("ReceiptScanner Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}
