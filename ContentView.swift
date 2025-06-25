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
                
                // Analytics Tab - Spending Dashboard
                NavigationView {
                    coordinator.itemsModule.makeSpendingDashboardView()
                }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                // Scanner Tab - Now using the Scanner module!
                NavigationView {
                    coordinator.scannerModule.makeScannerView()
                }
                    .tabItem {
                        Label("Scanner", systemImage: "barcode.viewfinder")
                    }
                    .tag(3)
                
                // Settings Tab - Now using the Settings module!
                NavigationView {
                    coordinator.settingsModule.makeSettingsView()
                }
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
}

// Gmail banner for promoting Gmail integration
struct GmailBanner: View {
    @StateObject private var gmailModule = GmailModule()
    @State private var showingGmailSetup = false
    
    var body: some View {
        if !gmailModule.isAuthenticated {
            Button(action: { showingGmailSetup = true }) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect Gmail for Easy Receipt Import")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Automatically import receipts from your email")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showingGmailSetup) {
                gmailModule.makeReceiptImportView()
            }
        }
    }
}

// Button style for subtle scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}