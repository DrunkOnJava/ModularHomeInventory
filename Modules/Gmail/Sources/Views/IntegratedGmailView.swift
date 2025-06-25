import SwiftUI

/// Integrated Gmail view that combines both implementations
public struct IntegratedGmailView: View {
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Receipt-focused view using old implementation
            GmailReceiptsView()
                .tabItem {
                    Label("Receipts", systemImage: "doc.text")
                }
                .tag(0)
            
            // Full Gmail view using new implementation
            GmailView()
                .tabItem {
                    Label("Inbox", systemImage: "envelope")
                }
                .tag(1)
            
            // Receipts list from new implementation
            ReceiptListView()
                .tabItem {
                    Label("Parsed", systemImage: "doc.text.magnifyingglass")
                }
                .tag(2)
        }
    }
}