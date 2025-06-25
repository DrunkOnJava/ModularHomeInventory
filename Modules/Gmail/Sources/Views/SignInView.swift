// SignInView.swift
// Gmail Sign In View
// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT upgrade to Swift 6

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

public struct SignInView: View {
    @EnvironmentObject var bridge: GmailBridge
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Connect Gmail")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to import receipts and purchase emails")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Sign in button
                VStack(spacing: 16) {
                    GoogleSignInButtonWrapper(isSigningIn: $isSigningIn) {
                        handleSignIn()
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    
                    if isSigningIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Privacy note
                VStack(spacing: 8) {
                    Text("Privacy Note")
                        .font(.headline)
                    
                    Text("Home Inventory only accesses receipt and purchase emails. Your personal emails remain private and are never accessed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleSignIn() {
        isSigningIn = true
        errorMessage = nil
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            isSigningIn = false
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: topController) { [weak bridge] result, error in
            DispatchQueue.main.async {
                isSigningIn = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if result != nil {
                    // Sign in successful
                    bridge?.checkAuthenticationStatus()
                    dismiss()
                }
            }
        }
    }
}

// Google Sign-In Button Wrapper
struct GoogleSignInButtonWrapper: UIViewRepresentable {
    @Binding var isSigningIn: Bool
    let action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
        uiView.isEnabled = !isSigningIn
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}