import XCTest
import SnapshotTesting
import SwiftUI

final class AdvancedUIStatesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testSkeletonLoadingView() {
        let view = SkeletonLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testShimmerLoadingView() {
        let view = ShimmerLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testProgressIndicatorVariationsView() {
        let view = ProgressIndicatorVariationsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
    }
    
    func testAnimatedStatesView() {
        let view = AnimatedStatesView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testComplexOverlaysView() {
        let view = ComplexOverlaysView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
}

// MARK: - Helper Views

struct SkeletonLoadingView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<6) { index in
                        HStack(spacing: 12) {
                            // Skeleton avatar
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    SkeletonShimmer()
                                        .mask(RoundedRectangle(cornerRadius: 8))
                                )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Skeleton title
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .overlay(
                                        SkeletonShimmer()
                                            .mask(RoundedRectangle(cornerRadius: 4))
                                    )
                                
                                // Skeleton subtitle
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 12)
                                    .frame(maxWidth: 200, alignment: .leading)
                                    .overlay(
                                        SkeletonShimmer()
                                            .mask(RoundedRectangle(cornerRadius: 4))
                                    )
                                
                                // Skeleton price
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 14)
                                    .frame(maxWidth: 80, alignment: .leading)
                                    .overlay(
                                        SkeletonShimmer()
                                            .mask(RoundedRectangle(cornerRadius: 4))
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Loading Items...")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SkeletonShimmer: View {
    @State private var phase = 0.0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .rotationEffect(.degrees(20))
        .offset(x: phase)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
            ) {
                phase = 300
            }
        }
    }
}

struct ShimmerLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Syncing Data...")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 60)
            
            VStack(spacing: 16) {
                ShimmerCard(width: 300, height: 80)
                ShimmerCard(width: 250, height: 60)
                ShimmerCard(width: 200, height: 40)
                ShimmerCard(width: 280, height: 70)
            }
            
            Spacer()
            
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Please wait...")
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ShimmerCard: View {
    let width: CGFloat
    let height: CGFloat
    @State private var offset: CGFloat = -200
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 100)
                    .offset(x: offset)
                    .clipped()
            )
            .mask(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    offset = width + 100
                }
            }
    }
}

struct ProgressIndicatorVariationsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Progress Indicators")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Circular Progress
                VStack(spacing: 16) {
                    Text("Upload Progress")
                        .font(.headline)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: 0.68)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("68%")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Linear Progress Bars
                VStack(alignment: .leading, spacing: 16) {
                    Text("Task Progress")
                        .font(.headline)
                    
                    ProgressBar(label: "Scanning items", progress: 0.85, color: .green)
                    ProgressBar(label: "Uploading photos", progress: 0.45, color: .blue)
                    ProgressBar(label: "Generating thumbnails", progress: 0.22, color: .orange)
                    ProgressBar(label: "Syncing data", progress: 0.78, color: .purple)
                }
                .padding(.horizontal)
                
                // Step Progress
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setup Steps")
                        .font(.headline)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            StepIndicator(
                                number: index + 1,
                                isCompleted: index < 3,
                                isActive: index == 3
                            )
                            
                            if index < 4 {
                                Rectangle()
                                    .fill(index < 2 ? Color.green : Color(.systemGray4))
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct ProgressBar: View {
    let label: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct StepIndicator: View {
    let number: Int
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.green : isActive ? Color.blue : Color(.systemGray4))
                .frame(width: 32, height: 32)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isActive ? .white : .secondary)
            }
        }
    }
}

struct AnimatedStatesView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Animated States")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Pulsing Heart
            VStack {
                Text("Favorite Animation")
                    .font(.headline)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(1.2)
                    .opacity(0.8)
            }
            
            // Bouncing Items
            VStack {
                Text("Adding Items")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .scaleEffect(index == 1 ? 1.1 : 1.0)
                            .offset(y: index == 1 ? -10 : 0)
                    }
                }
            }
            
            // Rotating Sync Icon
            VStack {
                Text("Syncing")
                    .font(.headline)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(45))
            }
            
            // Loading Dots
            VStack {
                Text("Processing")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == 1 ? 1.3 : 1.0)
                            .opacity(index == 1 ? 1.0 : 0.5)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct ComplexOverlaysView: View {
    var body: some View {
        ZStack {
            // Background content
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<10) { index in
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading) {
                                Text("Item \(index + 1)")
                                    .font(.headline)
                                Text("$\(50 * (index + 1))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .blur(radius: 2)
            .opacity(0.6)
            
            // Multi-layer overlay
            VStack(spacing: 0) {
                // Top notification
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                    Text("No internet connection")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Retry") {}
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .border(Color.red.opacity(0.3), width: 1)
                
                Spacer()
                
                // Center modal
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Sync Conflict Detected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Some items have been modified on another device. Choose how to resolve this conflict.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Keep Local Changes") {}
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        Button("Use Remote Changes") {}
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        
                        Button("Review Each Item") {}
                            .foregroundColor(.blue)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 20)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Bottom toast
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("3 items backed up successfully")
                        .font(.subheadline)
                    Spacer()
                    Button("Undo") {}
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}