//
//  TwoFactorSetupView.swift
//  Core
//
//  Setup flow for two-factor authentication
//

import SwiftUI
// Note: CodeScanner would be imported here for QR code functionality
// import CodeScanner

@available(iOS 15.0, *)
public struct TwoFactorSetupView: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var verificationCode = ""
    @State private var showingBackupCodes = false
    @State private var copiedSecret = false
    @State private var showingQRCode = false
    @State private var isVerifying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: authService.setupProgress)
                
                // Content based on current step
                Group {
                    switch authService.setupProgress {
                    case .notStarted:
                        WelcomeStep(authService: authService)
                    case .selectingMethod:
                        MethodSelectionStep(authService: authService)
                    case .configuringMethod:
                        ConfigurationStep(
                            authService: authService,
                            verificationCode: $verificationCode,
                            copiedSecret: $copiedSecret,
                            showingQRCode: $showingQRCode
                        )
                    case .verifying:
                        VerificationStep(
                            authService: authService,
                            verificationCode: $verificationCode,
                            isVerifying: $isVerifying,
                            showingError: $showingError,
                            errorMessage: $errorMessage
                        )
                    case .backupCodes:
                        BackupCodesStep(
                            authService: authService,
                            showingBackupCodes: $showingBackupCodes
                        )
                    case .completed:
                        CompletionStep(authService: authService, dismiss: dismiss)
                    }
                }
                .animation(.easeInOut, value: authService.setupProgress)
            }
            .navigationTitle("Set Up Two-Factor Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingBackupCodes) {
                BackupCodesView(codes: authService.backupCodes)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let currentStep: TwoFactorAuthService.SetupProgress
    
    private let steps: [TwoFactorAuthService.SetupProgress] = [
        .selectingMethod,
        .configuringMethod,
        .verifying,
        .backupCodes,
        .completed
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { index in
                let step = steps[index]
                let isCompleted = currentStep.stepNumber > step.stepNumber
                let isCurrent = currentStep.stepNumber == step.stepNumber
                
                Circle()
                    .fill(isCompleted || isCurrent ? Color.blue : Color(.systemGray4))
                    .frame(width: 8, height: 8)
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(isCompleted ? Color.blue : Color(.systemGray4))
                        .frame(height: 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Text("Secure Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Two-factor authentication adds an extra layer of security to your account by requiring both your password and a verification code.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(
                        icon: "shield.lefthalf.filled",
                        title: "Enhanced Security",
                        description: "Protect your inventory data from unauthorized access"
                    )
                    
                    BenefitRow(
                        icon: "lock.rotation",
                        title: "Multiple Methods",
                        description: "Choose from authenticator apps, SMS, email, or biometrics"
                    )
                    
                    BenefitRow(
                        icon: "key.fill",
                        title: "Backup Codes",
                        description: "Access your account even if you lose your device"
                    )
                }
                .padding()
                
                Spacer(minLength: 40)
                
                Button(action: { authService.startSetup() }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Method Selection Step

struct MethodSelectionStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Choose Authentication Method")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select how you'd like to verify your identity")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                VStack(spacing: 12) {
                    ForEach(authService.availableMethods, id: \.self) { method in
                        MethodCard(
                            method: method,
                            isRecommended: method == .authenticator
                        ) {
                            authService.selectMethod(method)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Configuration Step

struct ConfigurationStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Binding var verificationCode: String
    @Binding var copiedSecret: Bool
    @Binding var showingQRCode: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch authService.preferredMethod {
                case .authenticator:
                    AuthenticatorConfiguration(
                        authService: authService,
                        copiedSecret: $copiedSecret,
                        showingQRCode: $showingQRCode
                    )
                case .sms:
                    SMSConfiguration(authService: authService)
                case .email:
                    EmailConfiguration(authService: authService)
                case .biometric:
                    BiometricConfiguration(authService: authService)
                }
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - Verification Step

struct VerificationStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Binding var verificationCode: String
    @Binding var isVerifying: Bool
    @Binding var showingError: Bool
    @Binding var errorMessage: String
    
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Enter Verification Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(descriptionText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Code input
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitView(
                            digit: digit(at: index),
                            isActive: index == verificationCode.count
                        )
                    }
                }
                .onTapGesture {
                    isCodeFieldFocused = true
                }
                
                // Hidden text field for input
                TextField("", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .focused($isCodeFieldFocused)
                    .opacity(0)
                    .frame(width: 1, height: 1)
                    .onChange(of: verificationCode) { newValue in
                        if newValue.count > 6 {
                            verificationCode = String(newValue.prefix(6))
                        }
                        if newValue.count == 6 {
                            verifyCode()
                        }
                    }
                
                if authService.preferredMethod == .authenticator {
                    Text("Open your authenticator app and enter the 6-digit code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
                
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
        .onAppear {
            isCodeFieldFocused = true
        }
    }
    
    private var descriptionText: String {
        switch authService.preferredMethod {
        case .authenticator:
            return "Enter the code from your authenticator app"
        case .sms:
            return "Enter the code we sent to your phone"
        case .email:
            return "Enter the code we sent to your email"
        case .biometric:
            return "Use your biometric authentication"
        }
    }
    
    private func digit(at index: Int) -> String? {
        guard index < verificationCode.count else { return nil }
        let stringIndex = verificationCode.index(verificationCode.startIndex, offsetBy: index)
        return String(verificationCode[stringIndex])
    }
    
    private func verifyCode() {
        isVerifying = true
        
        Task {
            do {
                let success = try await authService.verifyCode(verificationCode)
                if !success {
                    errorMessage = "Invalid verification code. Please try again."
                    showingError = true
                    verificationCode = ""
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                verificationCode = ""
            }
            
            isVerifying = false
        }
    }
}

// MARK: - Backup Codes Step

struct BackupCodesStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Binding var showingBackupCodes: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Text("Save Your Backup Codes")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("These codes can be used to access your account if you lose access to your authentication method. Each code can only be used once.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("⚠️ Store them in a safe place")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                // Backup codes preview
                VStack(spacing: 8) {
                    ForEach(authService.backupCodes.prefix(3), id: \.self) { code in
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    if authService.backupCodes.count > 3 {
                        Text("+ \(authService.backupCodes.count - 3) more codes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                HStack(spacing: 12) {
                    Button(action: { showingBackupCodes = true }) {
                        Label("View All Codes", systemImage: "eye")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    
                    Button(action: downloadCodes) {
                        Label("Download", systemImage: "arrow.down.doc")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
                
                Button(action: { authService.enable() }) {
                    Text("I've Saved My Codes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func downloadCodes() {
        if let url = authService.downloadBackupCodes() {
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Completion Step

struct CompletionStep: View {
    @ObservedObject var authService: TwoFactorAuthService
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Two-factor authentication is now enabled for your account")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(
                    icon: "checkmark.shield",
                    text: "Your account is now more secure"
                )
                
                InfoRow(
                    icon: "key.fill",
                    text: "Backup codes saved for emergency access"
                )
                
                InfoRow(
                    icon: "iphone",
                    text: "This device is now trusted"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Supporting Views

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
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

struct MethodCard: View {
    let method: TwoFactorAuthService.TwoFactorMethod
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(method.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isRecommended {
                            Text("Recommended")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CodeDigitView: View {
    let digit: String?
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color(.systemGray4), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
                .frame(width: 44, height: 54)
            
            if let digit = digit {
                Text(digit)
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Configuration Views

struct AuthenticatorConfiguration: View {
    @ObservedObject var authService: TwoFactorAuthService
    @Binding var copiedSecret: Bool
    @Binding var showingQRCode: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Set Up Authenticator App")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Scan the QR code or enter the secret key manually")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // QR Code placeholder
            Button(action: { showingQRCode = true }) {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 120))
                        .foregroundColor(.blue)
                    
                    Text("Tap to view QR code")
                        .font(.callout)
                        .foregroundColor(.blue)
                }
                .frame(width: 200, height: 200)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Manual entry option
            VStack(alignment: .leading, spacing: 12) {
                Text("Or enter this code manually:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Secret Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if copiedSecret {
                        Label("Copied!", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: copySecret) {
                    HStack {
                        Text("XXXX-XXXX-XXXX-XXXX")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Supported apps
            VStack(spacing: 8) {
                Text("Popular authenticator apps:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    AppLink(name: "Google Authenticator", icon: "g.circle.fill")
                    AppLink(name: "Microsoft Authenticator", icon: "m.circle.fill")
                    AppLink(name: "Authy", icon: "a.circle.fill")
                }
            }
            .padding(.top)
            
            Spacer()
            
            Button(action: proceedToVerification) {
                Text("I've Added the Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private func copySecret() {
        // Copy secret to clipboard
        UIPasteboard.general.string = "XXXX-XXXX-XXXX-XXXX" // Would use actual secret
        
        withAnimation {
            copiedSecret = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedSecret = false
            }
        }
    }
    
    private func proceedToVerification() {
        authService.setupProgress = .verifying
    }
}

struct SMSConfiguration: View {
    @ObservedObject var authService: TwoFactorAuthService
    @State private var phoneNumber = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("SMS Authentication")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your phone number to receive verification codes via text message")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Phone Number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: { authService.setupProgress = .verifying }) {
                Text("Send Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(phoneNumber.isEmpty)
            .padding(.horizontal)
        }
    }
}

struct EmailConfiguration: View {
    @ObservedObject var authService: TwoFactorAuthService
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Email Authentication")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("We'll send verification codes to your registered email address")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                Text("user@example.com")
                    .font(.body)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { authService.setupProgress = .verifying }) {
                Text("Send Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

struct BiometricConfiguration: View {
    @ObservedObject var authService: TwoFactorAuthService
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Biometric Authentication")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Use Face ID or Touch ID as your second factor")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: { authService.setupProgress = .verifying }) {
                Text("Enable Biometric Authentication")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

struct AppLink: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}