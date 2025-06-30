import XCTest
import SnapshotTesting
import SwiftUI

final class LoadingStatesSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testFullScreenLoadingView() {
        let view = createFullScreenLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testFullScreenLoadingViewDarkMode() {
        let view = createFullScreenLoadingView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFullScreenLoadingViewCompact() {
        let view = createFullScreenLoadingView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testFullScreenLoadingViewAccessibility() {
        let view = createFullScreenLoadingView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testFullScreenLoadingViewErrorState() {
        let view = createFullScreenLoadingErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFullScreenLoadingViewNetworkError() {
        let view = createFullScreenLoadingNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFullScreenLoadingViewPermissionDenied() {
        let view = createFullScreenLoadingPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testFullScreenLoadingViewLoading() {
        let view = createFullScreenLoadingLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFullScreenLoadingViewRefreshing() {
        let view = createFullScreenLoadingRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testInlineLoadingView() {
        let view = createInlineLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testInlineLoadingViewDarkMode() {
        let view = createInlineLoadingView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testInlineLoadingViewCompact() {
        let view = createInlineLoadingView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testInlineLoadingViewAccessibility() {
        let view = createInlineLoadingView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testInlineLoadingViewErrorState() {
        let view = createInlineLoadingErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testInlineLoadingViewNetworkError() {
        let view = createInlineLoadingNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testInlineLoadingViewPermissionDenied() {
        let view = createInlineLoadingPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testInlineLoadingViewLoading() {
        let view = createInlineLoadingLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testInlineLoadingViewRefreshing() {
        let view = createInlineLoadingRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testSkeletonLoadingView() {
        let view = createSkeletonLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testSkeletonLoadingViewDarkMode() {
        let view = createSkeletonLoadingView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSkeletonLoadingViewCompact() {
        let view = createSkeletonLoadingView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testSkeletonLoadingViewAccessibility() {
        let view = createSkeletonLoadingView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testSkeletonLoadingViewErrorState() {
        let view = createSkeletonLoadingErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSkeletonLoadingViewNetworkError() {
        let view = createSkeletonLoadingNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSkeletonLoadingViewPermissionDenied() {
        let view = createSkeletonLoadingPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testSkeletonLoadingViewLoading() {
        let view = createSkeletonLoadingLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSkeletonLoadingViewRefreshing() {
        let view = createSkeletonLoadingRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testProgressIndicatorView() {
        let view = createProgressIndicatorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testProgressIndicatorViewDarkMode() {
        let view = createProgressIndicatorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testProgressIndicatorViewCompact() {
        let view = createProgressIndicatorView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testProgressIndicatorViewAccessibility() {
        let view = createProgressIndicatorView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testProgressIndicatorViewErrorState() {
        let view = createProgressIndicatorErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testProgressIndicatorViewNetworkError() {
        let view = createProgressIndicatorNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testProgressIndicatorViewPermissionDenied() {
        let view = createProgressIndicatorPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testProgressIndicatorViewLoading() {
        let view = createProgressIndicatorLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testProgressIndicatorViewRefreshing() {
        let view = createProgressIndicatorRefreshingView()
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
    
    private func createFullScreenLoadingView() -> some View {
                VStack(spacing: 30) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
            
            Text("Loading your inventory...")
                .font(.headline)
                .padding(.top)
            
            Text("This may take a few moments")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

    }
    
    private func createFullScreenLoadingErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "hourglass",
            title: "FullScreenLoading Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createFullScreenLoadingNetworkErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createFullScreenLoadingPermissionDeniedView() -> some View {
        LoadingStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createFullScreenLoadingLoadingView() -> some View {
        LoadingStatesLoadingStateView(
            message: "Loading FullScreenLoading...",
            progress: 0.6
        )
    }
    
    private func createFullScreenLoadingRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createFullScreenLoadingView()
                .opacity(0.6)
        }
    }
    
    private func createInlineLoadingView() -> some View {
                VStack {
            // Header
            HStack {
                Text("Recent Items")
                    .font(.headline)
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
            }
            .padding()
            
            // Content with loading overlay
            List {
                ForEach(0..<3) { i in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading) {
                            Text("Loading item...")
                                .foregroundColor(.secondary)
                            Text("Please wait")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .disabled(true)
            .opacity(0.6)
            
            // Loading indicator at bottom
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }

    }
    
    private func createInlineLoadingErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "arrow.clockwise",
            title: "InlineLoading Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createInlineLoadingNetworkErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createInlineLoadingPermissionDeniedView() -> some View {
        LoadingStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createInlineLoadingLoadingView() -> some View {
        LoadingStatesLoadingStateView(
            message: "Loading InlineLoading...",
            progress: 0.6
        )
    }
    
    private func createInlineLoadingRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createInlineLoadingView()
                .opacity(0.6)
        }
    }
    
    private func createSkeletonLoadingView() -> some View {
                VStack(spacing: 16) {
            // Skeleton header
            HStack {
                LoadingStatesSkeletonView()
                    .frame(width: 120, height: 20)
                Spacer()
                LoadingStatesSkeletonView()
                    .frame(width: 60, height: 20)
            }
            .padding()
            
            // Skeleton cards
            ForEach(0..<4) { _ in
                HStack(spacing: 12) {
                    LoadingStatesSkeletonView()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        LoadingStatesSkeletonView()
                            .frame(width: 150, height: 16)
                        LoadingStatesSkeletonView()
                            .frame(width: 100, height: 14)
                        LoadingStatesSkeletonView()
                            .frame(width: 80, height: 14)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))

    }
    
    private func createSkeletonLoadingErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "rectangle.3.group",
            title: "SkeletonLoading Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createSkeletonLoadingNetworkErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createSkeletonLoadingPermissionDeniedView() -> some View {
        LoadingStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createSkeletonLoadingLoadingView() -> some View {
        LoadingStatesLoadingStateView(
            message: "Loading SkeletonLoading...",
            progress: 0.6
        )
    }
    
    private func createSkeletonLoadingRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createSkeletonLoadingView()
                .opacity(0.6)
        }
    }
    
    private func createProgressIndicatorView() -> some View {
                NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Circular progress
                    VStack {
                        Text("Upload Progress")
                            .font(.headline)
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: 0.75)
                                .stroke(Color.green, lineWidth: 20)
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("75%")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("3 of 4 files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Linear progress bars
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Processing Items")
                            .font(.headline)
                        
                        ForEach(["Photos", "Documents", "Metadata", "Optimization"], id: \.self) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(task)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(task == "Photos" ? "Complete" : task == "Documents" ? "85%" : task == "Metadata" ? "45%" : "Waiting")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: task == "Photos" ? 1.0 : task == "Documents" ? 0.85 : task == "Metadata" ? 0.45 : 0.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: task == "Photos" ? .green : .blue))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Progress Indicators")
        }

    }
    
    private func createProgressIndicatorErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "percent",
            title: "ProgressIndicator Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createProgressIndicatorNetworkErrorView() -> some View {
        LoadingStatesErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createProgressIndicatorPermissionDeniedView() -> some View {
        LoadingStatesErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createProgressIndicatorLoadingView() -> some View {
        LoadingStatesLoadingStateView(
            message: "Loading ProgressIndicator...",
            progress: 0.6
        )
    }
    
    private func createProgressIndicatorRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createProgressIndicatorView()
                .opacity(0.6)
        }
    }
    
    private func createCombinedView() -> some View {
        TabView {
            createFullScreenLoadingView()
                .tabItem {
                    Label("FullScreenLoading", systemImage: "hourglass")
                }
                .tag(0)
            
            createInlineLoadingView()
                .tabItem {
                    Label("InlineLoading", systemImage: "arrow.clockwise")
                }
                .tag(1)
            
            createSkeletonLoadingView()
                .tabItem {
                    Label("SkeletonLoading", systemImage: "rectangle.3.group")
                }
                .tag(2)
            
            createProgressIndicatorView()
                .tabItem {
                    Label("ProgressIndicator", systemImage: "percent")
                }
                .tag(3)
            
        }
    }
}

// MARK: - Helper Views

struct LoadingStatesErrorStateView: View {
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

struct LoadingStatesLoadingStateView: View {
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

struct LoadingStatesSkeletonView: View {
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
