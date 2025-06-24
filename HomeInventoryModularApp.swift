import SwiftUI
import SharedUI

@main
struct HomeInventoryModularApp: App {
    // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // Temporarily disabled until AppDelegate is properly added to target
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