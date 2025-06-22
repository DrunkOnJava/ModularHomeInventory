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