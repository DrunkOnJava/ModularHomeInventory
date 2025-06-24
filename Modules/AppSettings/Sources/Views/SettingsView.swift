import SwiftUI
import SharedUI
import Core
import Sync

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
    @State private var showingOfflineData = false
    @State private var showingSyncStatus = false
    @State private var showingCategoryManagement = false
    @State private var showingScannerSettings = false
    @State private var showingConflictResolution = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
                // General Section
                generalSection
                
                // Privacy & Security Section
                privacySection
                
                // Data & Storage Section
                dataSection
                
                // Offline & Sync Section
                offlineSection
                
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
            .sheet(isPresented: $showingOfflineData) {
                NavigationView {
                    OfflineDataView()
                        .navigationTitle("Offline Data")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingOfflineData = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingSyncStatus) {
                NavigationView {
                    VStack(spacing: AppSpacing.lg) {
                        SyncStatusView()
                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                    .navigationTitle("Sync Status")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSyncStatus = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCategoryManagement) {
                // Note: We need to pass the categoryRepository here
                // For now, we'll use a placeholder
                Text("Category Management View")
            }
            .sheet(isPresented: $showingScannerSettings) {
                ScannerSettingsView(settings: $viewModel.settings, viewModel: viewModel)
            }
            .sheet(isPresented: $showingConflictResolution) {
                // Note: We'll need to pass the repositories here
                if let itemRepo = viewModel.itemRepository,
                   let receiptRepo = viewModel.receiptRepository,
                   let locationRepo = viewModel.locationRepository {
                    ConflictResolutionView(
                        conflictService: ConflictResolutionService(
                            itemRepository: itemRepo,
                            receiptRepository: receiptRepo,
                            locationRepository: locationRepo
                        ),
                        itemRepository: itemRepo,
                        receiptRepository: receiptRepo,
                        locationRepository: locationRepo
                    )
                }
            }
        }
    
    // MARK: - Sections
    
    private var generalSection: some View {
        Section {
            // Notifications
            NavigationLink(destination: NotificationSettingsView()) {
                Label("Notifications", systemImage: "bell")
            }
            
            // Spotlight Search
            NavigationLink(destination: SpotlightSettingsView()) {
                Label("Spotlight Search", systemImage: "magnifyingglass")
            }
            
            // Accessibility
            NavigationLink(destination: AccessibilitySettingsView(settingsStorage: viewModel.settingsStorage)) {
                Label("Accessibility", systemImage: "accessibility")
            }
            
            // Dark Mode
            Toggle(isOn: Binding(
                get: { ThemeManager.shared.isDarkMode },
                set: { isDark in
                    ThemeManager.shared.useSystemTheme = false
                    ThemeManager.shared.setDarkMode(isDark)
                }
            )) {
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
            
            // Scanner Settings
            Button(action: {
                showingScannerSettings = true
            }) {
                Label("Scanner Settings", systemImage: "barcode.viewfinder")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Category Management
            Button(action: {
                showingCategoryManagement = true
            }) {
                Label("Manage Categories", systemImage: "folder")
                    .foregroundColor(AppColors.textPrimary)
            }
        } header: {
            Text("General")
        }
    }
    
    private var privacySection: some View {
        Section {
            // Biometric Auth
            NavigationLink(destination: BiometricSettingsView()) {
                Label("Face ID / Touch ID", systemImage: BiometricAuthService.shared.biometricType.icon)
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
            
            // Crash Reporting
            NavigationLink(destination: CrashReportingSettingsView(settingsStorage: viewModel.settingsStorage)) {
                Label("Crash Reporting", systemImage: "exclamationmark.triangle")
            }
        } header: {
            Text("Data & Storage")
        } footer: {
            Text("Auto backup saves your data to iCloud daily")
                .textStyle(.labelSmall)
        }
    }
    
    private var offlineSection: some View {
        Section {
            // Offline Mode Toggle
            Toggle(isOn: $viewModel.settings.offlineModeEnabled) {
                Label("Enable Offline Mode", systemImage: "wifi.slash")
            }
            
            // Sync Status
            Button(action: {
                showingSyncStatus = true
            }) {
                HStack {
                    Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    // Simplified sync status
                    Text("Synced")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            // Conflict Resolution
            Button(action: {
                showingConflictResolution = true
            }) {
                HStack {
                    Label("Resolve Conflicts", systemImage: "exclamationmark.icloud")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    if viewModel.hasConflicts {
                        Text("\(viewModel.conflictCount)")
                            .textStyle(.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.error)
                            .cornerRadius(10)
                    }
                }
            }
            
            // Offline Data Management
            Button(action: {
                showingOfflineData = true
            }) {
                Label("Manage Offline Data", systemImage: "internaldrive")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Auto-sync on WiFi
            Toggle(isOn: $viewModel.settings.autoSyncOnWiFi) {
                Label("Auto-sync on Wi-Fi", systemImage: "wifi")
            }
        } header: {
            Text("Offline & Sync")
        } footer: {
            Text("Offline mode allows you to use the app without an internet connection. Changes will sync when you're back online.")
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