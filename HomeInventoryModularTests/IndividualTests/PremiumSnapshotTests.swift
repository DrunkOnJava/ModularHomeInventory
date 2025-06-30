import XCTest
import SnapshotTesting
import SwiftUI

final class PremiumSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testPremiumMainView() {
        let view = createPremiumView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPremiumDarkMode() {
        let view = createPremiumView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPremiumComponents() {
        // Test individual components
        let upgradeviewView = createUpgradeViewView()
        assertSnapshot(
            of: UIHostingController(rootView: upgradeviewView), 
            as: .image(on: .iPhone13),
            named: "UpgradeView"
        )

        let featuresView = createFeaturesView()
        assertSnapshot(
            of: UIHostingController(rootView: featuresView), 
            as: .image(on: .iPhone13),
            named: "Features"
        )

        let subscriptionView = createSubscriptionView()
        assertSnapshot(
            of: UIHostingController(rootView: subscriptionView), 
            as: .image(on: .iPhone13),
            named: "Subscription"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createPremiumView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                Text("Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack(spacing: 20) {
                // Premium badge
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Unlock Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Unlimited items")
                    FeatureRow(icon: "icloud", text: "Cloud backup")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics")
                    FeatureRow(icon: "sparkles", text: "AI-powered insights")
                }
                .padding()
                
                // Price
                VStack(spacing: 8) {
                    Text("$4.99/month")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Start 7-day free trial")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createUpgradeViewView() -> some View {
        // Mock UpgradeView view
        VStack {
            Text("UpgradeView")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("UpgradeView Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createFeaturesView() -> some View {
        // Mock Features view
        VStack {
            Text("Features")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Features Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createSubscriptionView() -> some View {
        // Mock Subscription view
        VStack {
            Text("Subscription")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Subscription Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}

// Helper view for Premium features
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(text)
            Spacer()
        }
    }
}
