import SwiftUI
import SharedUI
import Core
import Sync

/// Enhanced settings view with sophisticated UI/UX
struct EnhancedSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var selectedSection: SettingsSection? = nil
    @State private var searchText = ""
    @State private var showingSheet = false
    @State private var sheetContent: SheetContent? = nil
    
    // Profile
    @State private var userName = "User"
    @State private var userEmail = ""
    @State private var profileImage: UIImage?
    
    // Visual feedback
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                SettingsBackgroundView()
                
                ScrollView {
                    VStack(spacing: 0) {
                    // Profile Header
                    profileHeaderView
                        .padding(.bottom, AppSpacing.md)
                    
                    // Quick Stats
                    quickStatsView
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    
                    // Search Bar
                    if !searchText.isEmpty || isSearching {
                        searchBarView
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.md)
                    }
                    
                    // Settings Sections
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(filteredSections) { section in
                            SettingsSectionCard(
                                section: section,
                                isExpanded: selectedSection == section,
                                searchText: searchText,
                                viewModel: viewModel,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if selectedSection == section {
                                            selectedSection = nil
                                        } else {
                                            selectedSection = section
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                },
                                onItemTap: { item in
                                    handleItemTap(item)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Footer
                    footerView
                        .padding(.top, AppSpacing.xl)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xxl)
                }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isSearching.toggle() }) {
                        Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .sheet(item: $sheetContent) { content in
            sheetView(for: content)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderView: some View {
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
                Button(action: { handleProfileEdit() }) {
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
    
    // MARK: - Quick Stats
    
    private var quickStatsView: some View {
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
    
    // MARK: - Search
    
    @State private var isSearching = false
    
    private var searchBarView: some View {
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
    
    private var filteredSections: [SettingsSection] {
        if searchText.isEmpty {
            return SettingsSection.allSections
        }
        
        return SettingsSection.allSections.compactMap { section in
            let filteredItems = section.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false
            }
            
            if !filteredItems.isEmpty {
                var modifiedSection = section
                modifiedSection.items = filteredItems
                return modifiedSection
            }
            
            if section.title.localizedCaseInsensitiveContains(searchText) {
                return section
            }
            
            return nil
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
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
                Button(action: { handleSupport() }) {
                    Text("Support")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: { handlePrivacy() }) {
                    Text("Privacy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: { handleTerms() }) {
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
    
    // MARK: - Actions
    
    private func handleItemTap(_ item: SettingsItem) {
        impactFeedback.impactOccurred()
        
        switch item.id {
        case "notifications":
            sheetContent = .notifications
        case "spotlight":
            sheetContent = .spotlight
        case "accessibility":
            sheetContent = .accessibility
        case "scanner":
            sheetContent = .scanner
        case "categories":
            sheetContent = .categories
        case "biometric":
            sheetContent = .biometric
        case "privacy":
            sheetContent = .privacy
        case "terms":
            sheetContent = .terms
        case "export":
            sheetContent = .export
        case "clear-cache":
            sheetContent = .clearCache
        case "crash-reporting":
            sheetContent = .crashReporting
        case "sync-status":
            sheetContent = .syncStatus
        case "conflicts":
            sheetContent = .conflicts
        case "offline-data":
            sheetContent = .offlineData
        case "rate":
            sheetContent = .rate
        case "share":
            sheetContent = .share
        case "support":
            handleSupport()
        default:
            break
        }
    }
    
    private func handleProfileEdit() {
        // Handle profile editing
        impactFeedback.impactOccurred()
    }
    
    private func handleSupport() {
        if let url = URL(string: "mailto:support@homeinventory.app") {
            UIApplication.shared.open(url)
        }
    }
    
    private func handlePrivacy() {
        sheetContent = .privacy
    }
    
    private func handleTerms() {
        sheetContent = .terms
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func sheetView(for content: SheetContent) -> some View {
        switch content {
        case .notifications:
            NavigationView {
                NotificationSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .spotlight:
            NavigationView {
                SpotlightSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .accessibility:
            NavigationView {
                AccessibilitySettingsView(settingsStorage: viewModel.settingsStorage)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .scanner:
            ScannerSettingsView(settings: $viewModel.settings, viewModel: viewModel)
        case .categories:
            Text("Category Management")
        case .biometric:
            NavigationView {
                BiometricSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .privacy:
            PrivacyPolicyView()
        case .terms:
            TermsOfServiceView()
        case .export:
            ExportDataView()
        case .clearCache:
            ClearCacheView()
        case .crashReporting:
            NavigationView {
                CrashReportingSettingsView(settingsStorage: viewModel.settingsStorage)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .syncStatus:
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
                        Button("Done") { sheetContent = nil }
                    }
                }
            }
        case .conflicts:
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
        case .offlineData:
            NavigationView {
                OfflineDataView()
                    .navigationTitle("Offline Data")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { sheetContent = nil }
                        }
                    }
            }
        case .rate:
            RateAppView()
        case .share:
            ShareAppView()
        }
    }
}

// MARK: - Supporting Types

enum SheetContent: Identifiable {
    case notifications
    case spotlight
    case accessibility
    case scanner
    case categories
    case biometric
    case privacy
    case terms
    case export
    case clearCache
    case crashReporting
    case syncStatus
    case conflicts
    case offlineData
    case rate
    case share
    
    var id: String {
        switch self {
        case .notifications: return "notifications"
        case .spotlight: return "spotlight"
        case .accessibility: return "accessibility"
        case .scanner: return "scanner"
        case .categories: return "categories"
        case .biometric: return "biometric"
        case .privacy: return "privacy"
        case .terms: return "terms"
        case .export: return "export"
        case .clearCache: return "clearCache"
        case .crashReporting: return "crashReporting"
        case .syncStatus: return "syncStatus"
        case .conflicts: return "conflicts"
        case .offlineData: return "offlineData"
        case .rate: return "rate"
        case .share: return "share"
        }
    }
}

// MARK: - Settings Section Model

struct SettingsSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    var items: [SettingsItem]
    
    static let allSections: [SettingsSection] = [
        SettingsSection(
            title: "General",
            icon: "gear",
            color: AppColors.primary,
            items: [
                SettingsItem(id: "notifications", title: "Notifications", icon: "bell", type: .navigation),
                SettingsItem(id: "spotlight", title: "Spotlight Search", icon: "magnifyingglass", type: .navigation),
                SettingsItem(id: "accessibility", title: "Accessibility", icon: "accessibility", type: .navigation),
                SettingsItem(id: "dark-mode", title: "Dark Mode", icon: "moon", type: .toggle(key: "darkMode")),
                SettingsItem(id: "currency", title: "Currency", icon: "dollarsign.circle", type: .picker(key: "currency", options: ["USD", "EUR", "GBP", "JPY"])),
                SettingsItem(id: "scanner", title: "Scanner Settings", icon: "barcode.viewfinder", type: .navigation),
                SettingsItem(id: "categories", title: "Manage Categories", icon: "folder", type: .navigation)
            ]
        ),
        SettingsSection(
            title: "Privacy & Security",
            icon: "lock.shield",
            color: .blue,
            items: [
                SettingsItem(id: "biometric", title: "Face ID / Touch ID", icon: BiometricAuthService.shared.biometricType.icon, type: .navigation),
                SettingsItem(id: "privacy", title: "Privacy Policy", icon: "hand.raised", type: .navigation),
                SettingsItem(id: "terms", title: "Terms of Service", icon: "doc.text", type: .navigation)
            ]
        ),
        SettingsSection(
            title: "Data & Storage",
            icon: "internaldrive",
            color: .green,
            items: [
                SettingsItem(id: "auto-backup", title: "Auto Backup", icon: "icloud", type: .toggle(key: "autoBackup")),
                SettingsItem(id: "export", title: "Export Data", icon: "square.and.arrow.up", type: .navigation),
                SettingsItem(id: "clear-cache", title: "Clear Cache", icon: "trash", type: .action, destructive: true),
                SettingsItem(id: "crash-reporting", title: "Crash Reporting", icon: "exclamationmark.triangle", type: .navigation)
            ]
        ),
        SettingsSection(
            title: "Sync & Offline",
            icon: "arrow.triangle.2.circlepath",
            color: .purple,
            items: [
                SettingsItem(id: "offline-mode", title: "Enable Offline Mode", icon: "wifi.slash", type: .toggle(key: "offlineMode")),
                SettingsItem(id: "sync-status", title: "Sync Status", icon: "arrow.triangle.2.circlepath", type: .navigation, badge: "Synced"),
                SettingsItem(id: "conflicts", title: "Resolve Conflicts", icon: "exclamationmark.icloud", type: .navigation),
                SettingsItem(id: "offline-data", title: "Manage Offline Data", icon: "internaldrive", type: .navigation),
                SettingsItem(id: "auto-sync-wifi", title: "Auto-sync on Wi-Fi", icon: "wifi", type: .toggle(key: "autoSyncWiFi"))
            ]
        ),
        SettingsSection(
            title: "Support",
            icon: "questionmark.circle",
            color: .orange,
            items: [
                SettingsItem(id: "rate", title: "Rate Home Inventory", icon: "star", type: .navigation),
                SettingsItem(id: "share", title: "Share App", icon: "square.and.arrow.up", type: .navigation),
                SettingsItem(id: "support", title: "Contact Support", icon: "envelope", type: .action)
            ]
        )
    ]
}

struct SettingsItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let type: SettingsItemType
    var subtitle: String? = nil
    var badge: String? = nil
    var destructive: Bool = false
}

enum SettingsItemType {
    case toggle(key: String)
    case navigation
    case action
    case picker(key: String, options: [String])
}

// MARK: - Components

struct SettingsSectionCard: View {
    let section: SettingsSection
    let isExpanded: Bool
    let searchText: String
    let viewModel: SettingsViewModel
    let onTap: () -> Void
    let onItemTap: (SettingsItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    // Icon
                    Image(systemName: section.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(section.color)
                        .cornerRadius(8)
                    
                    // Title
                    Text(section.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Items
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(section.items) { item in
                        SettingsItemRow(
                            item: item,
                            viewModel: viewModel,
                            onTap: { onItemTap(item) }
                        )
                        
                        if item.id != section.items.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SettingsItemRow: View {
    let item: SettingsItem
    let viewModel: SettingsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.destructive ? .red : AppColors.textSecondary)
                    .frame(width: 24)
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16))
                        .foregroundColor(item.destructive ? .red : AppColors.textPrimary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Right side content
                switch item.type {
                case .toggle(let key):
                    Toggle("", isOn: boolBinding(for: key))
                        .labelsHidden()
                    
                case .navigation:
                    if let badge = item.badge {
                        Text(badge)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                    
                case .action:
                    EmptyView()
                    
                case .picker(let key, let options):
                    Picker("", selection: stringBinding(for: key)) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func boolBinding(for key: String) -> Binding<Bool> {
        switch key {
        case "darkMode":
            return Binding(
                get: { ThemeManager.shared.isDarkMode },
                set: { isDark in
                    ThemeManager.shared.useSystemTheme = false
                    ThemeManager.shared.setDarkMode(isDark)
                }
            )
        case "autoBackup":
            return $viewModel.settings.autoBackupEnabled
        case "offlineMode":
            return $viewModel.settings.offlineModeEnabled
        case "autoSyncWiFi":
            return $viewModel.settings.autoSyncOnWiFi
        default:
            return .constant(false)
        }
    }
    
    private func stringBinding(for key: String) -> Binding<String> {
        switch key {
        case "currency":
            return $viewModel.settings.defaultCurrency
        default:
            return .constant("")
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

#Preview {
    EnhancedSettingsView(
        viewModel: SettingsViewModel(
            settingsStorage: UserDefaultsSettingsStorage(),
            itemRepository: nil,
            receiptRepository: nil,
            locationRepository: nil
        )
    )
}