//
//  LockScreenView.swift
//  Core
//
//  Lock screen interface with authentication
//

import SwiftUI
import LocalAuthentication

@available(iOS 15.0, *)
public struct LockScreenView: View {
    @StateObject private var lockService = AutoLockService.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var passcode = ""
    @State private var showingPasscode = false
    @State private var isUnlocking = false
    @State private var wrongAttemptAnimation = false
    
    private let maxPasscodeLength = 6
    
    public var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .ignoresSafeArea()
                )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(wrongAttemptAnimation ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.3), value: wrongAttemptAnimation)
                
                // Title
                VStack(spacing: 8) {
                    Text("Home Inventory Locked")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(getLockReasonText())
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Authentication button or passcode
                if showingPasscode {
                    PasscodeView(
                        passcode: $passcode,
                        maxLength: maxPasscodeLength,
                        onComplete: { code in
                            handlePasscodeEntry(code)
                        }
                    )
                    .padding(.horizontal, 40)
                } else {
                    VStack(spacing: 16) {
                        // Biometric button
                        if lockService.isBiometricAvailable() {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    Image(systemName: biometricIcon)
                                        .font(.title2)
                                    
                                    Text("Unlock with \(biometricName)")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: 280)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isUnlocking)
                        }
                        
                        // Passcode option
                        Button(action: { showingPasscode = true }) {
                            Text("Use Passcode")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // Failed attempts warning
                if lockService.failedAttempts > 0 {
                    Text("\(lockService.failedAttempts) failed attempt\(lockService.failedAttempts == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Spacer()
                Spacer()
            }
            
            // Loading overlay
            if isUnlocking {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Unlocking...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                }
            }
        }
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("OK") {
                wrongAttemptAnimation = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if !lockService.requireAuthentication {
                // Auto-unlock if authentication not required
                Task {
                    try? await lockService.unlock()
                }
            } else if lockService.isBiometricAvailable() && !showingPasscode {
                // Auto-trigger biometric authentication
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
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
            return "Biometrics"
        }
    }
    
    private func getLockReasonText() -> String {
        switch lockService.autoLockTimeout {
        case .immediate:
            return "Authentication required"
        case .never:
            return "App was locked"
        default:
            return "Locked after \(lockService.autoLockTimeout.displayName.lowercased()) of inactivity"
        }
    }
    
    private func authenticateWithBiometrics() {
        isUnlocking = true
        
        Task {
            do {
                try await lockService.unlock()
            } catch {
                isUnlocking = false
                errorMessage = error.localizedDescription
                showingError = true
                triggerWrongAttemptAnimation()
            }
        }
    }
    
    private func handlePasscodeEntry(_ code: String) {
        // In a real app, verify against stored passcode
        // For demo, accept any 6-digit code
        if code.count == maxPasscodeLength {
            isUnlocking = true
            
            Task {
                do {
                    try await lockService.unlock()
                } catch {
                    isUnlocking = false
                    passcode = ""
                    errorMessage = "Invalid passcode"
                    showingError = true
                    triggerWrongAttemptAnimation()
                }
            }
        }
    }
    
    private func triggerWrongAttemptAnimation() {
        wrongAttemptAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wrongAttemptAnimation = false
        }
    }
}

// MARK: - Passcode View

struct PasscodeView: View {
    @Binding var passcode: String
    let maxLength: Int
    let onComplete: (String) -> Void
    
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Passcode dots
            HStack(spacing: 16) {
                ForEach(0..<maxLength, id: \.self) { index in
                    Circle()
                        .fill(index < passcode.count ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            
            // Hidden text field
            TextField("", text: $passcode)
                .keyboardType(.numberPad)
                .focused($isKeyboardFocused)
                .opacity(0.01)
                .onChange(of: passcode) { newValue in
                    // Limit to numbers only
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        passcode = filtered
                    }
                    
                    // Limit length
                    if passcode.count > maxLength {
                        passcode = String(passcode.prefix(maxLength))
                    }
                    
                    // Auto-submit when complete
                    if passcode.count == maxLength {
                        onComplete(passcode)
                    }
                }
            
            // Number pad buttons (optional visual feedback)
            Text("Enter your \(maxLength)-digit passcode")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear {
            isKeyboardFocused = true
        }
    }
}

// MARK: - Blur View

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}