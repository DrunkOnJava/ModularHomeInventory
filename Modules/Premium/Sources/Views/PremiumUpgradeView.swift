//
//  PremiumUpgradeView.swift
//  HomeInventoryModular
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
//  Module: Premium
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/Premium/Tests/PremiumTests/PremiumUpgradeViewTests.swift
//
//  Description: Premium upgrade view showcasing paid features and subscription management
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI

/// Premium upgrade view
/// Swift 5.9 - No Swift 6 features
struct PremiumUpgradeView: View {
    @ObservedObject var module: PremiumModule
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Pricing
                    pricingSection
                    
                    // Action buttons
                    actionButtons
                }
                .appPadding()
            }
            .background(AppColors.background)
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Go Premium")
                .textStyle(.displayMedium)
            
            Text("Unlock all features and remove limits")
                .textStyle(.bodyLarge)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .appPadding(.vertical)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Premium Features")
                .textStyle(.headlineMedium)
            
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: feature.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(feature.displayName)
                            .textStyle(.bodyLarge)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(feature.description)
                            .textStyle(.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Choose Your Plan")
                .textStyle(.headlineMedium)
            
            // Monthly plan
            PricingCard(
                title: "Monthly",
                price: "$4.99",
                period: "/month",
                isPopular: false
            )
            
            // Yearly plan
            PricingCard(
                title: "Yearly",
                price: "$39.99",
                period: "/year",
                isPopular: true,
                savings: "Save 33%"
            )
        }
        .appPadding(.vertical)
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(
                title: "Start Free Trial",
                isLoading: isLoading,
                action: purchasePremium
            )
            
            Button("Restore Purchases") {
                restorePurchases()
            }
            .foregroundColor(AppColors.primary)
            
            Text("Cancel anytime. No commitment.")
                .textStyle(.labelSmall)
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    private func purchasePremium() {
        isLoading = true
        Task {
            do {
                try await module.purchasePremium()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        Task {
            do {
                try await module.restorePurchases()
                if module.isPremium {
                    dismiss()
                } else {
                    errorMessage = "No previous purchases found"
                    showError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    let savings: String?
    
    init(
        title: String,
        price: String,
        period: String,
        isPopular: Bool,
        savings: String? = nil
    ) {
        self.title = title
        self.price = price
        self.period = period
        self.isPopular = isPopular
        self.savings = savings
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            if isPopular {
                Text("MOST POPULAR")
                    .textStyle(.labelSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primary)
                    .cornerRadius(AppCornerRadius.small)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                Text(price)
                    .textStyle(.displaySmall)
                    .fontWeight(.bold)
                
                Text(period)
                    .textStyle(.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(title)
                .textStyle(.bodyLarge)
            
            if let savings = savings {
                Text(savings)
                    .textStyle(.labelMedium)
                    .foregroundColor(AppColors.success)
            }
        }
        .frame(maxWidth: .infinity)
        .appPadding()
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(isPopular ? AppColors.primary : Color.clear, lineWidth: 2)
                )
        )
    }
}