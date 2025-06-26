//
//  AutoLockSettingsView.swift
//  Core
//
//  Settings for configuring auto-lock behavior
//

import SwiftUI

@available(iOS 15.0, *)
public struct AutoLockSettingsView: View {
    public init() {}
    @StateObject private var lockService = AutoLockService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingTestLock = false
    @State private var showingResetConfirmation = false
    
    public var body: some View {
        NavigationView {
            Form {
                // Auto-lock toggle
                Section {
                    Toggle("Enable Auto-Lock", isOn: Binding(
                        get: { lockService.autoLockEnabled },
                        set: { enabled in
                            if enabled {
                                lockService.enableAutoLock(timeout: lockService.autoLockTimeout)
                            } else {
                                lockService.disableAutoLock()
                            }
                        }
                    ))
                } footer: {
                    Text("Automatically lock the app after a period of inactivity to protect your data")
                }
                
                // Timeout settings
                if lockService.autoLockEnabled {
                    Section {
                        Picker("Lock After", selection: Binding(
                            get: { lockService.autoLockTimeout },
                            set: { lockService.updateTimeout($0) }
                        )) {
                            ForEach(AutoLockService.AutoLockTimeout.allCases, id: \.self) { timeout in
                                Text(timeout.displayName).tag(timeout)
                            }
                        }
                    } header: {
                        Text("Timeout")
                    } footer: {
                        Text(getTimeoutDescription())
                    }
                }
                
                // Authentication settings
                Section {
                    Toggle("Require Authentication", isOn: Binding(
                        get: { lockService.requireAuthentication },
                        set: { lockService.updateSettings(requireAuth: $0) }
                    ))
                    
                    if lockService.requireAuthentication {
                        HStack {
                            Image(systemName: biometricIcon)
                                .foregroundColor(.blue)
                            Text("\(biometricName) Available")
                                .foregroundColor(.secondary)
                            Spacer()
                            if lockService.isBiometricAvailable() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("Security")
                } footer: {
                    if lockService.requireAuthentication {
                        Text("Use \(biometricName) or device passcode to unlock the app")
                    } else {
                        Text("⚠️ Warning: Disabling authentication reduces security")
                    }
                }
                
                // Additional lock triggers
                Section {
                    Toggle("Lock on Background", isOn: Binding(
                        get: { lockService.lockOnBackground },
                        set: { lockService.updateSettings(lockOnBackground: $0) }
                    ))
                    
                    Toggle("Lock on Screenshot", isOn: Binding(
                        get: { lockService.lockOnScreenshot },
                        set: { lockService.updateSettings(lockOnScreenshot: $0) }
                    ))
                } header: {
                    Text("Additional Triggers")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if lockService.lockOnBackground {
                            Text("• App will lock when moved to background")
                        }
                        if lockService.lockOnScreenshot {
                            Text("• App will lock when a screenshot is taken")
                        }
                    }
                    .font(.caption)
                }
                
                // Test and info
                Section {
                    Button(action: testLock) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Test Lock Screen")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Failed Attempts")
                        Spacer()
                        Text("\(lockService.failedAttempts)")
                            .foregroundColor(.secondary)
                    }
                    
                    if lockService.failedAttempts > 0 {
                        Button(action: { showingResetConfirmation = true }) {
                            Label("Reset Failed Attempts", systemImage: "arrow.counterclockwise")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Testing & Info")
                }
                
                // Statistics
                if lockService.autoLockEnabled {
                    Section {
                        HStack {
                            Label("Last Activity", systemImage: "clock")
                            Spacer()
                            Text(lockService.lastActivityTime, style: .relative)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Current Status", systemImage: "info.circle")
                            Spacer()
                            Text(lockService.isLocked ? "Locked" : "Unlocked")
                                .foregroundColor(lockService.isLocked ? .red : .green)
                                .fontWeight(.medium)
                        }
                    } header: {
                        Text("Status")
                    }
                }
            }
            .navigationTitle("Auto-Lock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Failed Attempts", isPresented: $showingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    lockService.failedAttempts = 0
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset the failed authentication attempt counter.")
            }
        }
    }
    
    private var biometricIcon: String {
        switch lockService.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var biometricName: String {
        switch lockService.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    private func getTimeoutDescription() -> String {
        switch lockService.autoLockTimeout {
        case .immediate:
            return "App will lock immediately when inactive"
        case .never:
            return "App will only lock manually or based on other triggers"
        default:
            return "App will lock after \(lockService.autoLockTimeout.displayName.lowercased()) of inactivity"
        }
    }
    
    private func testLock() {
        // Save current state
        let wasLocked = lockService.isLocked
        
        // Lock the app
        lockService.lock(reason: .manual)
        
        // Show lock screen
        showingTestLock = true
        
        // If app wasn't locked before, schedule unlock after test
        if !wasLocked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // The lock screen will handle the unlock
            }
        }
    }
}

// MARK: - Quick Toggle View

@available(iOS 15.0, *)
public struct AutoLockQuickToggle: View {
    @StateObject private var lockService = AutoLockService.shared
    
    public var body: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundColor(lockService.autoLockEnabled ? .blue : .secondary)
            
            Text("Auto-Lock")
            
            Spacer()
            
            if lockService.autoLockEnabled {
                Text(lockService.autoLockTimeout.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Toggle("", isOn: Binding(
                get: { lockService.autoLockEnabled },
                set: { enabled in
                    if enabled {
                        lockService.enableAutoLock(timeout: lockService.autoLockTimeout)
                    } else {
                        lockService.disableAutoLock()
                    }
                }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Lock Status Indicator

@available(iOS 15.0, *)
public struct LockStatusIndicator: View {
    @StateObject private var lockService = AutoLockService.shared
    
    public var body: some View {
        if lockService.autoLockEnabled {
            HStack(spacing: 4) {
                Image(systemName: lockService.isLocked ? "lock.fill" : "lock.open")
                    .font(.caption)
                    .foregroundColor(lockService.isLocked ? .red : .green)
                
                if !lockService.isLocked {
                    Text(timeUntilLock)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var timeUntilLock: String {
        guard let timeout = lockService.autoLockTimeout.seconds else {
            return "No timeout"
        }
        
        let timeSinceActivity = Date().timeIntervalSince(lockService.lastActivityTime)
        let timeRemaining = max(0, timeout - timeSinceActivity)
        
        if timeRemaining < 60 {
            return "\(Int(timeRemaining))s"
        } else {
            let minutes = Int(timeRemaining / 60)
            return "\(minutes)m"
        }
    }
}