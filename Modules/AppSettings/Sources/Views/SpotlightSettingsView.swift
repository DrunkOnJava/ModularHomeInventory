import SwiftUI
import Core
import SharedUI

/// Settings view for configuring Spotlight search integration
/// Swift 5.9 - No Swift 6 features
struct SpotlightSettingsView: View {
    @StateObject private var spotlightManager = SpotlightIntegrationManager.shared
    @State private var showingReindexConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var isReindexing = false
    
    var body: some View {
        List {
            // Status Section
            statusSection
            
            // Settings Section
            settingsSection
            
            // Actions Section
            actionsSection
            
            // Info Section
            infoSection
        }
        .navigationTitle("Spotlight Search")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reindex All Items?", isPresented: $showingReindexConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reindex") {
                Task {
                    await reindexItems()
                }
            }
        } message: {
            Text("This will rebuild the entire search index. It may take a few moments.")
        }
        .alert("Clear Search Index?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await clearIndex()
                }
            }
        } message: {
            Text("This will remove all items from Spotlight search. You can re-enable indexing later.")
        }
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        Section {
            // Indexing status
            HStack {
                Label("Status", systemImage: "magnifyingglass")
                Spacer()
                if spotlightManager.isIndexing {
                    HStack(spacing: AppSpacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Indexing...")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } else if spotlightManager.isIndexingEnabled {
                    Text("Active")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.success)
                } else {
                    Text("Disabled")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            // Indexed items count
            if spotlightManager.isIndexingEnabled {
                HStack {
                    Label("Indexed Items", systemImage: "doc.text.magnifyingglass")
                    Spacer()
                    Text("\(spotlightManager.indexedItemCount)")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Last index date
                if let lastDate = spotlightManager.lastIndexDate {
                    HStack {
                        Label("Last Updated", systemImage: "clock")
                        Spacer()
                        Text(lastDate, style: .relative)
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        } header: {
            Text("Status")
        }
    }
    
    private var settingsSection: some View {
        Section {
            // Enable/Disable indexing
            Toggle(isOn: $spotlightManager.isIndexingEnabled) {
                Label("Enable Spotlight Search", systemImage: "magnifyingglass")
            }
            .disabled(spotlightManager.isIndexing)
        } header: {
            Text("Settings")
        } footer: {
            Text("When enabled, your items will appear in iOS Spotlight search results")
                .textStyle(.labelSmall)
        }
    }
    
    private var actionsSection: some View {
        Section {
            // Reindex button
            Button(action: {
                showingReindexConfirmation = true
            }) {
                HStack {
                    Label("Reindex All Items", systemImage: "arrow.clockwise")
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    if isReindexing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(!spotlightManager.isIndexingEnabled || spotlightManager.isIndexing || isReindexing)
            
            // Clear index button
            Button(role: .destructive, action: {
                showingClearConfirmation = true
            }) {
                Label("Clear Search Index", systemImage: "trash")
            }
            .disabled(!spotlightManager.isIndexingEnabled || spotlightManager.isIndexing)
        } header: {
            Text("Actions")
        }
    }
    
    private var infoSection: some View {
        Section {
            // How it works
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("How It Works", systemImage: "questionmark.circle")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("• Search for items directly from the iOS home screen")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Find items by name, brand, model, location, or tags")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Tap search results to open items in the app")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Updates automatically when items change")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
            
            // Privacy note
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Privacy", systemImage: "lock.shield")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Your item data remains private and is only searchable on this device")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
        } header: {
            Text("Information")
        }
    }
    
    // MARK: - Actions
    
    private func reindexItems() async {
        isReindexing = true
        await spotlightManager.reindexAll()
        isReindexing = false
    }
    
    private func clearIndex() async {
        await spotlightManager.clearIndex()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SpotlightSettingsView()
    }
}