import XCTest
import SnapshotTesting
import SwiftUI

final class OnboardingFlowTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testWelcomeScreen() {
        let view = WelcomeView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testFeaturesScreen() {
        let view = FeaturesView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testPermissionsScreen() {
        let view = PermissionsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAccountSetupScreen() {
        let view = AccountSetupView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCompletionScreen() {
        let view = CompletionView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Home Inventory")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
            }
            
            Text("Keep track of everything you own\nin one secure place")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {}) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("I already have an account")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct FeaturesView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Key Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 24) {
                OnboardingFeatureRow(
                    icon: "camera.fill",
                    title: "Quick Capture",
                    description: "Add items instantly with your camera",
                    color: .blue
                )
                
                OnboardingFeatureRow(
                    icon: "doc.text.fill",
                    title: "Smart Organization",
                    description: "Automatically categorize your belongings",
                    color: .green
                )
                
                OnboardingFeatureRow(
                    icon: "lock.fill",
                    title: "Secure & Private",
                    description: "Your data is encrypted and protected",
                    color: .purple
                )
                
                OnboardingFeatureRow(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    description: "Access your inventory anywhere",
                    color: .orange
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {}) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 1 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PermissionsView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Enable Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 24) {
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera Access",
                    description: "Quickly add items by taking photos",
                    isEnabled: true
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get reminders about warranties",
                    isEnabled: false
                )
                
                PermissionRow(
                    icon: "location.fill",
                    title: "Location Services",
                    description: "Tag items with their location",
                    isEnabled: false
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {}) {
                    Text("Enable All")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("Set Up Later")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 2 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct AccountSetupView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 20) {
                TextField("Email", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 32)
            
            Text("Or continue with")
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                SocialButton(icon: "apple.logo", color: .black)
                SocialButton(icon: "g.circle.fill", color: .red)
                SocialButton(icon: "f.circle.fill", color: .blue)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 3 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(30)
        }
    }
}

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start adding items to your inventory\nand keep track of everything you own")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Start Using Home Inventory")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 4 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}