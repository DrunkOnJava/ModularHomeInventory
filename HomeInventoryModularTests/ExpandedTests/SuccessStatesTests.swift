import XCTest
import SnapshotTesting
import SwiftUI

final class SuccessStatesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testItemAddedSuccess() {
        let view = SuccessView(
            icon: "checkmark.circle.fill",
            title: "Item Added",
            message: "Your item has been successfully added to the inventory",
            primaryAction: "View Item",
            secondaryAction: "Add Another"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBackupCompleteSuccess() {
        let view = SuccessView(
            icon: "icloud.and.arrow.up",
            title: "Backup Complete",
            message: "All data has been successfully backed up to iCloud",
            primaryAction: "Done",
            secondaryAction: "View Details"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
    }
    
    func testExportSuccess() {
        let view = SuccessView(
            icon: "square.and.arrow.up",
            title: "Export Successful",
            message: "Your inventory has been exported to CSV format",
            primaryAction: "Share",
            secondaryAction: "Done"
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSyncCompleteSuccess() {
        let view = SuccessView(
            icon: "arrow.triangle.2.circlepath",
            title: "Sync Complete",
            message: "All changes have been synchronized across devices",
            primaryAction: "Continue",
            secondaryAction: nil
        )
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPaymentSuccess() {
        let view = SuccessView(
            icon: "creditcard.fill",
            title: "Payment Successful",
            message: "Thank you for upgrading to Premium!",
            primaryAction: "Get Started",
            secondaryAction: "View Receipt"
        )
        .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct SuccessView: View {
    let icon: String
    let title: String
    let message: String
    let primaryAction: String
    let secondaryAction: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success animation circle
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Text(primaryAction)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if let secondaryAction = secondaryAction {
                    Button(action: {}) {
                        Text(secondaryAction)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}