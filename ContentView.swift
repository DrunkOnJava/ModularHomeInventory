import SwiftUI
import SharedUI
import Items
import BarcodeScanner
import AppSettings
import Receipts
import Core
import Gmail

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0
    @State private var showingSearch = false
    @State private var showingBarcodeSearch = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Use iPad optimized interface
            iPadSidebarView()
                .environmentObject(coordinator)
        } else {
            TabView(selection: $selectedTab) {
                // Items Tab - Now using the Items module!
                NavigationView {
                    coordinator.itemsModule.makeItemsListView(onSearchTapped: {
                        showingSearch = true
                    }, onBarcodeSearchTapped: {
                        showingBarcodeSearch = true
                    })
                }
                    .tabItem {
                        Label("Items", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                // Insurance Tab
                NavigationView {
                    coordinator.itemsModule.makeInsuranceDashboardView()
                }
                    .tabItem {
                        Label("Insurance", systemImage: "shield.fill")
                    }
                    .tag(1)
                
                // Receipts Tab - with Gmail integration
                NavigationView {
                    VStack(spacing: 0) {
                        // Gmail Integration Banner at the top
                        GmailIntegrationBanner()
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        // Receipts List
                        coordinator.receiptsModule.makeReceiptsListView()
                    }
                    .navigationBarTitle("Receipts", displayMode: .large)
                }
                    .tabItem {
                        Label("Receipts", systemImage: "doc.text.fill")
                    }
                    .tag(2)
                
                // Analytics Tab - Spending Dashboard
                NavigationView {
                    coordinator.itemsModule.makeSpendingDashboardView()
                }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
                
                // Scanner Tab - Now using the Scanner module!
                NavigationView {
                    coordinator.scannerModule.makeScannerView()
                }
                    .tabItem {
                        Label("Scanner", systemImage: "barcode.viewfinder")
                    }
                    .tag(4)
                
                // Settings Tab - Now using the Settings module!
                NavigationView {
                    coordinator.settingsModule.makeSettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
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
}

#Preview {
    ContentView()
}