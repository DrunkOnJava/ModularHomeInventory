import XCTest
import SnapshotTesting
import SwiftUI

final class SyncSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testConflictResolutionView() {
        let view = createConflictResolutionView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testConflictResolutionViewDarkMode() {
        let view = createConflictResolutionView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testConflictResolutionViewEmptyState() {
        let view = createConflictResolutionEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testSyncStatusView() {
        let view = createSyncStatusView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testSyncStatusViewDarkMode() {
        let view = createSyncStatusView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSyncStatusViewEmptyState() {
        let view = createSyncStatusEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCollaborativeListsView() {
        let view = createCollaborativeListsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testCollaborativeListsViewDarkMode() {
        let view = createCollaborativeListsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCollaborativeListsViewEmptyState() {
        let view = createCollaborativeListsEmptyView()
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
    
    private func createConflictResolutionView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Conflict Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Sync Conflict")
                        .font(.headline)
                    Text("This item has been modified on multiple devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Conflict Comparison
                HStack(spacing: 16) {
                    // Local Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Version")
                            .font(.caption)
                            .fontWeight(.medium)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MacBook Pro 16\"")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Modified: 2 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Price: $2,499")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Cloud Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cloud Version")
                            .font(.caption)
                            .fontWeight(.medium)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MacBook Pro 16\"")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Modified: 3 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Price: $2,399")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createConflictResolutionEmptyView() -> some View {
        createConflictResolutionView()
    }

    private func createSyncStatusView() -> some View {
        NavigationView {
            List {
                Section("Sync Status") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All data synced")
                        Spacer()
                        Text("Just now")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sync Details") {
                    HStack {
                        Text("Last sync")
                        Spacer()
                        Text("Oct 26, 2:45 PM")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Items synced")
                        Spacer()
                        Text("150")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Devices") {
                    ForEach(["iPhone 15 Pro", "iPad Pro", "MacBook Pro"], id: \.self) { device in
                        HStack {
                            Image(systemName: device.contains("iPhone") ? "iphone" : 
                                            device.contains("iPad") ? "ipad" : "laptopcomputer")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(device)
                                    .font(.subheadline)
                                Text("Last seen: 12h ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if device.contains("iPhone") {
                                Text("This device")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sync Status")
        }
    }
    
    private func createSyncStatusEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Sync Not Enabled")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Enable sync to keep your data updated across devices")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Enable Sync", systemImage: "checkmark")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Sync Status")
        }
    }

    private func createCollaborativeListsView() -> some View {
        NavigationView {
            List {
                Section("My Lists") {
                    ForEach(["Home Essentials", "Office Equipment", "Vacation Items"], id: \.self) { list in
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text(list)
                                    .font(.subheadline)
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption2)
                                    Text("3 members")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("20 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Shared With Me") {
                    ForEach(["Family Shopping", "Project Equipment"], id: \.self) { list in
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text(list)
                                    .font(.subheadline)
                                Text("Shared by Sarah")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("12 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Collaborative Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createCollaborativeListsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Collaborative Lists")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Create lists to share with others")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Shared List", systemImage: "plus")
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Collaborative Lists")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createConflictResolutionView()
                .tabItem {
                    Label("ConflictResolution", systemImage: "arrow.triangle.branch")
                }
            createSyncStatusView()
                .tabItem {
                    Label("SyncStatus", systemImage: "arrow.triangle.2.circlepath")
                }
            createCollaborativeListsView()
                .tabItem {
                    Label("CollaborativeLists", systemImage: "person.3.fill")
                }
        }
    }
}
