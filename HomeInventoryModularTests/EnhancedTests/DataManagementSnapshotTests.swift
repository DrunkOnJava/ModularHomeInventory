import XCTest
import SnapshotTesting
import SwiftUI

final class DataManagementSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testCSVImportView() {
        let view = createCSVImportView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testCSVImportViewDarkMode() {
        let view = createCSVImportView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCSVImportViewEmptyState() {
        let view = createCSVImportEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCSVExportView() {
        let view = createCSVExportView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testCSVExportViewDarkMode() {
        let view = createCSVExportView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCSVExportViewEmptyState() {
        let view = createCSVExportEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testBackupManagerView() {
        let view = createBackupManagerView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBackupManagerViewDarkMode() {
        let view = createBackupManagerView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testBackupManagerViewEmptyState() {
        let view = createBackupManagerEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testFamilySharingView() {
        let view = createFamilySharingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testFamilySharingViewDarkMode() {
        let view = createFamilySharingView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFamilySharingViewEmptyState() {
        let view = createFamilySharingEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
    private func createCSVImportView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Drop Zone
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Drop CSV file here")
                        .font(.headline)
                    Text("or tap to browse")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.green)
                )
                
                // Import Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Settings")
                        .font(.headline)
                    Toggle("Skip duplicate items", isOn: .constant(true))
                    Toggle("Auto-match categories", isOn: .constant(true))
                    Toggle("Import images from URLs", isOn: .constant(false))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import CSV")
        }
    }
    
    private func createCSVImportEmptyView() -> some View {
        createCSVImportView()
    }

    private func createCSVExportView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Include:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Toggle("Basic item information", isOn: .constant(true))
                        Toggle("Purchase details", isOn: .constant(true))
                        Toggle("Warranty information", isOn: .constant(true))
                        Toggle("Item notes", isOn: .constant(false))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Export Button
                Button(action: {}) {
                    Label("Export Items", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export CSV")
        }
    }
    
    private func createCSVExportEmptyView() -> some View {
        createCSVExportView()
    }

    private func createBackupManagerView() -> some View {
        NavigationView {
            List {
                Section("Automatic Backups") {
                    Toggle("iCloud Backup", isOn: .constant(true))
                    Toggle("Local Backup", isOn: .constant(false))
                    HStack {
                        Text("Backup Frequency")
                        Spacer()
                        Text("Daily")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Recent Backups") {
                    ForEach(["Today, 2:00 AM", "Yesterday, 2:00 AM", "Oct 24, 2:00 AM"], id: \.self) { backup in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(backup)
                                    .font(.subheadline)
                                Text("150 items • 25 MB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Backup Manager")
        }
    }
    
    private func createBackupManagerEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Backups")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Enable automatic backups to protect your data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Enable Backups", systemImage: "checkmark.shield")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Backup Manager")
        }
    }

    private func createFamilySharingView() -> some View {
        NavigationView {
            List {
                Section("Family Members") {
                    ForEach(["John (Me)", "Sarah", "Kids"], id: \.self) { member in
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(member.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                )
                            VStack(alignment: .leading) {
                                Text(member)
                                    .font(.subheadline)
                                Text(member == "John (Me)" ? "Owner" : "Member")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if member != "John (Me)" {
                                Text("Can view")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Shared Lists") {
                    ForEach(["Home Electronics", "Kitchen Items", "Kids Toys"], id: \.self) { list in
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.orange)
                            Text(list)
                            Spacer()
                            Text("25 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Family Sharing")
        }
    }
    
    private func createFamilySharingEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Family Members")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Share your inventory with family")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Set Up Family Sharing", systemImage: "plus")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Family Sharing")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createCSVImportView()
                .tabItem {
                    Label("CSVImport", systemImage: "square.and.arrow.down")
                }
            createCSVExportView()
                .tabItem {
                    Label("CSVExport", systemImage: "square.and.arrow.up")
                }
            createBackupManagerView()
                .tabItem {
                    Label("BackupManager", systemImage: "externaldrive.fill")
                }
            createFamilySharingView()
                .tabItem {
                    Label("FamilySharing", systemImage: "person.2.fill")
                }
        }
    }
}
