import SwiftUI
import SharedUI
import Core
import Sync


/// Simplified enhanced settings view with sophisticated UI/UX
public struct EnhancedSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var searchText = ""
    @State private var showingSheet = false
    @State private var sheetContent: SheetContent? = nil
    @State private var userName = "User"
    @State private var userEmail = ""
    @State private var profileImage: UIImage?
    @State private var isSearching = false
    
    public init(viewModel: SettingsViewModel) {
        print("EnhancedSettingsView.init called")
        print("Stack trace: \(Thread.callStackSymbols)")
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        let _ = print("EnhancedSettingsView: Rendering body")
        ZStack {
            // Background
            SettingsBackgroundView()
            
            ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        SettingsProfileHeaderView(
                            userName: $userName,
                            userEmail: $userEmail,
                            profileImage: $profileImage,
                            onProfileEdit: handleProfileEdit
                        )
                        .padding(.bottom, AppSpacing.md)
                        
                        // Quick Stats
                        SettingsQuickStatsView()
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.lg)
                        
                        // Search Bar
                        if isSearching {
                            SettingsSearchBarView(searchText: $searchText)
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.bottom, AppSpacing.md)
                        }
                        
                        // Settings List
                        SettingsListView(
                            searchText: searchText,
                            viewModel: viewModel,
                            onItemTap: handleItemTap
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // Footer
                        SettingsFooterView(
                            onSupport: handleSupport,
                            onPrivacy: handlePrivacy,
                            onTerms: handleTerms
                        )
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
        .sheet(item: $sheetContent) { content in
            sheetView(for: content)
        }
    }
    
    // MARK: - Actions
    
    private func handleItemTap(_ item: SettingsItem) {
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
        case "autoLock":
            sheetContent = .autoLock
        case "privateMode":
            sheetContent = .privateMode
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
        case "backup":
            sheetContent = .backup
        case "currencyExchange":
            sheetContent = .currencyExchange
        default:
            break
        }
    }
    
    private func handleProfileEdit() {
        // Handle profile editing
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
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .spotlight:
            NavigationView {
                SpotlightSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .accessibility:
            NavigationView {
                AccessibilitySettingsView(settingsStorage: viewModel.settingsStorage)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .scanner:
            ScannerSettingsView(settings: $viewModel.settings, viewModel: viewModel)
        case .categories:
            Text("Category Management")
        case .biometric:
            NavigationView {
                BiometricSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
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
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .syncStatus:
            NavigationView {
                VStack(spacing: AppSpacing.lg) {
                    SyncStatusView(syncService: MultiPlatformSyncService())
                    Spacer()
                }
                .padding(AppSpacing.lg)
                .navigationTitle("Sync Status")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
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
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .rate:
            RateAppView()
        case .share:
            ShareAppView()
        case .backup:
            BackupManagerView()
        case .autoLock:
            NavigationView {
                AutoLockSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .privateMode:
            NavigationView {
                PrivateModeSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        case .currencyExchange:
            NavigationView {
                VStack(spacing: 0) {
                    CurrencyConverterView()
                    
                    Divider()
                    
                    NavigationLink(destination: CurrencySettingsView()) {
                        Label("Currency Settings", systemImage: "gear")
                            .padding()
                    }
                }
                .navigationTitle("Currency Exchange")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") { sheetContent = nil })
            }
        }
    }
}

// MARK: - Settings List View

struct SettingsListView: View {
    let searchText: String
    @ObservedObject var viewModel: SettingsViewModel
    let onItemTap: (SettingsItem) -> Void
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(filteredSections) { section in
                SettingsSectionCard(
                    section: section,
                    isExpanded: expandedSections.contains(section.title),
                    viewModel: viewModel,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if expandedSections.contains(section.title) {
                                expandedSections.remove(section.title)
                            } else {
                                expandedSections.insert(section.title)
                            }
                        }
                    },
                    onItemTap: onItemTap
                )
            }
        }
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
}

// MARK: - Supporting Types

enum SheetContent: Identifiable {
    case notifications, spotlight, accessibility, scanner, categories
    case biometric, privacy, terms, export, clearCache
    case crashReporting, syncStatus, conflicts, offlineData
    case rate, share, backup, currencyExchange, autoLock, privateMode
    
    var id: String {
        String(describing: self)
    }
}

struct SettingsSection: Identifiable {
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
                SettingsItem(id: "currency", title: "Currency", icon: "dollarsign.circle", type: .picker(key: "currency", options: ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "KRW"])),
                SettingsItem(id: "currencyExchange", title: "Currency Exchange", icon: "arrow.left.arrow.right.circle", type: .navigation),
                SettingsItem(id: "scanner", title: "Scanner Settings", icon: "barcode.viewfinder", type: .navigation),
                SettingsItem(id: "categories", title: "Manage Categories", icon: "folder", type: .navigation)
            ]
        ),
        SettingsSection(
            title: "Privacy & Security",
            icon: "lock.shield",
            color: .blue,
            items: [
                SettingsItem(id: "biometric", title: "Face ID / Touch ID", icon: "faceid", type: .navigation),
                SettingsItem(id: "autoLock", title: "Auto-Lock", icon: "lock.shield", type: .navigation),
                SettingsItem(id: "privateMode", title: "Private Mode", icon: "eye.slash", type: .navigation),
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
                SettingsItem(id: "auto-sync-wifi", title: "Auto-sync on Wi-Fi", icon: "wifi", type: .toggle(key: "autoSyncWiFi")),
                SettingsItem(id: "backup", title: "Backups", icon: "externaldrive.badge.timemachine", type: .navigation)
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
    @ObservedObject var viewModel: SettingsViewModel
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
    @ObservedObject var viewModel: SettingsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.destructive ? .red : AppColors.textSecondary)
                    .frame(width: 24)
                
                // Title
                Text(item.title)
                    .font(.system(size: 16))
                    .foregroundColor(item.destructive ? .red : AppColors.textPrimary)
                
                Spacer()
                
                // Right side content
                rightSideContent
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var rightSideContent: some View {
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