import XCTest
import SnapshotTesting
import SwiftUI

final class EdgeCaseScenarioTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testNetworkTimeoutView() {
        let view = NetworkTimeoutView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testDataCorruptionView() {
        let view = DataCorruptionView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testStorageFullView() {
        let view = StorageFullView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testVersionMismatchView() {
        let view = VersionMismatchView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCriticalErrorView() {
        let view = CriticalErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testOfflineDataConflictView() {
        let view = OfflineDataConflictView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct NetworkTimeoutView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Timeout icon with animation
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 16) {
                Text("Request Timed Out")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("The request took too long to complete. This might be due to a slow network connection or server issues.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Error details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Error Code:")
                        .fontWeight(.medium)
                    Text("TIMEOUT_408")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Attempted:")
                        .fontWeight(.medium)
                    Text("3 times")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Last attempt:")
                        .fontWeight(.medium)
                    Text("30 seconds ago")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("Work Offline")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct DataCorruptionView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Corruption warning
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 16) {
                Text("Data Corruption Detected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text("Some of your inventory data appears to be corrupted. This can happen due to unexpected app crashes or storage issues.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Affected data summary
            VStack(spacing: 12) {
                Text("Affected Data:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CorruptedDataRow(icon: "photo", title: "23 item photos", status: "Corrupted")
                CorruptedDataRow(icon: "doc.text", title: "156 item records", status: "Partially damaged")
                CorruptedDataRow(icon: "folder", title: "8 collections", status: "Missing data")
                CorruptedDataRow(icon: "checkmark.circle", title: "Warranties & receipts", status: "Intact")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Restore from Backup", systemImage: "arrow.clockwise.icloud")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Label("Repair Data", systemImage: "wrench.and.screwdriver")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("Continue with Damaged Data")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct CorruptedDataRow: View {
    let icon: String
    let title: String
    let status: String
    
    var statusColor: Color {
        switch status {
        case "Intact": return .green
        case "Corrupted": return .red
        case "Partially damaged": return .orange
        case "Missing data": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

struct StorageFullView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Storage full icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "externaldrive.fill.trianglebadge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Storage Almost Full")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your device is running low on storage space. This may affect app performance and your ability to add new items.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Storage breakdown
            VStack(spacing: 16) {
                HStack {
                    Text("Storage Usage")
                        .font(.headline)
                    Spacer()
                    Text("28.4 GB of 32 GB used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Storage bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * 0.89, height: 12)
                    }
                }
                .frame(height: 12)
                
                VStack(spacing: 8) {
                    StorageRow(category: "Home Inventory", size: "2.4 GB", color: .blue)
                    StorageRow(category: "Photos", size: "18.2 GB", color: .green)
                    StorageRow(category: "Apps", size: "5.8 GB", color: .purple)
                    StorageRow(category: "System", size: "2.0 GB", color: .gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Optimize Storage", systemImage: "wand.and.rays")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Label("Manage Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct StorageRow: View {
    let category: String
    let size: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category)
                .font(.subheadline)
            
            Spacer()
            
            Text(size)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct VersionMismatchView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "app.badge")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Update Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("A newer version of Home Inventory is required to continue. Please update to the latest version from the App Store.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Version info
            VStack(spacing: 12) {
                HStack {
                    Text("Current Version:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("2.0.1")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Required Version:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("2.1.0 or later")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Latest Version:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("2.1.3")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: {}) {
                Label("Update Now", systemImage: "arrow.down.app")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct CriticalErrorView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Critical error icon with pulsing effect
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1.1)
                    .opacity(0.6)
                
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 16) {
                Text("Critical Error")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("The app has encountered a critical error and cannot continue. Your data is safe, but the app needs to restart.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Error details
            VStack(alignment: .leading, spacing: 12) {
                Text("Error Details:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Error ID:")
                            .fontWeight(.medium)
                        Text("CR-5029")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Component:")
                            .fontWeight(.medium)
                        Text("Core Data Manager")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Time:")
                            .fontWeight(.medium)
                        Text("Oct 26, 2024 at 2:45 PM")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Description: Database connection lost during sync operation. Automatic recovery failed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Restart App", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Label("Send Error Report", systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct OfflineDataConflictView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Sync Conflicts")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            Text("While you were offline, some items were modified on another device. Please resolve these conflicts:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ConflictRow(
                        itemName: "MacBook Pro 16\"",
                        conflictType: "Price changed",
                        localValue: "$2,299",
                        remoteValue: "$2,499"
                    )
                    
                    ConflictRow(
                        itemName: "Coffee Maker",
                        conflictType: "Location moved",
                        localValue: "Kitchen Counter",
                        remoteValue: "Storage Room"
                    )
                    
                    ConflictRow(
                        itemName: "Gaming Chair",
                        conflictType: "Item deleted",
                        localValue: "Present",
                        remoteValue: "Deleted"
                    )
                    
                    ConflictRow(
                        itemName: "Bluetooth Headphones",
                        conflictType: "Notes updated",
                        localValue: "Good condition",
                        remoteValue: "Needs repair - left speaker issue"
                    )
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Keep All Local")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Keep All Remote")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Review Each")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ConflictRow: View {
    let itemName: String
    let conflictType: String
    let localValue: String
    let remoteValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(itemName)
                    .font(.headline)
                Spacer()
                Text(conflictType)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(localValue)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remote")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(remoteValue)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}