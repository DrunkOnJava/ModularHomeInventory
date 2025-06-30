import XCTest
import SnapshotTesting
import SwiftUI

final class AppSettingsSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testAppSettingsMainView() {
        let view = createAppSettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testAppSettingsDarkMode() {
        let view = createAppSettingsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAppSettingsComponents() {
        // Test individual components
        let generalsettingsView = createGeneralSettingsView()
        assertSnapshot(
            of: UIHostingController(rootView: generalsettingsView), 
            as: .image(on: .iPhone13),
            named: "GeneralSettings"
        )

        let privacysettingsView = createPrivacySettingsView()
        assertSnapshot(
            of: UIHostingController(rootView: privacysettingsView), 
            as: .image(on: .iPhone13),
            named: "PrivacySettings"
        )

        let datasettingsView = createDataSettingsView()
        assertSnapshot(
            of: UIHostingController(rootView: datasettingsView), 
            as: .image(on: .iPhone13),
            named: "DataSettings"
        )
    }
    
    // MARK: - View Creation Helpers
    
    private func createAppSettingsView() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gearshape")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("AppSettings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            VStack(spacing: 0) {
                // Settings sections
                ForEach(["General", "Privacy", "Notifications", "Data & Storage"], id: \.self) { section in
                    HStack {
                        Image(systemName: section == "General" ? "gearshape" : 
                                         section == "Privacy" ? "lock" :
                                         section == "Notifications" ? "bell" : "externaldrive")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        Text(section)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    if section != "Data & Storage" {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
                .cornerRadius(12)
                .padding()
            }

            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
    private func createGeneralSettingsView() -> some View {
        // Mock GeneralSettings view
        VStack {
            Text("GeneralSettings")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("GeneralSettings Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createPrivacySettingsView() -> some View {
        // Mock PrivacySettings view
        VStack {
            Text("PrivacySettings")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("PrivacySettings Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }

    private func createDataSettingsView() -> some View {
        // Mock DataSettings view
        VStack {
            Text("DataSettings")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("DataSettings Content")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }
}
