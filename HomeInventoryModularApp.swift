import SwiftUI
import SharedUI
import Core

@main
struct HomeInventoryModularApp: App {
    // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // Temporarily disabled until AppDelegate is properly added to target
    @StateObject private var coordinator = AppCoordinator()
    @State private var selectedItem: Item?
    @State private var showingItem = false
    
    init() {
        // Basic app initialization
        print("🚀 HomeInventory Modular App Starting...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .themedView()
                .onContinueUserActivity(SpotlightService.viewItemActivityType) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
                .sheet(isPresented: $showingItem) {
                    if let item = selectedItem {
                        coordinator.itemsModule.makeItemDetailView(item: item)
                    }
                }
        }
    }
    
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        Task { @MainActor in
            if let item = await SpotlightIntegrationManager.shared.handleUserActivity(userActivity) {
                selectedItem = item
                showingItem = true
            }
        }
    }
}