//
//  TermsOfServiceView.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/AppSettings/Tests/Views/TermsOfServiceViewTests.swift
//
//  Description: Terms of service display view providing legal content with scrollable interface and proper navigation controls
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  TermsOfServiceView.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/TermsOfServiceViewTests.swift
//
//  Description: Complete terms of service document with expandable sections covering license agreement,
//  user responsibilities, ownership, disclaimers, liability limitations, and legal dispute resolution
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI

/// Terms of Service view for the Settings module
/// Swift 5.9 - No Swift 6 features
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: TermsSection? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Terms of Service")
                            .textStyle(.displayLarge)
                        
                        HStack {
                            Text("Effective: June 24, 2025")
                                .textStyle(.labelLarge)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text("v1.0")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.surface)
                                .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    .padding(.bottom, AppSpacing.md)
                    
                    // Quick Summary Card
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Key Points", systemImage: "doc.text.fill")
                            .textStyle(.headlineMedium)
                            .foregroundStyle(AppColors.primary)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            bulletPoint("Personal use license only")
                            bulletPoint("You own your data")
                            bulletPoint("No warranties provided")
                            bulletPoint("Limited liability")
                            bulletPoint("Must be 13+ to use")
                        }
                        .textStyle(.bodyMedium)
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Main Sections
                    Group {
                        termsSection(
                            section: .agreement,
                            title: "1. Agreement to Terms",
                            icon: "handshake",
                            content: """
                            By downloading, installing, or using ModularHomeInventory ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you disagree with any part of these terms, then you may not use the App.
                            """
                        )
                        
                        termsSection(
                            section: .license,
                            title: "2. Use License",
                            icon: "key.fill",
                            content: """
                            **Grant of License**
                            We grant you a revocable, non-exclusive, non-transferable, limited license to use the App for personal, non-commercial purposes.
                            
                            **You agree NOT to:**
                            • Copy, modify, or create derivative works
                            • Reverse engineer or decompile the App
                            • Remove proprietary notices
                            • Use for illegal purposes
                            • Violate any laws
                            • Infringe on others' rights
                            • Interfere with App functionality
                            """
                        )
                        
                        termsSection(
                            section: .ownership,
                            title: "3. Ownership & Your Content",
                            icon: "lock.doc.fill",
                            content: """
                            **App Ownership**
                            The App and its features are our exclusive property, protected by intellectual property laws.
                            
                            **Your Content**
                            • You retain all rights to your content
                            • You grant us limited license to store and display it
                            • We can't access your data
                            • You can delete it anytime
                            
                            **Feedback**
                            Any suggestions you provide become our property.
                            """
                        )
                        
                        termsSection(
                            section: .responsibilities,
                            title: "4. Your Responsibilities",
                            icon: "person.fill.checkmark",
                            content: """
                            **You are responsible for:**
                            • Device security
                            • Protecting App access
                            • iCloud account security
                            • Providing accurate information
                            • Using the App lawfully
                            • Backing up your data
                            
                            **You agree NOT to store:**
                            • Illegal items
                            • Items you don't own
                            • Content violating others' rights
                            • Inappropriate material
                            """
                        )
                    }
                    
                    Group {
                        termsSection(
                            section: .privacy,
                            title: "5. Privacy & Data",
                            icon: "hand.raised.fill",
                            content: """
                            Your use is governed by our Privacy Policy.
                            
                            **Data Storage:**
                            • Stored locally on device
                            • Optional iCloud sync
                            • We have no access
                            • You control deletion
                            
                            **Not responsible for data loss due to:**
                            • Device failure
                            • User error
                            • iOS updates
                            • iCloud issues
                            """
                        )
                        
                        termsSection(
                            section: .updates,
                            title: "6. Updates & Changes",
                            icon: "arrow.triangle.2.circlepath",
                            content: """
                            **App Updates**
                            We may update for new features, fixes, or iOS compatibility.
                            
                            **No Guarantee of:**
                            • Future iOS compatibility
                            • All device support
                            • Jailbroken device support
                            
                            **Terms Updates**
                            We may modify Terms and will notify you of changes.
                            """
                        )
                        
                        termsSection(
                            section: .disclaimers,
                            title: "7. Disclaimers & Warranties",
                            icon: "exclamationmark.triangle.fill",
                            content: """
                            **"AS IS" BASIS**
                            THE APP IS PROVIDED WITHOUT WARRANTIES OF ANY KIND.
                            
                            **We do NOT warrant:**
                            • Uninterrupted operation
                            • Error-free functionality
                            • Meeting your requirements
                            • Freedom from viruses
                            
                            **Use at Your Own Risk**
                            You're responsible for any damage or data loss.
                            """
                        )
                        
                        termsSection(
                            section: .liability,
                            title: "8. Limitation of Liability",
                            icon: "shield.slash.fill",
                            content: """
                            **NOT LIABLE FOR:**
                            • Indirect or consequential damages
                            • Loss of profits or data
                            • Business interruption
                            • Substitute services
                            
                            **Maximum Liability**
                            Limited to amount paid for App in past 12 months.
                            
                            Some jurisdictions don't allow these limitations.
                            """
                        )
                    }
                    
                    Group {
                        termsSection(
                            section: .termination,
                            title: "9. Termination",
                            icon: "xmark.circle.fill",
                            content: """
                            **By You**
                            Delete the App from your device anytime.
                            
                            **By Us**
                            We may terminate access for:
                            • Terms violation
                            • Illegal use
                            • Law enforcement request
                            • Extended inactivity
                            
                            **Effect**
                            License ends; delete App from all devices.
                            """
                        )
                        
                        termsSection(
                            section: .legal,
                            title: "10. Legal & Disputes",
                            icon: "scalemass.fill",
                            content: """
                            **Governing Law**
                            US and California law applies.
                            
                            **Dispute Resolution:**
                            1. Good faith negotiation
                            2. Mediation
                            3. Binding arbitration
                            
                            **Class Action Waiver**
                            Individual disputes only.
                            """
                        )
                        
                        termsSection(
                            section: .contact,
                            title: "11. Contact Information",
                            icon: "envelope.fill",
                            content: """
                            For Terms questions:
                            
                            **Email**: legal@modularhomeinventory.com
                            **Response**: 2-3 business days
                            """
                        )
                    }
                    
                    // Agreement Statement
                    Text("By using ModularHomeInventory, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.top, AppSpacing.xl)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { shareTermsOfService() }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { printTermsOfService() }) {
                            Label("Print", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func termsSection(section: TermsSection, title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                    .font(.title3)
                
                Text(title)
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.primary)
                
                Spacer()
                
                Image(systemName: selectedSection == section ? "chevron.up" : "chevron.down")
                    .foregroundStyle(AppColors.textSecondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSection = selectedSection == section ? nil : section
                }
            }
            
            if selectedSection == nil || selectedSection == section {
                Text(.init(content)) // Using .init() to parse markdown
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppSpacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text("•")
                .foregroundStyle(AppColors.primary)
            Text(text)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
    
    private func shareTermsOfService() {
        let termsURL = URL(string: "https://modularhomeinventory.com/terms")!
        let activityVC = UIActivityViewController(activityItems: [termsURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func printTermsOfService() {
        // Implementation for printing would go here
        print("Print terms of service")
    }
}

enum TermsSection: CaseIterable {
    case agreement
    case license
    case ownership
    case responsibilities
    case privacy
    case updates
    case disclaimers
    case liability
    case termination
    case legal
    case contact
}

#Preview {
    TermsOfServiceView()
}