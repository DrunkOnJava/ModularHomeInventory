import XCTest
import SnapshotTesting
import SwiftUI
@testable import BarcodeScanner
@testable import Core
@testable import SharedUI

final class ScannerViewSnapshotTests: SnapshotTestCase {
    
    func testScannerTabView() {
        let view = NavigationStack {
            ScannerTabView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScanHistoryView_Empty() {
        let view = NavigationStack {
            ScanHistoryView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScanHistoryView_WithItems() {
        // Mock scan history items
        let historyList = List {
            Section("Today") {
                ScanHistoryRow(
                    barcode: "0123456789012",
                    timestamp: Date(),
                    itemName: "iPhone 15 Pro"
                )
                ScanHistoryRow(
                    barcode: "9876543210987",
                    timestamp: Date().addingTimeInterval(-3600),
                    itemName: "MacBook Air"
                )
            }
            
            Section("Yesterday") {
                ScanHistoryRow(
                    barcode: "1234567890123",
                    timestamp: Date().addingTimeInterval(-86400),
                    itemName: "AirPods Pro"
                )
            }
        }
        .frame(height: 400)
        
        assertSnapshot(matching: historyList, as: .image(on: .iPhone16ProMax))
    }
    
    func testOfflineScanQueueView() {
        let view = NavigationStack {
            OfflineScanQueueView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testScannerView_DarkMode() {
        let view = NavigationStack {
            ScannerTabView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
}

// Helper view for scan history row
struct ScanHistoryRow: View {
    let barcode: String
    let timestamp: Date
    let itemName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(itemName ?? "Unknown Item")
                    .font(.headline)
                Spacer()
                Text(timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(barcode)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}