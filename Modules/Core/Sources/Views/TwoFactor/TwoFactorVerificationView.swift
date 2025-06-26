//
//  TwoFactorVerificationView.swift
//  Core
//
//  Verification view for two-factor authentication
//

import SwiftUI

@available(iOS 15.0, *)
public struct TwoFactorVerificationView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var attemptsRemaining = 3
    @State private var showingBackupOption = false
    @State private var selectedTrustedDevice: TwoFactorAuthService.TrustedDevice?
    @State private var trustThisDevice = false
    
    @FocusState private var isCodeFieldFocused: Bool
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: authService.preferredMethod.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    // Title and description
                    VStack(spacing: 8) {
                        Text("Two-Factor Authentication")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(descriptionText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Code input or biometric button
                    if authService.preferredMethod == .biometric {
                        BiometricVerificationView(authService: authService)
                    } else {
                        CodeInputView(
                            code: $verificationCode,
                            isCodeFieldFocused: _isCodeFieldFocused,
                            onComplete: verifyCode
                        )
                    }
                    
                    // Trust device option
                    if authService.preferredMethod != .biometric {
                        Toggle(isOn: $trustThisDevice) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text("Trust This Device")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("Don't ask for codes on this device for 30 days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Alternative options
                    VStack(spacing: 16) {
                        if authService.preferredMethod != .biometric {
                            Button(action: resendCode) {
                                Text("Resend Code")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Button(action: { showingBackupOption = true }) {
                            Text("Use Backup Method")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        if attemptsRemaining < 3 {
                            Text("\(attemptsRemaining) attempts remaining")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Verify button
                    if authService.preferredMethod != .biometric {
                        Button(action: verifyCode) {
                            HStack {
                                if isVerifying {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Verify")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(verificationCode.count != 6 || isVerifying)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield")
                            .font(.subheadline)
                        Text("Secure Login")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingBackupOption) {
                BackupOptionsView(
                    authService: authService,
                    onSuccess: {
                        authService.isVerified = true
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            if authService.preferredMethod != .biometric {
                isCodeFieldFocused = true
            }
        }
    }
    
    private var descriptionText: String {
        switch authService.preferredMethod {
        case .authenticator:
            return "Enter the 6-digit code from your authenticator app"
        case .sms:
            return "Enter the code we sent to your phone"
        case .email:
            return "Enter the code we sent to your email"
        case .biometric:
            return "Verify your identity with Face ID or Touch ID"
        }
    }
    
    private func verifyCode() {
        isVerifying = true
        
        Task {
            do {
                let success = try await authService.verifyCode(verificationCode)
                
                if success {
                    if trustThisDevice {
                        authService.trustCurrentDevice()
                    }
                    
                    authService.isVerified = true
                    dismiss()
                } else {
                    attemptsRemaining -= 1
                    
                    if attemptsRemaining == 0 {
                        errorMessage = "Too many failed attempts. Please try again later or use a backup method."
                    } else {
                        errorMessage = "Invalid code. Please try again."
                    }
                    
                    showingError = true
                    verificationCode = ""
                    isCodeFieldFocused = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                verificationCode = ""
            }
            
            isVerifying = false
        }
    }
    
    private func resendCode() {
        // In real implementation, would resend the code
        verificationCode = ""
        isCodeFieldFocused = true
    }
}

// MARK: - Code Input View

struct CodeInputView: View {
    @Binding var code: String
    @FocusState var isCodeFieldFocused: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Code digits display
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitView(
                        digit: digit(at: index),
                        isActive: index == code.count
                    )
                }
            }
            .onTapGesture {
                isCodeFieldFocused = true
            }
            
            // Hidden text field for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isCodeFieldFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: code) { newValue in
                    // Only allow digits
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        code = filtered
                    }
                    
                    // Limit to 6 digits
                    if code.count > 6 {
                        code = String(code.prefix(6))
                    }
                    
                    // Auto-submit when complete
                    if code.count == 6 {
                        onComplete()
                    }
                }
            
            Text("Enter 6-digit code")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func digit(at index: Int) -> String? {
        guard index < code.count else { return nil }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

// MARK: - Biometric Verification View

struct BiometricVerificationView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @State private var isAuthenticating = false
    @State private var authFailed = false
    
    var body: some View {
        VStack(spacing: 24) {
            Button(action: authenticate) {
                VStack(spacing: 16) {
                    Image(systemName: "faceid")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Tap to Authenticate")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 200)
                .background(
                    Circle()
                        .fill(authFailed ? Color.red : Color.blue)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
                .scaleEffect(isAuthenticating ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isAuthenticating)
            }
            .buttonStyle(PlainButtonStyle())
            
            if authFailed {
                Text("Authentication failed. Please try again.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // Auto-trigger biometric authentication
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        authFailed = false
        
        Task {
            do {
                let success = try await authService.verifyCode("biometric")
                if success {
                    authService.isVerified = true
                } else {
                    authFailed = true
                }
            } catch {
                authFailed = true
            }
            
            isAuthenticating = false
        }
    }
}

// MARK: - Backup Options View

struct BackupOptionsView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOption: BackupOption = .backupCode
    @State private var backupCode = ""
    @State private var isVerifying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onSuccess: () -> Void
    
    enum BackupOption: String, CaseIterable {
        case backupCode = "Backup Code"
        case email = "Email"
        case sms = "SMS"
        case recovery = "Account Recovery"
        
        var icon: String {
            switch self {
            case .backupCode: return "key.fill"
            case .email: return "envelope.fill"
            case .sms: return "message.fill"
            case .recovery: return "person.crop.circle.badge.questionmark"
            }
        }
        
        var description: String {
            switch self {
            case .backupCode:
                return "Use one of your saved backup codes"
            case .email:
                return "Send a verification code to your email"
            case .sms:
                return "Send a verification code to your phone"
            case .recovery:
                return "Start the account recovery process"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Backup Verification")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Choose an alternative method to verify your identity")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 24)
                    
                    // Backup options
                    VStack(spacing: 12) {
                        ForEach(BackupOption.allCases, id: \.self) { option in
                            BackupOptionCard(
                                option: option,
                                isSelected: selectedOption == option
                            ) {
                                selectedOption = option
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Option-specific content
                    Group {
                        switch selectedOption {
                        case .backupCode:
                            BackupCodeInput(code: $backupCode)
                        case .email, .sms:
                            SendCodeView(method: selectedOption)
                        case .recovery:
                            RecoveryInfoView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer(minLength: 40)
                    
                    // Action button
                    Button(action: performBackupVerification) {
                        HStack {
                            if isVerifying {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(actionButtonTitle)
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(selectedOption == .backupCode && backupCode.isEmpty || isVerifying)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var actionButtonTitle: String {
        switch selectedOption {
        case .backupCode:
            return "Verify Code"
        case .email, .sms:
            return "Send Code"
        case .recovery:
            return "Start Recovery"
        }
    }
    
    private func performBackupVerification() {
        isVerifying = true
        
        Task {
            switch selectedOption {
            case .backupCode:
                if authService.useBackupCode(backupCode) {
                    onSuccess()
                } else {
                    errorMessage = "Invalid backup code"
                    showingError = true
                }
            case .email:
                // Send email code
                try? await authService.initiateRecovery(email: "user@example.com")
                errorMessage = "Verification code sent to your email"
                showingError = true
            case .sms:
                // Send SMS code
                errorMessage = "Verification code sent to your phone"
                showingError = true
            case .recovery:
                // Start recovery process
                try? await authService.initiateRecovery(email: "user@example.com")
                errorMessage = "Recovery instructions sent to your email"
                showingError = true
            }
            
            isVerifying = false
        }
    }
}

// MARK: - Backup Option Card

struct BackupOptionCard: View {
    let option: BackupOptionsView.BackupOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Backup Code Input

struct BackupCodeInput: View {
    @Binding var code: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter one of your backup codes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("XXXX-XXXX", text: $code)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
            
            Text("Each backup code can only be used once")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Send Code View

struct SendCodeView: View {
    let method: BackupOptionsView.BackupOption
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: method.icon)
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text(method == .email ? "Send code to email" : "Send code to phone")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(method == .email ? "user@example.com" : "+1 (555) 123-4567")
                .font(.body)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Recovery Info View

struct RecoveryInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Account Recovery")
                    .font(.headline)
            }
            
            Text("Account recovery will temporarily disable two-factor authentication. You'll need to:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                RecoveryStep(number: "1", text: "Verify your email address")
                RecoveryStep(number: "2", text: "Answer security questions")
                RecoveryStep(number: "3", text: "Wait for review (24-48 hours)")
                RecoveryStep(number: "4", text: "Re-enable two-factor authentication")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RecoveryStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.orange)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}