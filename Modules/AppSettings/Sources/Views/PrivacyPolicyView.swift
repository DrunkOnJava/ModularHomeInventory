import SwiftUI
import SharedUI

/// Privacy Policy view for the Settings module
/// Swift 5.9 - No Swift 6 features
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: PrivacySection? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Privacy Policy")
                            .textStyle(.title1)
                        
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
                        Label("Your Privacy at a Glance", systemImage: "lock.shield.fill")
                            .textStyle(.headline)
                            .foregroundStyle(AppColors.success)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            bulletPoint("All data stored locally on your device")
                            bulletPoint("Optional iCloud sync through your account")
                            bulletPoint("No data sent to our servers")
                            bulletPoint("No ads or tracking")
                            bulletPoint("You can delete everything anytime")
                        }
                        .textStyle(.body)
                    }
                    .padding()
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Main Sections
                    Group {
                        privacySection(
                            section: .dataCollection,
                            title: "Information We Collect",
                            icon: "doc.text.magnifyingglass",
                            content: """
                            **Information You Provide:**
                            • Item details (names, descriptions, values)
                            • Photos of your belongings
                            • Purchase receipts and warranties
                            • Location names within your home
                            • Custom tags and categories
                            • Notes and serial numbers
                            
                            **Automatically Collected:**
                            • Device type and iOS version
                            • App usage patterns (locally stored)
                            • Crash reports (anonymous, if enabled)
                            • Barcode scan history
                            """
                        )
                        
                        privacySection(
                            section: .dataUsage,
                            title: "How We Use Your Information",
                            icon: "gearshape.2.fill",
                            content: """
                            Your data is used exclusively to provide app functionality:
                            
                            • **Inventory Management**: Organize and track your belongings
                            • **Value Tracking**: Monitor total values and depreciation
                            • **Search & Discovery**: Find items quickly
                            • **Warranty Alerts**: Remind you of expiring warranties
                            • **Backup & Sync**: Keep data safe across devices
                            • **Reports**: Generate insurance and tax documents
                            
                            We DO NOT use your data for advertising, profiling, or any purpose other than providing app features.
                            """
                        )
                        
                        privacySection(
                            section: .dataSecurity,
                            title: "Data Storage & Security",
                            icon: "lock.circle.fill",
                            content: """
                            **Local Storage:**
                            • Stored in app's sandboxed environment
                            • Protected by iOS device encryption
                            • Biometric authentication available
                            
                            **iCloud Sync (Optional):**
                            • Uses your personal iCloud account
                            • End-to-end encrypted by Apple
                            • We cannot access your iCloud data
                            
                            **Security Measures:**
                            • No data on our servers
                            • Regular security updates
                            • Industry-standard encryption
                            """
                        )
                        
                        privacySection(
                            section: .dataSharing,
                            title: "Data Sharing",
                            icon: "person.2.slash.fill",
                            content: """
                            **We NEVER share your data with:**
                            • Advertisers
                            • Data brokers
                            • Marketing companies
                            • Other apps
                            
                            **Limited Sharing:**
                            • **Legal Requirements**: Only if legally required
                            • **Your Consent**: When you explicitly share
                            • **Anonymous Crash Reports**: To improve stability (opt-in)
                            """
                        )
                    }
                    
                    Group {
                        privacySection(
                            section: .userRights,
                            title: "Your Rights & Controls",
                            icon: "person.crop.circle.badge.checkmark",
                            content: """
                            **You have complete control:**
                            • **Access**: View all stored data
                            • **Export**: Download data as CSV
                            • **Correct**: Edit any information
                            • **Delete**: Remove items or all data
                            • **Port**: Transfer to other apps
                            
                            **Privacy Controls:**
                            • Enable/disable biometric lock
                            • Manage notification preferences
                            • Control camera permissions
                            • Toggle iCloud sync
                            • Clear cache anytime
                            """
                        )
                        
                        privacySection(
                            section: .childrenPrivacy,
                            title: "Children's Privacy",
                            icon: "figure.child.circle",
                            content: """
                            ModularHomeInventory is not intended for children under 13.
                            
                            We do not knowingly collect data from children. If you believe we have inadvertently collected such information, please contact us immediately for deletion.
                            """
                        )
                        
                        privacySection(
                            section: .internationalRights,
                            title: "International Privacy Rights",
                            icon: "globe.europe.africa.fill",
                            content: """
                            **GDPR (European Union):**
                            • Right to access
                            • Right to rectification
                            • Right to erasure
                            • Right to data portability
                            • Right to object
                            
                            **CCPA (California):**
                            • Right to know
                            • Right to delete
                            • Right to opt-out (we don't sell data)
                            • Right to non-discrimination
                            """
                        )
                        
                        privacySection(
                            section: .contact,
                            title: "Contact Us",
                            icon: "envelope.fill",
                            content: """
                            For privacy questions or concerns:
                            
                            **Email**: privacy@modularhomeinventory.com
                            **Response Time**: Within 48 hours
                            
                            You may also submit requests through the app's Settings > Support section.
                            """
                        )
                    }
                    
                    // Compliance badges
                    HStack(spacing: AppSpacing.md) {
                        complianceBadge("GDPR", color: .blue)
                        complianceBadge("CCPA", color: .green)
                        complianceBadge("COPPA", color: .orange)
                        complianceBadge("App Store", color: .gray)
                    }
                    .padding(.top, AppSpacing.xl)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { sharePrivacyPolicy() }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { printPrivacyPolicy() }) {
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
    
    private func privacySection(section: PrivacySection, title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                    .font(.title3)
                
                Text(title)
                    .textStyle(.headline)
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
                    .textStyle(.body)
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
                .foregroundStyle(AppColors.success)
            Text(text)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
    
    private func complianceBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .textStyle(.labelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(AppCornerRadius.small)
    }
    
    private func sharePrivacyPolicy() {
        // Implementation for sharing
        let privacyPolicyURL = URL(string: "https://modularhomeinventory.com/privacy")!
        let activityVC = UIActivityViewController(activityItems: [privacyPolicyURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func printPrivacyPolicy() {
        // Implementation for printing would go here
        // For now, we'll just show a placeholder
        print("Print privacy policy")
    }
}

enum PrivacySection: CaseIterable {
    case dataCollection
    case dataUsage
    case dataSecurity
    case dataSharing
    case userRights
    case childrenPrivacy
    case internationalRights
    case contact
}

#Preview {
    PrivacyPolicyView()
}