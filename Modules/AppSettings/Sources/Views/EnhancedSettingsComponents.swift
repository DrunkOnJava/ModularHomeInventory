import SwiftUI
import SharedUI
import Core

// MARK: - Profile Header View

struct SettingsProfileHeaderView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var profileImage: UIImage?
    let onProfileEdit: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Text(userName.prefix(2).uppercased())
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Edit button
                Button(action: onProfileEdit) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
                .offset(x: 35, y: 35)
            }
            
            // User Info
            VStack(spacing: AppSpacing.xs) {
                Text(userName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                if !userEmail.isEmpty {
                    Text(userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Premium Status
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                Text("Premium Member")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding(.top, AppSpacing.lg)
    }
}

// MARK: - Quick Stats View

struct SettingsQuickStatsView: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            QuickStatCard(
                icon: "shippingbox.fill",
                value: "247",
                label: "Items",
                color: AppColors.primary
            )
            
            QuickStatCard(
                icon: "folder.fill",
                value: "12",
                label: "Collections",
                color: .purple
            )
            
            QuickStatCard(
                icon: "doc.fill",
                value: "89",
                label: "Receipts",
                color: .green
            )
            
            QuickStatCard(
                icon: "icloud.fill",
                value: "2.3 GB",
                label: "Storage",
                color: .blue
            )
        }
    }
}

// MARK: - Search Bar View

struct SettingsSearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Search settings", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Footer View

struct SettingsFooterView: View {
    let onSupport: () -> Void
    let onPrivacy: () -> Void
    let onTerms: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // App Info
            VStack(spacing: AppSpacing.xs) {
                Text("Home Inventory")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Version 1.0.0 (Build 2)")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Links
            HStack(spacing: AppSpacing.xl) {
                Button(action: onSupport) {
                    Text("Support")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: onPrivacy) {
                    Text("Privacy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: onTerms) {
                    Text("Terms")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
            }
            
            // Copyright
            Text("© 2024 Home Inventory. All rights reserved.")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}