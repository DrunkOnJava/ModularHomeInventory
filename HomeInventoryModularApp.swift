import SwiftUI
import SharedUI

@main
struct HomeInventoryModularApp: App {
    @StateObject private var coordinator = AppCoordinator()
    
    init() {
        // Basic app initialization
        print("🚀 HomeInventory Modular App Starting...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .themedView()
        }
    }
}