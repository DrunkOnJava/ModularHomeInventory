import XCTest
import SnapshotTesting
import SwiftUI

final class OnboardingSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testOnboardingMainView() {
        let view = createOnboardingView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testOnboardingDarkMode() {
        let view = createOnboardingView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testOnboardingComponents() {
        // Test individual components
        let welcomeView = createWelcomeView()
        assertSnapshot(
            of: UIHostingController(rootView: welcomeView), 
            as: .image(on: .iPhone13),
            named: "Welcome"
        )

        let permissionsView = createPermissionsView()
        assertSnapshot(
            of: UIHostingController(rootView: permissionsView), 
            as: .image(on: .iPhone13),
            named: "Permissions"
        )

        let setupView = createSetupView()
        assertSnapshot(
            of: UIHostingController(rootView: setupView), 
            as: .image(on: .iPhone13),
            named: "Setup"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createOnboardingView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "info.circle")
                    .font(.largeTitle)
                    .foregroundColor(.teal)
                Text("Onboarding")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack(spacing: 30) {
                // Welcome image
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.teal)
                
                Text("Welcome to\nHome Inventory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Track and manage all your\nvaluable possessions")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Page indicators
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.teal)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                // Action button
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            .padding()

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createWelcomeView() -> some View {
        // Mock Welcome view
        VStack {
            Text("Welcome")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Welcome Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createPermissionsView() -> some View {
        // Mock Permissions view
        VStack {
            Text("Permissions")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Permissions Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createSetupView() -> some View {
        // Mock Setup view
        VStack {
            Text("Setup")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Setup Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}
