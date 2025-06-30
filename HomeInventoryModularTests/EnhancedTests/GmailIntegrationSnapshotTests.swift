import XCTest
import SnapshotTesting
import SwiftUI

final class GmailIntegrationSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testGmailReceiptsView() {
        let view = createGmailReceiptsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testGmailReceiptsViewDarkMode() {
        let view = createGmailReceiptsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testGmailReceiptsViewEmptyState() {
        let view = createGmailReceiptsEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testImportPreviewView() {
        let view = createImportPreviewView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testImportPreviewViewDarkMode() {
        let view = createImportPreviewView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testImportPreviewViewEmptyState() {
        let view = createImportPreviewEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testImportHistoryView() {
        let view = createImportHistoryView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testImportHistoryViewDarkMode() {
        let view = createImportHistoryView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testImportHistoryViewEmptyState() {
        let view = createImportHistoryEmptyView()
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
    
    private func createGmailReceiptsView() -> some View {
        NavigationView {
            List {
                Section("Connected Account") {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.red)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text("john.doe@gmail.com")
                                .font(.subheadline)
                            Text("Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Button("Sync") {
                            // Action
                        }
                        .font(.caption)
                    }
                }
                
                Section("Recent Receipts") {
                    ForEach(["Amazon - MacBook Pro", "Best Buy - AirPods", "Target - Home Items"], id: \.self) { receipt in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text(receipt)
                                    .font(.subheadline)
                                Spacer()
                                Text("2d ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Gmail Receipts")
        }
    }
    
    private func createGmailReceiptsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "envelope")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Connect Gmail")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Import receipts from your email")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Connect Gmail", systemImage: "envelope.badge")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Gmail Receipts")
        }
    }

    private func createImportPreviewView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("ImportPreview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("ImportPreview")
        }
    }
    
    private func createImportPreviewEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("ImportPreview content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("ImportPreview")
        }
    }

    private func createImportHistoryView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("ImportHistory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("ImportHistory")
        }
    }
    
    private func createImportHistoryEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("ImportHistory content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("ImportHistory")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createGmailReceiptsView()
                .tabItem {
                    Label("GmailReceipts", systemImage: "envelope.fill")
                }
            createImportPreviewView()
                .tabItem {
                    Label("ImportPreview", systemImage: "doc.text.magnifyingglass")
                }
            createImportHistoryView()
                .tabItem {
                    Label("ImportHistory", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
