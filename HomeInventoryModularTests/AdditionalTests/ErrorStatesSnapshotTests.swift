import XCTest
import SnapshotTesting
import SwiftUI

final class ErrorStatesSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testNetworkErrorView() {
        let view = createNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testNetworkErrorViewDarkMode() {
        let view = createNetworkErrorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNetworkErrorViewCompact() {
        let view = createNetworkErrorView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testNetworkErrorViewAccessibility() {
        let view = createNetworkErrorView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNetworkErrorViewErrorState() {
        let view = createNetworkErrorErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNetworkErrorViewNetworkError() {
        let view = createNetworkErrorNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNetworkErrorViewPermissionDenied() {
        let view = createNetworkErrorPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testServerErrorView() {
        let view = createServerErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testServerErrorViewDarkMode() {
        let view = createServerErrorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testServerErrorViewCompact() {
        let view = createServerErrorView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testServerErrorViewAccessibility() {
        let view = createServerErrorView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testServerErrorViewErrorState() {
        let view = createServerErrorErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testServerErrorViewNetworkError() {
        let view = createServerErrorNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testServerErrorViewPermissionDenied() {
        let view = createServerErrorPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testValidationErrorView() {
        let view = createValidationErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testValidationErrorViewDarkMode() {
        let view = createValidationErrorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testValidationErrorViewCompact() {
        let view = createValidationErrorView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testValidationErrorViewAccessibility() {
        let view = createValidationErrorView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testValidationErrorViewErrorState() {
        let view = createValidationErrorErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testValidationErrorViewNetworkError() {
        let view = createValidationErrorNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testValidationErrorViewPermissionDenied() {
        let view = createValidationErrorPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPermissionErrorView() {
        let view = createPermissionErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPermissionErrorViewDarkMode() {
        let view = createPermissionErrorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPermissionErrorViewCompact() {
        let view = createPermissionErrorView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testPermissionErrorViewAccessibility() {
        let view = createPermissionErrorView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPermissionErrorViewErrorState() {
        let view = createPermissionErrorErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPermissionErrorViewNetworkError() {
        let view = createPermissionErrorNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPermissionErrorViewPermissionDenied() {
        let view = createPermissionErrorPermissionDeniedView()
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
    
    private func createNetworkErrorView() -> some View {
                VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please check your network settings and try again")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Work Offline")
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

    }
    
    private func createNetworkErrorErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "wifi.slash",
            title: "NetworkError Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createNetworkErrorNetworkErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createNetworkErrorPermissionDeniedView() -> some View {
        ErrorStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createServerErrorView() -> some View {
                VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Server Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We're having trouble connecting to our servers. Please try again later.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Error Code: 503")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
            
            Button(action: {}) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(width: 200)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

    }
    
    private func createServerErrorErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "exclamationmark.icloud",
            title: "ServerError Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createServerErrorNetworkErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createServerErrorPermissionDeniedView() -> some View {
        ErrorStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createValidationErrorView() -> some View {
                NavigationView {
            Form {
                Section {
                    HStack {
                        TextField("Email", text: .constant("invalid-email"))
                            .foregroundColor(.red)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    HStack {
                        SecureField("Password", text: .constant("123"))
                            .foregroundColor(.red)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Section("Requirements") {
                    Label("Valid email format", systemImage: "xmark")
                        .foregroundColor(.red)
                    Label("Minimum 8 characters", systemImage: "xmark")
                        .foregroundColor(.red)
                    Label("One uppercase letter", systemImage: "checkmark")
                        .foregroundColor(.green)
                    Label("One number", systemImage: "xmark")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Validation Errors")
        }

    }
    
    private func createValidationErrorErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "xmark.circle",
            title: "ValidationError Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createValidationErrorNetworkErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createValidationErrorPermissionDeniedView() -> some View {
        ErrorStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createPermissionErrorView() -> some View {
                VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 12) {
                Text("Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This feature requires camera access to scan barcodes")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Grant Permission", systemImage: "camera")
                        .frame(width: 250)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Open Settings")
                        .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Text("Skip for Now")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

    }
    
    private func createPermissionErrorErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "lock.shield",
            title: "PermissionError Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createPermissionErrorNetworkErrorView() -> some View {
        ErrorStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createPermissionErrorPermissionDeniedView() -> some View {
        ErrorStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createCombinedView() -> some View {
        TabView {
            createNetworkErrorView()
                .tabItem {
                    Label("NetworkError", systemImage: "wifi.slash")
                }
                .tag(0)
            
            createServerErrorView()
                .tabItem {
                    Label("ServerError", systemImage: "exclamationmark.icloud")
                }
                .tag(1)
            
            createValidationErrorView()
                .tabItem {
                    Label("ValidationError", systemImage: "xmark.circle")
                }
                .tag(2)
            
            createPermissionErrorView()
                .tabItem {
                    Label("PermissionError", systemImage: "lock.shield")
                }
                .tag(3)
            
        }
    }
}

// MARK: - Helper Views

struct ErrorStatesErrorStateView: View {
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

struct ErrorStatesLoadingStateView: View {
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

struct ErrorStatesSkeletonView: View {
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
