import SwiftUI
import Core
import SharedUI

/// View for managing biometric authentication settings
/// Swift 5.9 - No Swift 6 features
struct BiometricSettingsView: View {
    @StateObject private var biometricService = BiometricAuthService.shared
    @AppStorage("biometric_enabled") private var biometricEnabled = false
    @AppStorage("biometric_app_lock") private var appLockEnabled = false
    @AppStorage("biometric_sensitive_data") private var protectSensitiveData = true
    @State private var showingError = false
    @State private var showingEnrollmentAlert = false
    
    var body: some View {
        List {
            // Status Section
            statusSection
            
            // Settings Section
            if biometricService.isAvailable {
                settingsSection
                
                // Security Options
                securitySection
            }
            
            // Information Section
            informationSection
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.large)
        .alert("Biometric Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(biometricService.error?.localizedDescription ?? "An error occurred")
        }
        .alert("Set Up \(biometricService.biometricType.displayName)", isPresented: $showingEnrollmentAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please set up \(biometricService.biometricType.displayName) in Settings to use biometric authentication.")
        }
        .onAppear {
            biometricService.checkBiometricAvailability()
        }
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        Section {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(biometricService.biometricType.displayName)
                            .font(.body)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: biometricService.biometricType.icon)
                        .font(.title2)
                        .foregroundColor(biometricService.isAvailable ? .green : .gray)
                }
                
                Spacer()
                
                if biometricService.isAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Biometric Authentication")
        }
    }
    
    private var settingsSection: some View {
        Section {
            Toggle(isOn: $biometricEnabled) {
                Label("Enable Biometric Authentication", systemImage: biometricService.biometricType.icon)
            }
            .onChange(of: biometricEnabled) { newValue in
                if newValue {
                    Task {
                        await testBiometric()
                    }
                }
            }
            
            if biometricEnabled {
                Toggle(isOn: $appLockEnabled) {
                    Label("Require on App Launch", systemImage: "lock.app.dashed")
                }
                
                HStack {
                    Label("Auto-lock Timeout", systemImage: "timer")
                    Spacer()
                    Menu {
                        Button("Immediately") {
                            UserDefaults.standard.set(0, forKey: "auto_lock_timeout")
                        }
                        Button("1 minute") {
                            UserDefaults.standard.set(60, forKey: "auto_lock_timeout")
                        }
                        Button("5 minutes") {
                            UserDefaults.standard.set(300, forKey: "auto_lock_timeout")
                        }
                        Button("15 minutes") {
                            UserDefaults.standard.set(900, forKey: "auto_lock_timeout")
                        }
                        Button("Never") {
                            UserDefaults.standard.set(-1, forKey: "auto_lock_timeout")
                        }
                    } label: {
                        Text(autoLockTimeoutText)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        } header: {
            Text("App Security")
        } footer: {
            Text("When enabled, you'll need to authenticate with \(biometricService.biometricType.displayName) to access the app.")
        }
    }
    
    private var securitySection: some View {
        Section {
            Toggle(isOn: $protectSensitiveData) {
                Label("Protect Financial Data", systemImage: "dollarsign.circle.fill")
            }
            
            if protectSensitiveData {
                Label {
                    Text("Protected items:")
                        .font(.caption)
                } icon: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 16))
                
                ForEach(protectedDataTypes, id: \.self) { dataType in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(dataType)
                            .font(.caption)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 50, bottom: 2, trailing: 16))
                }
            }
        } header: {
            Text("Data Protection")
        } footer: {
            Text("Sensitive financial information will require authentication to view.")
        }
    }
    
    private var informationSection: some View {
        Section {
            if !biometricService.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Not Available", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text(unavailableReason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if biometricService.error == .notEnrolled {
                        Button("Set Up \(biometricService.biometricType.displayName)") {
                            showingEnrollmentAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Privacy info
            VStack(alignment: .leading, spacing: 8) {
                Label("Privacy", systemImage: "hand.raised.fill")
                    .font(.headline)
                
                Text("• Biometric data never leaves your device")
                    .font(.caption)
                Text("• Authentication is handled by iOS")
                    .font(.caption)
                Text("• No biometric data is stored in the app")
                    .font(.caption)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Information")
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusText: String {
        if biometricService.isAvailable {
            return "Available and ready to use"
        } else if let error = biometricService.error {
            switch error {
            case .notEnrolled:
                return "Not set up on this device"
            case .passcodeNotSet:
                return "Device passcode not set"
            case .notAvailable:
                return "Not available on this device"
            default:
                return "Unavailable"
            }
        } else {
            return "Checking availability..."
        }
    }
    
    private var unavailableReason: String {
        if let error = biometricService.error {
            return error.localizedDescription
        } else {
            return "Biometric authentication is not available on this device."
        }
    }
    
    private var protectedDataTypes: [String] {
        [
            "Purchase prices",
            "Item values",
            "Total inventory value",
            "Financial reports",
            "Budget information"
        ]
    }
    
    private var autoLockTimeoutText: String {
        let timeout = UserDefaults.standard.integer(forKey: "auto_lock_timeout")
        switch timeout {
        case 0: return "Immediately"
        case 60: return "1 minute"
        case 300: return "5 minutes"
        case 900: return "15 minutes"
        case -1: return "Never"
        default: return "5 minutes"
        }
    }
    
    // MARK: - Methods
    
    private func testBiometric() async {
        let success = await biometricService.authenticate(
            reason: "Authenticate to enable biometric security"
        )
        
        if !success {
            biometricEnabled = false
            if biometricService.error != nil && biometricService.error != .userCancelled {
                showingError = true
            }
        }
    }
}

// MARK: - Preview

struct BiometricSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BiometricSettingsView()
        }
    }
}