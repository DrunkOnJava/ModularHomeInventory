import SwiftUI
import Core

/// Public API for the Onboarding module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol OnboardingModuleAPI {
    /// Check if onboarding has been completed
    var isOnboardingCompleted: Bool { get }
    
    /// Creates the onboarding flow view
    func makeOnboardingView(completion: @escaping () -> Void) -> AnyView
    
    /// Mark onboarding as completed
    func completeOnboarding()
    
    /// Reset onboarding (useful for testing or user request)
    func resetOnboarding()
}

/// Dependencies required by the Onboarding module
public struct OnboardingModuleDependencies {
    public let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

/// Onboarding step information
public struct OnboardingStep {
    public let title: String
    public let description: String
    public let imageName: String
    public let buttonTitle: String
    
    public init(
        title: String,
        description: String,
        imageName: String,
        buttonTitle: String = "Next"
    ) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Default Onboarding Steps

public extension OnboardingStep {
    static let welcome = OnboardingStep(
        title: "Welcome to Home Inventory",
        description: "Keep track of all your belongings in one place. Organize, manage, and protect what matters most.",
        imageName: "shippingbox.fill"
    )
    
    static let organize = OnboardingStep(
        title: "Organize Everything",
        description: "Create categories, add locations, and keep your items perfectly organized with custom tags and notes.",
        imageName: "square.grid.3x3.fill"
    )
    
    static let scan = OnboardingStep(
        title: "Quick Barcode Scanning",
        description: "Add items instantly by scanning barcodes. Get product details automatically filled in.",
        imageName: "barcode.viewfinder"
    )
    
    static let receipts = OnboardingStep(
        title: "Smart Receipt Management",
        description: "Import receipts from emails or scan them. Track warranties and purchase history effortlessly.",
        imageName: "doc.text.viewfinder"
    )
    
    static let protect = OnboardingStep(
        title: "Protect Your Data",
        description: "Secure cloud backup ensures your inventory is safe. Access from any device, anytime.",
        imageName: "lock.icloud.fill",
        buttonTitle: "Get Started"
    )
    
    static let allSteps: [OnboardingStep] = [
        .welcome,
        .organize,
        .scan,
        .receipts,
        .protect
    ]
}