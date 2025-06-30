import XCTest
import SnapshotTesting
import SwiftUI

final class SecuritySnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testLockScreenView() {
        let view = createLockScreenView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testLockScreenViewDarkMode() {
        let view = createLockScreenView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testLockScreenViewEmptyState() {
        let view = createLockScreenEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testBiometricLockView() {
        let view = createBiometricLockView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBiometricLockViewDarkMode() {
        let view = createBiometricLockView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testBiometricLockViewEmptyState() {
        let view = createBiometricLockEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testTwoFactorView() {
        let view = createTwoFactorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testTwoFactorViewDarkMode() {
        let view = createTwoFactorView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testTwoFactorViewEmptyState() {
        let view = createTwoFactorEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testPrivacySettingsView() {
        let view = createPrivacySettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPrivacySettingsViewDarkMode() {
        let view = createPrivacySettingsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPrivacySettingsViewEmptyState() {
        let view = createPrivacySettingsEmptyView()
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
    
    private func createLockScreenView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Home Inventory")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter passcode to unlock")
                .foregroundColor(.secondary)
            
            // Passcode dots
            HStack(spacing: 20) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < 2 ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 15, height: 15)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            Button("Use Face ID") {
                // Action
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    private func createLockScreenEmptyView() -> some View {
        createLockScreenView()
    }

    private func createBiometricLockView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Face ID")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Look at your iPhone to unlock")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Animation placeholder
            Circle()
                .strokeBorder(Color.blue, lineWidth: 3)
                .frame(width: 150, height: 150)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.5))
                )
            
            Spacer()
            
            Button("Enter Passcode") {
                // Action
            }
            .foregroundColor(.blue)
            
            Button("Cancel") {
                // Action
            }
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .padding()
    }
    
    private func createBiometricLockEmptyView() -> some View {
        createBiometricLockView()
    }

    private func createTwoFactorView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("TwoFactor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("TwoFactor")
        }
    }
    
    private func createTwoFactorEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("TwoFactor content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("TwoFactor")
        }
    }

    private func createPrivacySettingsView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                Text("PrivacySettings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("PrivacySettings")
        }
    }
    
    private func createPrivacySettingsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("PrivacySettings content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("PrivacySettings")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createLockScreenView()
                .tabItem {
                    Label("LockScreen", systemImage: "lock.fill")
                }
            createBiometricLockView()
                .tabItem {
                    Label("BiometricLock", systemImage: "faceid")
                }
            createTwoFactorView()
                .tabItem {
                    Label("TwoFactor", systemImage: "lock.shield.fill")
                }
            createPrivacySettingsView()
                .tabItem {
                    Label("PrivacySettings", systemImage: "hand.raised.fill")
                }
        }
    }
}
