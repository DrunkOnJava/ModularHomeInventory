//
//  SignInView.swift
//  Gmail Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Gmail
//  Dependencies: SwiftUI, GoogleSignIn, GoogleSignInSwift
//  Testing: GmailTests/SignInViewTests.swift
//
//  Description: Google Sign-In view with privacy information and authentication flow
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

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