//
//  PrivacyConsentView.swift
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
//  Description: Privacy consent view for onboarding flow. Displays privacy policy
//               key points, allows users to read full policy, and manages consent
//               acceptance with version tracking.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Privacy consent view shown during onboarding
/// Swift 5.9 - No Swift 6 features
public struct PrivacyConsentView: View {
    @Binding var hasAcceptedPrivacy: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var showFullPolicy = false
    
    public init(
        hasAcceptedPrivacy: Binding<Bool>,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void
    ) {
        self._hasAcceptedPrivacy = hasAcceptedPrivacy
        self.onAccept = onAccept
        self.onDecline = onDecline
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, AppSpacing.xl)
                
                Text("Your Privacy Matters")
                    .textStyle(.displayLarge)
                    .multilineTextAlignment(.center)
                
                Text("We respect your privacy and put you in control")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, AppSpacing.lg)
            
            // Key Points
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                privacyPoint(
                    icon: "iphone",
                    title: "Data Stays Local",
                    description: "All your inventory data is stored on your device"
                )
                
                privacyPoint(
                    icon: "icloud",
                    title: "Your iCloud, Your Control",
                    description: "Optional sync uses your personal iCloud account"
                )
                
                privacyPoint(
                    icon: "xmark.shield",
                    title: "No Tracking or Ads",
                    description: "We don't track you or show advertisements"
                )
                
                privacyPoint(
                    icon: "square.and.arrow.up",
                    title: "Export Anytime",
                    description: "Your data belongs to you - export or delete it anytime"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Actions
            VStack(spacing: AppSpacing.md) {
                Button(action: {
                    PrivacyPolicyVersion.acceptCurrentVersion()
                    hasAcceptedPrivacy = true
                    onAccept()
                }) {
                    Text("I Agree")
                        .textStyle(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(AppCornerRadius.medium)
                }
                
                HStack(spacing: AppSpacing.lg) {
                    Button(action: { showFullPolicy = true }) {
                        Text("Read Full Policy")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.primary)
                    }
                    
                    Button(action: onDecline) {
                        Text("Decline")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppColors.surface)
        }
        .background(AppColors.background)
        .sheet(isPresented: $showFullPolicy) {
            FullPrivacyPolicyView()
        }
    }
    
    private func privacyPoint(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .textStyle(.bodyLarge)
                    .fontWeight(.medium)
                
                Text(description)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

/// Full privacy policy view wrapper
struct FullPrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text(privacyPolicyText)
                        .textStyle(.bodyMedium)
                        .padding()
                }
            }
            .background(AppColors.background)
            .navigationTitle("Privacy Policy")
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
    
    private var privacyPolicyText: String {
        """
        Privacy Policy for ModularHomeInventory
        
        Effective Date: June 24, 2025
        
        Your privacy is critically important to us. This policy explains how we handle your information.
        
        Information We Collect
        
        We collect information you provide directly:
        • Item details, photos, and receipts
        • Purchase information and warranties
        • Location names within your home
        • Custom tags and categories
        
        How We Use Information
        
        Your information is used solely to provide app functionality:
        • Manage your inventory
        • Track values and warranties
        • Generate reports
        • Sync across your devices
        
        Data Storage
        
        • All data is stored locally on your device
        • iCloud sync uses your personal account
        • We have no access to your data
        • Data is encrypted by iOS
        
        Your Rights
        
        You have complete control:
        • Export data anytime
        • Delete any or all data
        • Disable features
        • Control all permissions
        
        Contact Us
        
        For privacy questions:
        privacy@modularhomeinventory.com
        """
    }
}

#Preview {
    PrivacyConsentView(
        hasAcceptedPrivacy: .constant(false),
        onAccept: {},
        onDecline: {}
    )
}