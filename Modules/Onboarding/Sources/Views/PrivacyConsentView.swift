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