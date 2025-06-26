//
//  OnboardingView.swift
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
//  Module: Onboarding
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/Onboarding/Tests/OnboardingTests/OnboardingViewTests.swift
//
//  Description: Main onboarding view with page control for first-time user experience
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI

/// Main onboarding view with page control
/// Swift 5.9 - No Swift 6 features
struct OnboardingView: View {
    let steps: [OnboardingStep]
    let completion: () -> Void
    
    @State private var currentStep = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completion()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .appPadding()
                }
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        OnboardingStepView(
                            step: steps[index],
                            isLastStep: index == steps.count - 1,
                            onNext: {
                                if index < steps.count - 1 {
                                    withAnimation {
                                        currentStep = index + 1
                                    }
                                } else {
                                    completion()
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicator
                PageIndicator(
                    numberOfPages: steps.count,
                    currentPage: currentStep
                )
                .appPadding(.bottom)
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for onboarding
    }
    
    private var backgroundColors: [Color] {
        switch currentStep {
        case 0: return [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]
        case 1: return [Color.purple.opacity(0.6), Color.pink.opacity(0.6)]
        case 2: return [Color.pink.opacity(0.6), Color.orange.opacity(0.6)]
        case 3: return [Color.orange.opacity(0.6), Color.yellow.opacity(0.6)]
        case 4: return [Color.green.opacity(0.6), Color.blue.opacity(0.6)]
        default: return [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]
        }
    }
}

// MARK: - Step View

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLastStep: Bool
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()
            
            // Icon
            Image(systemName: step.imageName)
                .font(.system(size: 100))
                .foregroundColor(.white)
                .shadow(radius: 10)
            
            // Content
            VStack(spacing: AppSpacing.lg) {
                Text(step.title)
                    .textStyle(.displaySmall)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .textStyle(.bodyLarge)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appPadding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            // Action button
            Button(action: onNext) {
                HStack {
                    Text(step.buttonTitle)
                        .fontWeight(.semibold)
                    
                    if !isLastStep {
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(AppCornerRadius.large)
            }
            .appPadding(.horizontal, AppSpacing.xl)
            .appPadding(.bottom, AppSpacing.xl)
        }
    }
}

// MARK: - Page Indicator

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}