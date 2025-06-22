import SwiftUI
import SharedUI
import Items
import Scanner
import Settings
import Receipts

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Items Tab - Now using the Items module!
            coordinator.itemsModule.makeItemsListView()
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            // Scanner Tab - Now using the Scanner module!
            coordinator.scannerModule.makeScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "barcode.viewfinder")
                }
                .tag(1)
            
            // Receipts Tab - Now using the Receipts module!
            coordinator.receiptsModule.makeReceiptsListView()
            .tabItem {
                Label("Receipts", systemImage: "doc.text")
            }
            .tag(2)
            
            // Settings Tab - Now using the Settings module!
            coordinator.settingsModule.makeSettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(AppColors.primary)
    }
}

#Preview {
    ContentView()
}