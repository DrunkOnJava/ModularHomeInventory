import XCTest
import SnapshotTesting
import SwiftUI

final class BarcodeScannerSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testBarcodeScannerMainView() {
        let view = createBarcodeScannerView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBarcodeScannerDarkMode() {
        let view = createBarcodeScannerView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testBarcodeScannerComponents() {
        // Test individual components
        let scannerView = createScannerView()
        assertSnapshot(
            of: UIHostingController(rootView: scannerView), 
            as: .image(on: .iPhone13),
            named: "Scanner"
        )

        let historyView = createHistoryView()
        assertSnapshot(
            of: UIHostingController(rootView: historyView), 
            as: .image(on: .iPhone13),
            named: "History"
        )

        let batchscanView = createBatchScanView()
        assertSnapshot(
            of: UIHostingController(rootView: batchscanView), 
            as: .image(on: .iPhone13),
            named: "BatchScan"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createBarcodeScannerView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("BarcodeScanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack {
                // Scanner preview area
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, lineWidth: 3)
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)
                            Text("Aim at barcode")
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding()
                
                // Recent scans
                VStack(alignment: .leading) {
                    Text("Recent Scans")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(0..<2) { _ in
                        HStack {
                            Image(systemName: "barcode")
                                .foregroundColor(.orange)
                            Text("1234567890123")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("Just now")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createScannerView() -> some View {
        // Mock Scanner view
        VStack {
            Text("Scanner")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Scanner Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createHistoryView() -> some View {
        // Mock History view
        VStack {
            Text("History")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("History Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createBatchScanView() -> some View {
        // Mock BatchScan view
        VStack {
            Text("BatchScan")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("BatchScan Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}
