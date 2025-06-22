import SwiftUI
import SharedUI

/// Main settings view with various configuration options
/// Swift 5.9 - No Swift 6 features
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingExportData = false
    @State private var showingClearCache = false
    @State private var showingRateApp = false
    @State private var showingShareApp = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            List {
                // General Section
                generalSection
                
                // Privacy & Security Section
                privacySection
                
                // Data & Storage Section
                dataSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingExportData) {
                ExportDataView()
            }
            .sheet(isPresented: $showingClearCache) {
                ClearCacheView()
            }
            .sheet(isPresented: $showingRateApp) {
                RateAppView()
            }
            .sheet(isPresented: $showingShareApp) {
                ShareAppView()
            }
        }
    }
    
    // MARK: - Sections
    
    private var generalSection: some View {
        Section {
            // Notifications
            Toggle(isOn: $viewModel.settings.notificationsEnabled) {
                Label("Notifications", systemImage: "bell")
            }
            
            // Dark Mode
            Toggle(isOn: $viewModel.settings.darkModeEnabled) {
                Label("Dark Mode", systemImage: "moon")
            }
            
            // Currency
            HStack {
                Label("Currency", systemImage: "dollarsign.circle")
                Spacer()
                Picker("Currency", selection: $viewModel.settings.defaultCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("JPY").tag("JPY")
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("General")
        }
    }
    
    private var privacySection: some View {
        Section {
            // Biometric Auth
            Toggle(isOn: $viewModel.settings.biometricAuthEnabled) {
                Label("Face ID / Touch ID", systemImage: "faceid")
            }
            
            // Privacy Policy
            Button(action: {
                showingPrivacyPolicy = true
            }) {
                Label("Privacy Policy", systemImage: "hand.raised")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Terms of Service
            Button(action: {
                showingTermsOfService = true
            }) {
                Label("Terms of Service", systemImage: "doc.text")
                    .foregroundColor(AppColors.textPrimary)
            }
        } header: {
            Text("Privacy & Security")
        }
    }
    
    private var dataSection: some View {
        Section {
            // Auto Backup
            Toggle(isOn: $viewModel.settings.autoBackupEnabled) {
                Label("Auto Backup", systemImage: "icloud")
            }
            
            // Export Data
            Button(action: {
                showingExportData = true
            }) {
                Label("Export Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Clear Cache
            Button(action: {
                showingClearCache = true
            }) {
                Label("Clear Cache", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Data & Storage")
        } footer: {
            Text("Auto backup saves your data to iCloud daily")
                .textStyle(.labelSmall)
        }
    }
    
    private var aboutSection: some View {
        Section {
            // About
            Button(action: {
                showingAbout = true
            }) {
                HStack {
                    Label("About", systemImage: "info.circle")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("Version 1.0.0")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Rate App
            Button(action: {
                showingRateApp = true
            }) {
                Label("Rate Home Inventory", systemImage: "star")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Share App
            Button(action: {
                showingShareApp = true
            }) {
                Label("Share App", systemImage: "square.and.arrow.up")
                    .foregroundColor(AppColors.textPrimary)
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // App Icon
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.primary)
                    .appPadding()
                
                // App Name and Version
                VStack(spacing: AppSpacing.sm) {
                    Text("Home Inventory")
                        .textStyle(.displayMedium)
                    
                    Text("Version 1.0.0")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Description
                Text("Keep track of your belongings with ease")
                    .textStyle(.bodyLarge)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                
                // Credits
                VStack(spacing: AppSpacing.xs) {
                    Text("Made with ❤️ using Swift")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("© 2024 Home Inventory")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .appPadding()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("About")
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
}