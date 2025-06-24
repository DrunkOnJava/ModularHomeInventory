import SwiftUI
import SharedUI
import Items
import BarcodeScanner
import AppSettings
import Receipts
import Core

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0
    @State private var showingSearch = false
    @State private var showingBarcodeSearch = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Items Tab - Now using the Items module!
            coordinator.itemsModule.makeItemsListView(onSearchTapped: {
                showingSearch = true
            }, onBarcodeSearchTapped: {
                showingBarcodeSearch = true
            })
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            // Collections Tab
            coordinator.itemsModule.makeCollectionsListView()
                .tabItem {
                    Label("Collections", systemImage: "folder")
                }
                .tag(1)
            
            // Analytics Tab - Spending Dashboard
            coordinator.itemsModule.makeSpendingDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            // Scanner Tab - Now using the Scanner module!
            coordinator.scannerModule.makeScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "barcode.viewfinder")
                }
                .tag(3)
            
            // Settings Tab - Now using the Settings module!
            coordinator.settingsModule.makeSettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .accentColor(AppColors.primary)
        .withOfflineIndicator()
        .sheet(isPresented: $showingSearch) {
            coordinator.itemsModule.makeNaturalLanguageSearchView()
        }
        .sheet(isPresented: $showingBarcodeSearch) {
            coordinator.itemsModule.makeBarcodeSearchView()
        }
        // Biometric lock would be added here when BiometricLockModifier is available
    }
}

#Preview {
    ContentView()
}