//
//  TwoFactorSettingsView.swift
//  Core
//
//  Settings view for managing two-factor authentication
//

import SwiftUI

@available(iOS 15.0, *)
public struct TwoFactorSettingsView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @State private var showingSetup = false
    @State private var showingDisableConfirmation = false
    @State private var showingBackupCodes = false
    @State private var showingMethodChange = false
    @State private var showingTrustedDevices = false
    @State private var isDisabling = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public var body: some View {
        Form {
            // Status section
            Section {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Two-Factor Authentication")
                                .font(.headline)
                            
                            Text(authService.isEnabled ? "Enabled" : "Disabled")
                                .font(.subheadline)
                                .foregroundColor(authService.isEnabled ? .green : .secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundColor(authService.isEnabled ? .green : .secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(authService.isEnabled))
                        .labelsHidden()
                        .disabled(true)
                        .onTapGesture {
                            if authService.isEnabled {
                                showingDisableConfirmation = true
                            } else {
                                showingSetup = true
                            }
                        }
                }
            } footer: {
                Text(authService.isEnabled
                    ? "Your account is protected with an additional layer of security"
                    : "Enable two-factor authentication for enhanced account security")
            }
            
            if authService.isEnabled {
                // Current method
                Section {
                    Button(action: { showingMethodChange = true }) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Authentication Method")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(authService.preferredMethod.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: authService.preferredMethod.icon)
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Current Method")
                }
                
                // Backup codes
                Section {
                    Button(action: { showingBackupCodes = true }) {
                        HStack {
                            Label("View Backup Codes", systemImage: "key.fill")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(authService.backupCodes.count) available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if authService.backupCodes.count < 5 {
                        Button(action: regenerateBackupCodes) {
                            Label("Generate New Backup Codes", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Backup Codes")
                } footer: {
                    if authService.backupCodes.count < 5 {
                        Label("Running low on backup codes. Generate new ones to ensure account access.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Trusted devices
                Section {
                    Button(action: { showingTrustedDevices = true }) {
                        HStack {
                            Label("Manage Trusted Devices", systemImage: "iphone")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(authService.trustedDevices.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Trusted Devices")
                } footer: {
                    Text("Trusted devices don't require verification codes for 30 days")
                }
                
                // Security actions
                Section {
                    Button(role: .destructive, action: { showingDisableConfirmation = true }) {
                        HStack {
                            if isDisabling {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Label("Disable Two-Factor Authentication", systemImage: "xmark.shield")
                            }
                        }
                    }
                    .disabled(isDisabling)
                }
            } else {
                // Setup prompt
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Enhance Your Security")
                            .font(.headline)
                        
                        Text("Add an extra layer of protection to your account with two-factor authentication")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingSetup = true }) {
                            Text("Set Up Two-Factor Authentication")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Two-Factor Authentication")
        .sheet(isPresented: $showingSetup) {
            TwoFactorSetupView(authService: authService)
        }
        .sheet(isPresented: $showingBackupCodes) {
            BackupCodesView(codes: authService.backupCodes)
        }
        .sheet(isPresented: $showingMethodChange) {
            ChangeMethodView(authService: authService)
        }
        .sheet(isPresented: $showingTrustedDevices) {
            TrustedDevicesView(authService: authService)
        }
        .alert("Disable Two-Factor Authentication?", isPresented: $showingDisableConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disable", role: .destructive) {
                disableTwoFactor()
            }
        } message: {
            Text("This will make your account less secure. You'll need to authenticate to confirm this action.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func regenerateBackupCodes() {
        authService.generateBackupCodes()
        showingBackupCodes = true
    }
    
    private func disableTwoFactor() {
        isDisabling = true
        
        Task {
            do {
                try await authService.disable()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isDisabling = false
        }
    }
}

// MARK: - Change Method View

struct ChangeMethodView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMethod: TwoFactorAuthService.TwoFactorMethod?
    @State private var showingVerification = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(authService.availableMethods, id: \.self) { method in
                        MethodRow(
                            method: method,
                            isSelected: method == selectedMethod,
                            isCurrent: method == authService.preferredMethod
                        ) {
                            if method != authService.preferredMethod {
                                selectedMethod = method
                            }
                        }
                    }
                } header: {
                    Text("Available Methods")
                } footer: {
                    Text("You'll need to verify your identity before changing methods")
                }
            }
            .navigationTitle("Change Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") {
                        showingVerification = true
                    }
                    .disabled(selectedMethod == nil)
                }
            }
            .sheet(isPresented: $showingVerification) {
                if let method = selectedMethod {
                    VerifyAndChangeView(
                        authService: authService,
                        newMethod: method
                    ) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Method Row

struct MethodRow: View {
    let method: TwoFactorAuthService.TwoFactorMethod
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(method.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isCurrent {
                            Text("Current")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(isCurrent)
    }
}

// MARK: - Verify and Change View

struct VerifyAndChangeView: View {
    @ObservedObject var authService: TwoFactorAuthService
    let newMethod: TwoFactorAuthService.TwoFactorMethod
    let onSuccess: () -> Void
    
    @State private var isVerifying = false
    @State private var verificationCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Verify Current Method")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Verification UI would go here
                
                Button("Verify and Change") {
                    // Perform verification and method change
                    authService.selectMethod(newMethod)
                    onSuccess()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Trusted Devices View

struct TrustedDevicesView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var deviceToRemove: TwoFactorAuthService.TrustedDevice?
    
    var body: some View {
        NavigationView {
            List {
                if authService.trustedDevices.isEmpty {
                    ContentUnavailableView(
                        "No Trusted Devices",
                        systemImage: "iphone.slash",
                        description: Text("Devices you trust will appear here")
                    )
                } else {
                    ForEach(authService.trustedDevices) { device in
                        TrustedDeviceRow(device: device) {
                            deviceToRemove = device
                        }
                    }
                }
            }
            .navigationTitle("Trusted Devices")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Remove Trusted Device?", isPresented: .constant(deviceToRemove != nil)) {
                Button("Cancel", role: .cancel) {
                    deviceToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let device = deviceToRemove {
                        authService.removeTrustedDevice(device)
                        deviceToRemove = nil
                    }
                }
            } message: {
                if let device = deviceToRemove {
                    Text("This device will need to enter a verification code on the next login. Device: \(device.deviceName)")
                }
            }
        }
    }
}

// MARK: - Trusted Device Row

struct TrustedDeviceRow: View {
    let device: TwoFactorAuthService.TrustedDevice
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: device.deviceType.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(device.deviceName)
                            .font(.headline)
                        
                        if device.isCurrentDevice {
                            Text("This Device")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(device.deviceType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !device.isCurrentDevice {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Label("Trusted \(device.trustedDate.formatted(.relative(presentation: .named)))", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("Last used \(device.lastUsedDate.formatted(.relative(presentation: .named)))", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}