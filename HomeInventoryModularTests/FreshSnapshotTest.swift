import XCTest
import SnapshotTesting
import SwiftUI

final class FreshSnapshotTest: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    func testHomeInventoryUI() {
        let view = VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "house.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Home Inventory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Sample item card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("MacBook Pro 16\"")
                            .font(.headline)
                        Text("Electronics • $2,499")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Living Room", systemImage: "location")
                    Spacer()
                    Label("2 years warranty", systemImage: "shield")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Tab bar preview
            HStack(spacing: 0) {
                ForEach(["house.fill", "qrcode.viewfinder", "doc.text", "gearshape"], id: \.self) { icon in
                    VStack {
                        Image(systemName: icon)
                            .font(.title2)
                        Text(icon == "house.fill" ? "Items" : 
                             icon == "qrcode.viewfinder" ? "Scan" :
                             icon == "doc.text" ? "Receipts" : "Settings")
                            .font(.caption2)
                    }
                    .foregroundColor(icon == "house.fill" ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}