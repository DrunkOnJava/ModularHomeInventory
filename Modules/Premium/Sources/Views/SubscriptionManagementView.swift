import SwiftUI
import SharedUI

/// Subscription management view
/// Swift 5.9 - No Swift 6 features
struct SubscriptionManagementView: View {
    @ObservedObject var module: PremiumModule
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Current status
                statusSection
                
                // Features
                featuresSection
                
                // Actions
                actionsSection
            }
            .navigationTitle("Subscription")
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
    
    private var statusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Status")
                        .textStyle(.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Image(systemName: module.isPremium ? "crown.fill" : "crown")
                            .foregroundColor(module.isPremium ? Color.yellow : AppColors.textTertiary)
                        
                        Text(module.isPremium ? "Premium" : "Free")
                            .textStyle(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                if module.isPremium {
                    VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                        Text("Active")
                            .textStyle(.labelMedium)
                            .foregroundColor(AppColors.success)
                        
                        Text("Renews monthly")
                            .textStyle(.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .appPadding(.vertical, AppSpacing.sm)
        }
    }
    
    private var featuresSection: some View {
        Section("Your Features") {
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack {
                    Image(systemName: feature.iconName)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text(feature.displayName)
                        .textStyle(.bodyMedium)
                    
                    Spacer()
                    
                    if !module.requiresPremium(feature) || module.isPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                    } else {
                        Text("Premium")
                            .textStyle(.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section {
            if !module.isPremium {
                Button(action: {
                    // Show upgrade view
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color.yellow)
                        Text("Upgrade to Premium")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            
            Button(action: {
                // Restore purchases
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restore Purchases")
                }
            }
            
            if module.isPremium {
                Button(role: .destructive, action: {
                    // Cancel subscription
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel Subscription")
                    }
                }
            }
        }
    }
}