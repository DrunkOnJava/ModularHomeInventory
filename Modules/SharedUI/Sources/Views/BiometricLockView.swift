import SwiftUI
import Core

/// Lock screen view that requires biometric authentication
/// Swift 5.9 - No Swift 6 features
public struct BiometricLockView: View {
    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var isUnlocking = false
    @State private var showingError = false
    @State private var attemptCount = 0
    
    let onAuthenticated: () -> Void
    let onCancel: (() -> Void)?
    
    public init(
        onAuthenticated: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.onAuthenticated = onAuthenticated
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // App icon or lock icon
                ZStack {
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 120, height: 120)
                        .shadow(radius: 20)
                    
                    Image(systemName: biometricService.biometricType.icon)
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                }
                .scaleEffect(isUnlocking ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isUnlocking)
                
                // Title
                VStack(spacing: 8) {
                    Text("Home Inventory Locked")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Authenticate to continue")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Authentication button
                VStack(spacing: 20) {
                    Button(action: authenticate) {
                        Label(
                            "Unlock with \(biometricService.biometricType.displayName)",
                            systemImage: biometricService.biometricType.icon
                        )
                        .frame(maxWidth: 280)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUnlocking)
                    
                    if attemptCount > 1 {
                        Button(action: authenticateWithPasscode) {
                            Text("Use Passcode")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    if let onCancel = onCancel {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("Try Again") {
                authenticate()
            }
            if let onCancel = onCancel {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            }
        } message: {
            Text(biometricService.error?.localizedDescription ?? "Unable to authenticate. Please try again.")
        }
        .onAppear {
            // Automatically attempt authentication on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticate()
            }
        }
    }
    
    // MARK: - Methods
    
    private func authenticate() {
        isUnlocking = true
        attemptCount += 1
        
        Task {
            let success = await biometricService.authenticate(
                reason: "Unlock Home Inventory"
            )
            
            await MainActor.run {
                isUnlocking = false
                
                if success {
                    // Add a small delay for animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onAuthenticated()
                    }
                } else if biometricService.error != nil && biometricService.error != .userCancelled {
                    showingError = true
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        isUnlocking = true
        
        Task {
            let success = await biometricService.authenticateWithPasscode(
                reason: "Unlock Home Inventory"
            )
            
            await MainActor.run {
                isUnlocking = false
                
                if success {
                    onAuthenticated()
                } else if biometricService.error != nil && biometricService.error != .userCancelled {
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Lock Screen Modifier

public struct BiometricLockModifier: ViewModifier {
    @AppStorage("biometric_enabled") private var biometricEnabled = false
    @AppStorage("biometric_app_lock") private var appLockEnabled = false
    @State private var isLocked = false
    @State private var lastBackgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase
    
    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLocked)
                .blur(radius: isLocked ? 20 : 0)
            
            if isLocked {
                BiometricLockView(
                    onAuthenticated: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLocked = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            checkInitialLockState()
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard biometricEnabled && appLockEnabled else { return }
        
        switch phase {
        case .background:
            lastBackgroundTime = Date()
        case .active:
            checkLockRequired()
        case .inactive:
            break
        @unknown default:
            break
        }
    }
    
    private func checkInitialLockState() {
        guard biometricEnabled && appLockEnabled else { return }
        
        // Check if we should lock on initial launch
        if !BiometricAuthService.shared.isAuthenticated {
            isLocked = true
        }
    }
    
    private func checkLockRequired() {
        guard biometricEnabled && appLockEnabled else { return }
        
        let timeout = UserDefaults.standard.integer(forKey: "auto_lock_timeout")
        
        // Never lock
        if timeout == -1 { return }
        
        // Immediate lock
        if timeout == 0 {
            isLocked = true
            return
        }
        
        // Time-based lock
        if let lastTime = lastBackgroundTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed >= Double(timeout) {
                isLocked = true
            }
        }
    }
}

public extension View {
    /// Apply biometric lock protection to a view
    func biometricLock() -> some View {
        modifier(BiometricLockModifier())
    }
}

// MARK: - Preview

struct BiometricLockView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricLockView(
            onAuthenticated: {
                print("Authenticated!")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
}