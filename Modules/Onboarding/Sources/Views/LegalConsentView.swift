//
//  LegalConsentView.swift
//  Onboarding Module
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
//  Module: Onboarding
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/Onboarding/Tests/OnboardingTests.swift
//
//  Description: Combined legal consent view for Privacy Policy and Terms of Service.
//               Requires explicit agreement to both documents with checkboxes and
//               provides access to full text of both agreements.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Combined legal consent view for Privacy Policy and Terms of Service
/// Swift 5.9 - No Swift 6 features
public struct LegalConsentView: View {
    @Binding var hasAcceptedLegal: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var agreedToPrivacy = false
    @State private var agreedToTerms = false
    
    private var canProceed: Bool {
        agreedToPrivacy && agreedToTerms
    }
    
    public init(
        hasAcceptedLegal: Binding<Bool>,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void
    ) {
        self._hasAcceptedLegal = hasAcceptedLegal
        self.onAccept = onAccept
        self.onDecline = onDecline
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, AppSpacing.xl)
                
                Text("Legal Agreements")
                    .textStyle(.displayLarge)
                    .multilineTextAlignment(.center)
                
                Text("Please review and accept our legal agreements to continue")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, AppSpacing.lg)
            
            // Agreements
            VStack(spacing: AppSpacing.md) {
                // Privacy Policy
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Privacy Policy")
                                .textStyle(.headlineMedium)
                            Text("How we protect your personal information")
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showPrivacyPolicy = true }) {
                            Text("Read")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: agreedToPrivacy ? "checkmark.square.fill" : "square")
                            .foregroundStyle(agreedToPrivacy ? AppColors.success : AppColors.textSecondary)
                            .font(.title2)
                            .onTapGesture {
                                agreedToPrivacy.toggle()
                            }
                        
                        Text("I have read and agree to the Privacy Policy")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        agreedToPrivacy.toggle()
                    }
                }
                
                // Terms of Service
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Terms of Service")
                                .textStyle(.headlineMedium)
                            Text("Rules and conditions for using the app")
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showTermsOfService = true }) {
                            Text("Read")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundStyle(agreedToTerms ? AppColors.success : AppColors.textSecondary)
                            .font(.title2)
                            .onTapGesture {
                                agreedToTerms.toggle()
                            }
                        
                        Text("I have read and agree to the Terms of Service")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        agreedToTerms.toggle()
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Key Points
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Important Points", systemImage: "info.circle.fill")
                    .textStyle(.headlineSmall)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    bulletPoint("Your data stays on your device")
                    bulletPoint("We don't track or sell your information")
                    bulletPoint("You can export or delete data anytime")
                    bulletPoint("Must be 13 or older to use the app")
                }
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
            }
            .padding()
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: AppSpacing.md) {
                Button(action: {
                    if canProceed {
                        PrivacyPolicyVersion.acceptCurrentVersion()
                        TermsOfServiceVersion.acceptCurrentVersion()
                        hasAcceptedLegal = true
                        onAccept()
                    }
                }) {
                    Text("I Agree to Both")
                        .textStyle(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(canProceed ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed ? AppColors.primary : AppColors.surface)
                        .cornerRadius(AppCornerRadius.medium)
                }
                .disabled(!canProceed)
                
                Button(action: onDecline) {
                    Text("Decline")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding()
            .background(AppColors.surface)
        }
        .background(AppColors.background)
        .sheet(isPresented: $showPrivacyPolicy) {
            FullPrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            FullTermsOfServiceView()
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text("•")
                .foregroundStyle(AppColors.primary)
            Text(text)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

/// Full Terms of Service view wrapper
struct FullTermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text(termsOfServiceText)
                        .textStyle(.bodyMedium)
                        .padding()
                }
            }
            .background(AppColors.background)
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var termsOfServiceText: String {
        """
        Terms of Service for ModularHomeInventory
        
        Effective Date: June 24, 2025
        
        1. Agreement to Terms
        By using ModularHomeInventory, you agree to these Terms. If you disagree, don't use the app.
        
        2. Use License
        We grant you a personal, non-commercial license to use the app. Don't copy, modify, or reverse engineer it.
        
        3. Your Content
        You own your data. We need permission to store and display it in the app. We can't access it.
        
        4. Your Responsibilities
        • Keep your device secure
        • Use the app legally
        • Don't store illegal items
        • Back up your data
        
        5. Privacy
        See our Privacy Policy for data handling details.
        
        6. No Warranties
        The app is provided "as is" without any warranties. Use at your own risk.
        
        7. Limited Liability
        We're not responsible for data loss or damages beyond what you paid for the app.
        
        8. Updates
        We may update the app and these terms. Continued use means acceptance.
        
        9. Termination
        You can stop using the app anytime. We can terminate for violations.
        
        10. Legal
        California law applies. Disputes through arbitration.
        
        Contact: legal@modularhomeinventory.com
        """
    }
}

#Preview {
    LegalConsentView(
        hasAcceptedLegal: .constant(false),
        onAccept: {},
        onDecline: {}
    )
}