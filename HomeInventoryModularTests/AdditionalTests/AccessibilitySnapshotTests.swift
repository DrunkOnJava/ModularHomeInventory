import XCTest
import SnapshotTesting
import SwiftUI

final class AccessibilitySnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testVoiceOverOptimizedView() {
        let view = createVoiceOverOptimizedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testVoiceOverOptimizedViewDarkMode() {
        let view = createVoiceOverOptimizedView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testVoiceOverOptimizedViewCompact() {
        let view = createVoiceOverOptimizedView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testVoiceOverOptimizedViewAccessibility() {
        let view = createVoiceOverOptimizedView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testLargeTextSupportView() {
        let view = createLargeTextSupportView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testLargeTextSupportViewDarkMode() {
        let view = createLargeTextSupportView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testLargeTextSupportViewCompact() {
        let view = createLargeTextSupportView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testLargeTextSupportViewAccessibility() {
        let view = createLargeTextSupportView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testHighContrastModeView() {
        let view = createHighContrastModeView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testHighContrastModeViewDarkMode() {
        let view = createHighContrastModeView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testHighContrastModeViewCompact() {
        let view = createHighContrastModeView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testHighContrastModeViewAccessibility() {
        let view = createHighContrastModeView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testReducedMotionView() {
        let view = createReducedMotionView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testReducedMotionViewDarkMode() {
        let view = createReducedMotionView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testReducedMotionViewCompact() {
        let view = createReducedMotionView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testReducedMotionViewAccessibility() {
        let view = createReducedMotionView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
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
    
    private func createVoiceOverOptimizedView() -> some View {
                NavigationView {
            VStack(spacing: 20) {
                Text("VoiceOver Optimized")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityLabel("VoiceOver Optimized View")
                    .accessibilityAddTraits(.isHeader)
                
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .accessibilityHidden(true)
                            Text("Play Audio Description")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .accessibilityLabel("Play audio description of current screen")
                    .accessibilityHint("Double tap to play")
                    
                    ForEach(["Navigation", "Content", "Actions"], id: \.self) { section in
                        VStack(alignment: .leading) {
                            Text(section)
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            Text("Optimized for screen readers with descriptive labels")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("\(section) section is optimized for screen readers with descriptive labels")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
    
    private func createLargeTextSupportView() -> some View {
                NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Large Text Support")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    Text("This view automatically adjusts to your preferred text size")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Automatic scaling", systemImage: "textformat.size")
                            .font(.headline)
                        Label("Readable layouts", systemImage: "text.alignleft")
                            .font(.headline)
                        Label("Flexible spacing", systemImage: "arrow.up.and.down")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("Sample Content")
                        .font(.headline)
                    
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Button("Cancel") {}
                            .font(.body)
                        Spacer()
                        Button("Confirm") {}
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Text Size")
        }

    }
    
    private func createHighContrastModeView() -> some View {
                VStack(spacing: 0) {
            // High contrast header
            HStack {
                Text("High Contrast Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black)
            
            // Content with high contrast
            VStack(spacing: 16) {
                ForEach(["Primary Action", "Secondary Action", "Disabled Action"], id: \.self) { action in
                    Button(action: {}) {
                        Text(action)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(action == "Disabled Action" ? Color.gray : action == "Primary Action" ? Color.black : Color.white)
                            .foregroundColor(action == "Secondary Action" ? .black : .white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: action == "Secondary Action" ? 2 : 0)
                            )
                            .cornerRadius(8)
                    }
                    .disabled(action == "Disabled Action")
                }
                
                // High contrast cards
                VStack(alignment: .leading, spacing: 8) {
                    Text("Important Information")
                        .font(.headline)
                    Text("High contrast improves readability for users with visual impairments")
                        .font(.body)
                }
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )
                
                // Status indicators
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Success")
                            .font(.caption)
                    }
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Warning")
                            .font(.caption)
                    }
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Error")
                            .font(.caption)
                    }
                }
                .padding()
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGray6))

    }
    
    private func createReducedMotionView() -> some View {
                NavigationView {
            VStack(spacing: 20) {
                Text("Reduced Motion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    // No animations indicator
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .font(.title)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Animations Disabled")
                                .font(.headline)
                            Text("Smooth transitions without motion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Static transitions
                    Text("All transitions use fade effects instead of sliding or scaling animations")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // Example buttons
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Text("Instant Feedback")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {}) {
                            Text("No Spring Effects")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Motion")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
    
    private func createCombinedView() -> some View {
        TabView {
            createVoiceOverOptimizedView()
                .tabItem {
                    Label("VoiceOverOptimized", systemImage: "speaker.wave.3")
                }
                .tag(0)
            
            createLargeTextSupportView()
                .tabItem {
                    Label("LargeTextSupport", systemImage: "textformat.size")
                }
                .tag(1)
            
            createHighContrastModeView()
                .tabItem {
                    Label("HighContrastMode", systemImage: "circle.lefthalf.filled")
                }
                .tag(2)
            
            createReducedMotionView()
                .tabItem {
                    Label("ReducedMotion", systemImage: "figure.walk.motion")
                }
                .tag(3)
            
        }
    }
}

// MARK: - Helper Views

struct AccessibilityErrorStateView: View {
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

struct AccessibilityLoadingStateView: View {
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

struct AccessibilitySkeletonView: View {
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
