//
//  iPadSidebarView.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Main App Target
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: HomeInventoryModularTests/iPadSidebarViewTests.swift
//
//  Description: iPad-optimized sidebar navigation for multi-column layout
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// iPad-optimized sidebar navigation
/// Provides a collapsible sidebar with all main navigation options
struct IPadSidebarView: View {
    @StateObject private var navigationState = IPadNavigationState()
    @EnvironmentObject var coordinator: AppCoordinator
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
                    
                    Button(action: { navigationState.selectedTab = .insurance }) {
                        Label("Insurance", systemImage: "shield.fill")
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(navigationState.selectedTab == .insurance ? Color.accentColor.opacity(0.1) : nil)
                    
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
                .environmentObject(coordinator)
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        Group {
            switch navigationState.selectedTab {
            case .items:
                ItemsNavigationView()
                    .environmentObject(coordinator)
            case .insurance:
                InsuranceNavigationView()
                    .environmentObject(coordinator)
            case .locations:
                LocationsNavigationView()
                    .environmentObject(coordinator)
            case .categories:
                CategoriesNavigationView()
                    .environmentObject(coordinator)
            case .analytics:
                AnalyticsNavigationView()
                    .environmentObject(coordinator)
            case .reports:
                ReportsNavigationView()
                    .environmentObject(coordinator)
            case .budget:
                BudgetNavigationView()
                    .environmentObject(coordinator)
            case .scanner:
                ScannerNavigationView()
                    .environmentObject(coordinator)
            case .search:
                SearchNavigationView()
                    .environmentObject(coordinator)
            case .importExport:
                ImportExportNavigationView()
                    .environmentObject(coordinator)
            case .settings:
                SettingsNavigationView()
                    .environmentObject(coordinator)
            }
        }
    }
}

/// Navigation state for iPad
class IPadNavigationState: ObservableObject {
    @Published var selectedTab: IPadTab = .items
    @Published var showAddItem = false
    @Published var selectedItem: Item?
    @Published var selectedInsurancePolicy: InsurancePolicy?
    @Published var selectedLocation: Location?
    @Published var showExport = false
    @Published var showImport = false
    @Published var showDuplicate = false
    @Published var showDeleteConfirmation = false
    @Published var showQuickLook = false
}

/// iPad navigation tabs
enum IPadTab: String, CaseIterable {
    case items
    case insurance
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
        }
    }
}

struct InsuranceNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeInsuranceDashboardView()
        }
    }
}

struct LocationsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeStorageUnitsListView()
        }
    }
}

struct CategoriesNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeTagsManagementView()
        }
    }
}

struct AnalyticsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeSpendingDashboardView()
        }
    }
}

struct ReportsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeDepreciationReportView()
        }
    }
}

struct BudgetNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeBudgetDashboardView()
        }
    }
}

struct ScannerNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.scannerModule.makeScannerView()
        }
    }
}

struct SearchNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.itemsModule.makeNaturalLanguageSearchView()
        }
    }
}

struct ImportExportNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            ImportExportDashboard()
                .environmentObject(coordinator)
        }
    }
}

struct SettingsNavigationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack {
            coordinator.settingsModule.makeSettingsView()
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
        coordinator.itemsModule.makeAddItemView { newItem in
            dismiss()
        }
    }
}

// MARK: - Import/Export Dashboard

struct ImportExportDashboard: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingImport = false
    @State private var showingExport = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("Import & Export")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: AppSpacing.xl) {
                // Import Card
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Import from CSV")
                        .font(.title2)
                        .bold()
                    
                    Text("Import your inventory data from a CSV file")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: { showingImport = true }) {
                        Text("Import Data")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(AppColors.primary)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.large)
                
                // Export Card
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Export to CSV")
                        .font(.title2)
                        .bold()
                    
                    Text("Export your inventory data to a CSV file")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: { showingExport = true }) {
                        Text("Export Data")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(AppColors.primary)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.large)
            }
            
            Spacer()
        }
        .padding(AppSpacing.xl)
        .navigationTitle("Import & Export")
        .sheet(isPresented: $showingImport) {
            NavigationView {
                coordinator.itemsModule.makeCSVImportView { result in
                    showingImport = false
                    print("Import completed with \(result.successfulImports) items")
                }
                .navigationTitle("Import from CSV")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingImport = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            NavigationView {
                coordinator.itemsModule.makeCSVExportView(items: nil)
                    .navigationTitle("Export to CSV")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingExport = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    IPadSidebarView()
}
