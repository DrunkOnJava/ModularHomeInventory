import XCTest
import SnapshotTesting
import SwiftUI

final class SharingExportSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testShareSheetView() {
        let view = createShareSheetView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testShareSheetViewDarkMode() {
        let view = createShareSheetView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testShareSheetViewCompact() {
        let view = createShareSheetView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testShareSheetViewAccessibility() {
        let view = createShareSheetView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testShareSheetViewErrorState() {
        let view = createShareSheetErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testShareSheetViewNetworkError() {
        let view = createShareSheetNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testShareSheetViewPermissionDenied() {
        let view = createShareSheetPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testShareSheetViewLoading() {
        let view = createShareSheetLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testShareSheetViewRefreshing() {
        let view = createShareSheetRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testExportOptionsView() {
        let view = createExportOptionsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testExportOptionsViewDarkMode() {
        let view = createExportOptionsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testExportOptionsViewCompact() {
        let view = createExportOptionsView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testExportOptionsViewAccessibility() {
        let view = createExportOptionsView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testExportOptionsViewErrorState() {
        let view = createExportOptionsErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testExportOptionsViewNetworkError() {
        let view = createExportOptionsNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testExportOptionsViewPermissionDenied() {
        let view = createExportOptionsPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testExportOptionsViewLoading() {
        let view = createExportOptionsLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testExportOptionsViewRefreshing() {
        let view = createExportOptionsRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPDFExportView() {
        let view = createPDFExportView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPDFExportViewDarkMode() {
        let view = createPDFExportView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPDFExportViewCompact() {
        let view = createPDFExportView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testPDFExportViewAccessibility() {
        let view = createPDFExportView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPDFExportViewErrorState() {
        let view = createPDFExportErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPDFExportViewNetworkError() {
        let view = createPDFExportNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPDFExportViewPermissionDenied() {
        let view = createPDFExportPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPDFExportViewLoading() {
        let view = createPDFExportLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPDFExportViewRefreshing() {
        let view = createPDFExportRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCloudBackupView() {
        let view = createCloudBackupView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testCloudBackupViewDarkMode() {
        let view = createCloudBackupView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCloudBackupViewCompact() {
        let view = createCloudBackupView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testCloudBackupViewAccessibility() {
        let view = createCloudBackupView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCloudBackupViewErrorState() {
        let view = createCloudBackupErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCloudBackupViewNetworkError() {
        let view = createCloudBackupNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCloudBackupViewPermissionDenied() {
        let view = createCloudBackupPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCloudBackupViewLoading() {
        let view = createCloudBackupLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCloudBackupViewRefreshing() {
        let view = createCloudBackupRefreshingView()
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
    
    private func createShareSheetView() -> some View {
                VStack(spacing: 0) {
            // Preview
            VStack {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Inventory Report.pdf")
                    .font(.headline)
                Text("2.4 MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Share options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(["Messages", "Mail", "AirDrop", "Notes"], id: \.self) { app in
                        VStack {
                            Image(systemName: ["message.fill", "envelope.fill", "wifi", "note.text"][["Messages", "Mail", "AirDrop", "Notes"].firstIndex(of: app)!])
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                            Text(app)
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 0) {
                ForEach(["Copy", "Save to Files", "Print"], id: \.self) { action in
                    Button(action: {}) {
                        HStack {
                            Image(systemName: ["doc.on.doc", "folder", "printer"][["Copy", "Save to Files", "Print"].firstIndex(of: action)!])
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text(action)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                    }
                    if action != "Print" {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))

    }
    
    private func createShareSheetErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "square.and.arrow.up",
            title: "ShareSheet Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createShareSheetNetworkErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createShareSheetPermissionDeniedView() -> some View {
        SharingExportErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createShareSheetLoadingView() -> some View {
        SharingExportLoadingStateView(
            message: "Loading ShareSheet...",
            progress: 0.6
        )
    }
    
    private func createShareSheetRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createShareSheetView()
                .opacity(0.6)
        }
    }
    
    private func createExportOptionsView() -> some View {
                NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: .constant(0)) {
                        Label("CSV", systemImage: "tablecells").tag(0)
                        Label("PDF", systemImage: "doc.richtext").tag(1)
                        Label("Excel", systemImage: "tablecells.fill").tag(2)
                        Label("JSON", systemImage: "curlybraces").tag(3)
                    }
                }
                
                Section("Include") {
                    Toggle("Photos", isOn: .constant(true))
                    Toggle("Receipts", isOn: .constant(true))
                    Toggle("Warranties", isOn: .constant(false))
                    Toggle("Purchase History", isOn: .constant(true))
                }
                
                Section("Date Range") {
                    Picker("Period", selection: .constant(1)) {
                        Text("Last 30 days").tag(0)
                        Text("Last 90 days").tag(1)
                        Text("Last year").tag(2)
                        Text("All time").tag(3)
                        Text("Custom").tag(4)
                    }
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Label("Export", systemImage: "arrow.down.doc")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Options")
        }

    }
    
    private func createExportOptionsErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "arrow.down.doc",
            title: "ExportOptions Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createExportOptionsNetworkErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createExportOptionsPermissionDeniedView() -> some View {
        SharingExportErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createExportOptionsLoadingView() -> some View {
        SharingExportLoadingStateView(
            message: "Loading ExportOptions...",
            progress: 0.6
        )
    }
    
    private func createExportOptionsRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createExportOptionsView()
                .opacity(0.6)
        }
    }
    
    private func createPDFExportView() -> some View {
                NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // PDF Preview
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                        .overlay(
                            VStack {
                                Image(systemName: "doc.richtext.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                Text("PDF Preview")
                                    .font(.headline)
                                Text("Page 1 of 12")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                    
                    // Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PDF Options")
                            .font(.headline)
                        
                        Toggle("Include cover page", isOn: .constant(true))
                        Toggle("Add page numbers", isOn: .constant(true))
                        Toggle("Include table of contents", isOn: .constant(false))
                        
                        HStack {
                            Text("Paper size")
                            Spacer()
                            Picker("", selection: .constant(0)) {
                                Text("Letter").tag(0)
                                Text("A4").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: {}) {
                        Label("Generate PDF", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("PDF Export")
        }

    }
    
    private func createPDFExportErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "doc.richtext",
            title: "PDFExport Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createPDFExportNetworkErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createPDFExportPermissionDeniedView() -> some View {
        SharingExportErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createPDFExportLoadingView() -> some View {
        SharingExportLoadingStateView(
            message: "Loading PDFExport...",
            progress: 0.6
        )
    }
    
    private func createPDFExportRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createPDFExportView()
                .opacity(0.6)
        }
    }
    
    private func createCloudBackupView() -> some View {
                NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status card
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Cloud Backup Active")
                            .font(.headline)
                        Text("Last backup: 2 hours ago")
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: 0.75)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("750 MB of 1 GB used")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("75%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Backup settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Backup Settings")
                            .font(.headline)
                        
                        Toggle("Automatic backup", isOn: .constant(true))
                        Toggle("Backup over cellular", isOn: .constant(false))
                        Toggle("Include photos", isOn: .constant(true))
                        
                        HStack {
                            Text("Backup frequency")
                            Spacer()
                            Menu("Daily") {
                                Button("Hourly") {}
                                Button("Daily") {}
                                Button("Weekly") {}
                                Button("Manual") {}
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Backup Now", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {}) {
                            Label("Restore", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cloud Backup")
        }

    }
    
    private func createCloudBackupErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "icloud.and.arrow.up",
            title: "CloudBackup Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createCloudBackupNetworkErrorView() -> some View {
        SharingExportErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createCloudBackupPermissionDeniedView() -> some View {
        SharingExportErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createCloudBackupLoadingView() -> some View {
        SharingExportLoadingStateView(
            message: "Loading CloudBackup...",
            progress: 0.6
        )
    }
    
    private func createCloudBackupRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createCloudBackupView()
                .opacity(0.6)
        }
    }
    
    private func createCombinedView() -> some View {
        TabView {
            createShareSheetView()
                .tabItem {
                    Label("ShareSheet", systemImage: "square.and.arrow.up")
                }
                .tag(0)
            
            createExportOptionsView()
                .tabItem {
                    Label("ExportOptions", systemImage: "arrow.down.doc")
                }
                .tag(1)
            
            createPDFExportView()
                .tabItem {
                    Label("PDFExport", systemImage: "doc.richtext")
                }
                .tag(2)
            
            createCloudBackupView()
                .tabItem {
                    Label("CloudBackup", systemImage: "icloud.and.arrow.up")
                }
                .tag(3)
            
        }
    }
}

// MARK: - Helper Views

struct SharingExportErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SharingExportLoadingStateView: View {
    let message: String
    let progress: Double?
    
    var body: some View {
        VStack(spacing: 20) {
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
            
            Text(message)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SharingExportSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
