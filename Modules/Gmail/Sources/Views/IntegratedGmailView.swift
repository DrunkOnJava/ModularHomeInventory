import SwiftUI

public struct IntegratedGmailView: View {
    @EnvironmentObject var bridge: GmailBridge
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            GmailReceiptsView()
                .tabItem {
                    Label("Receipts", systemImage: "doc.text")
                }
                .tag(0)
            
            Text("Email List Coming Soon")
                .tabItem {
                    Label("All Emails", systemImage: "envelope")
                }
                .tag(1)
        }
        .environmentObject(bridge)
    }
}
