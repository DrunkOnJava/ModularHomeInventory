import SwiftUI
import Core

/// Main implementation of the Onboarding module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class OnboardingModule: OnboardingModuleAPI {
    private let dependencies: OnboardingModuleDependencies
    private let onboardingKey = "hasCompletedOnboarding"
    
    public var isOnboardingCompleted: Bool {
        dependencies.userDefaults.bool(forKey: onboardingKey)
    }
    
    public init(dependencies: OnboardingModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeOnboardingView(completion: @escaping () -> Void) -> AnyView {
        AnyView(
            OnboardingView(
                steps: OnboardingStep.allSteps,
                completion: { [weak self] in
                    self?.completeOnboarding()
                    completion()
                }
            )
        )
    }
    
    public func completeOnboarding() {
        dependencies.userDefaults.set(true, forKey: onboardingKey)
    }
    
    public func resetOnboarding() {
        dependencies.userDefaults.set(false, forKey: onboardingKey)
    }
}