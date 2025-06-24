import SwiftUI
import Core
import SharedUI

/// iPad-optimized sidebar navigation
/// Provides a collapsible sidebar with all main navigation options
struct iPadSidebarView: View {
    @StateObject private var navigationState = iPadNavigationState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                Section("Inventory") {
                    Button(action: { navigationState.selectedTab = .items }) {
                        Label("Items", systemImage: "shippingbox.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .items ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .collections }) {
                        Label("Collections", systemImage: "folder.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .collections ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .locations }) {
                        Label("Locations", systemImage: "location.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .locations ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .categories }) {
                        Label("Categories", systemImage: "square.grid.2x2.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .categories ? Color.accentColor.opacity(0.1) : nil)
                }
                
                Section("Insights") {
                    Button(action: { navigationState.selectedTab = .analytics }) {
                        Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .analytics ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .reports }) {
                        Label("Reports", systemImage: "doc.text.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .reports ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .budget }) {
                        Label("Budget", systemImage: "dollarsign.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .budget ? Color.accentColor.opacity(0.1) : nil)
                }
                
                Section("Tools") {
                    Button(action: { navigationState.selectedTab = .scanner }) {
                        Label("Scanner", systemImage: "barcode.viewfinder")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .scanner ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .search }) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .search ? Color.accentColor.opacity(0.1) : nil)
                    
                    Button(action: { navigationState.selectedTab = .importExport }) {
                        Label("Import/Export", systemImage: "square.and.arrow.up.on.square.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .importExport ? Color.accentColor.opacity(0.1) : nil)
                }
                
                Section {
                    Button(action: { navigationState.selectedTab = .settings }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .settings ? Color.accentColor.opacity(0.1) : nil)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Home Inventory")
            .navigationBarTitleDisplayMode(.large)
        } detail: {
            // Detail view based on selection
            detailView
                .id(navigationState.selectedTab)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        .sheet(isPresented: $navigationState.showAddItem) {
            AddItemSheet()
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        Group {
            switch navigationState.selectedTab {
        case .items:
            ItemsNavigationView()
        case .collections:
            CollectionsNavigationView()
        case .locations:
            LocationsNavigationView()
        case .categories:
            CategoriesNavigationView()
        case .analytics:
            AnalyticsNavigationView()
        case .reports:
            ReportsNavigationView()
        case .budget:
            BudgetNavigationView()
        case .scanner:
            ScannerNavigationView()
        case .search:
            SearchNavigationView()
        case .importExport:
            ImportExportNavigationView()
        case .settings:
            SettingsNavigationView()
        }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { navigationState.showAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

/// Navigation state for iPad
class iPadNavigationState: ObservableObject {
    @Published var selectedTab: iPadTab = .items
    @Published var showAddItem = false
    @Published var selectedItem: Item?
    @Published var selectedCollection: Collection?
    @Published var selectedLocation: Location?
    @Published var showExport = false
    @Published var showImport = false
    @Published var showDuplicate = false
    @Published var showDeleteConfirmation = false
    @Published var showQuickLook = false
}

/// iPad navigation tabs
enum iPadTab: String, CaseIterable {
    case items
    case collections
    case locations
    case categories
    case analytics
    case reports
    case budget
    case scanner
    case search
    case importExport
    case settings
}

// MARK: - Navigation Views

struct ItemsNavigationView: View {
    @State private var selectedItem: Item?
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeItemsListView(
                onSearchTapped: {},
                onBarcodeSearchTapped: {}
            )
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CollectionsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeCollectionsListView()
                .navigationTitle("Collections")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct LocationsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeLocationsListView()
                .navigationTitle("Locations")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct CategoriesNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeCategoryListView()
                .navigationTitle("Categories")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct AnalyticsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeSpendingDashboardView()
                .navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct ReportsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeInventoryReportView()
                .navigationTitle("Reports")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct BudgetNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeBudgetDashboardView()
                .navigationTitle("Budget")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct ScannerNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.scannerModule.makeScannerView()
                .navigationTitle("Scanner")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct SearchNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeAdvancedSearchView()
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct ImportExportNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            ImportExportDashboard()
                .environmentObject(coordinator)
                .navigationTitle("Import/Export")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct SettingsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.settingsModule.makeSettingsView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

// MARK: - Placeholder Views

struct LocationsListView: View {
    var body: some View {
        Text("Locations List")
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct AnalyticsDashboardView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        coordinator.itemsModule.makeSpendingDashboardView()
    }
}

struct ReportsDashboardView: View {
    var body: some View {
        VStack {
            Text("Reports Dashboard")
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

struct AdvancedSearchView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        coordinator.itemsModule.makeNaturalLanguageSearchView()
    }
}

struct ImportExportDashboardView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            coordinator.itemsModule.makeCSVImportView { result in
                // Handle import completion
                print("Import completed with \(result.successfulImports) items")
            }
            Divider()
            coordinator.itemsModule.makeCSVExportView(items: nil)
        }
        .padding()
    }
}

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            coordinator.itemsModule.makeAddItemView { newItem in
                dismiss()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Import/Export Dashboard

struct ImportExportDashboard: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            coordinator.itemsModule.makeCSVImportView { result in
                print("Import completed with \(result.successfulImports) items")
            }
            Divider()
            coordinator.itemsModule.makeCSVExportView(items: nil)
        }
        .padding()
    }
}

#Preview {
    iPadSidebarView()
}