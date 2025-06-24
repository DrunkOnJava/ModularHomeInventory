import SwiftUI
import Core
import SharedUI

/// iPad-optimized sidebar navigation
/// Provides a collapsible sidebar with all main navigation options
struct iPadSidebarView: View {
    @StateObject private var navigationState = iPadNavigationState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $navigationState.selectedTab) {
                Section("Inventory") {
                    Label("Items", systemImage: "shippingbox.fill")
                        .tag(iPadTab.items)
                    
                    Label("Collections", systemImage: "folder.fill")
                        .tag(iPadTab.collections)
                    
                    Label("Locations", systemImage: "location.fill")
                        .tag(iPadTab.locations)
                    
                    Label("Categories", systemImage: "square.grid.2x2.fill")
                        .tag(iPadTab.categories)
                }
                
                Section("Insights") {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                        .tag(iPadTab.analytics)
                    
                    Label("Reports", systemImage: "doc.text.fill")
                        .tag(iPadTab.reports)
                    
                    Label("Budget", systemImage: "dollarsign.circle.fill")
                        .tag(iPadTab.budget)
                }
                
                Section("Tools") {
                    Label("Scanner", systemImage: "barcode.viewfinder")
                        .tag(iPadTab.scanner)
                    
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(iPadTab.search)
                    
                    Label("Import/Export", systemImage: "square.and.arrow.up.on.square.fill")
                        .tag(iPadTab.importExport)
                }
                
                Section {
                    Label("Settings", systemImage: "gear")
                        .tag(iPadTab.settings)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Home Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { navigationState.showAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            // Detail view based on selection
            detailView
                .id(navigationState.selectedTab)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $navigationState.showAddItem) {
            AddItemSheet()
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
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
}

/// Navigation state for iPad
class iPadNavigationState: ObservableObject {
    @Published var selectedTab: iPadTab = .items
    @Published var showAddItem = false
    @Published var selectedItem: Item?
    @Published var selectedCollection: Collection?
    @Published var selectedLocation: Location?
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
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LocationsNavigationView: View {
    var body: some View {
        NavigationStack {
            LocationsListView()
                .navigationTitle("Locations")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoriesNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.settingsModule.makeCategoryManagementView()
                .navigationTitle("Categories")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AnalyticsNavigationView: View {
    var body: some View {
        NavigationStack {
            AnalyticsDashboardView()
                .navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ReportsNavigationView: View {
    var body: some View {
        NavigationStack {
            ReportsDashboardView()
                .navigationTitle("Reports")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BudgetNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeBudgetDashboardView()
                .navigationTitle("Budget")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ScannerNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.scannerModule.makeScannerView()
                .navigationTitle("Scanner")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchNavigationView: View {
    var body: some View {
        NavigationStack {
            AdvancedSearchView()
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ImportExportNavigationView: View {
    var body: some View {
        NavigationStack {
            ImportExportDashboardView()
                .navigationTitle("Import/Export")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.settingsModule.makeSettingsView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
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
            coordinator.itemsModule.makeCSVImportView()
            Divider()
            coordinator.itemsModule.makeCSVExportView()
        }
        .padding()
    }
}

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            coordinator.itemsModule.makeAddItemView()
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

#Preview {
    iPadSidebarView()
}