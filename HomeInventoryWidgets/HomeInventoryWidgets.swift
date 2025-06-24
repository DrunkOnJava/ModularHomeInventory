import WidgetKit
import SwiftUI
import Core
import Widgets

/// Main widget bundle for Home Inventory
/// Swift 5.9 - No Swift 6 features
@main
struct HomeInventoryWidgetBundle: WidgetBundle {
    var body: some Widget {
        InventoryStatsWidget()
        SpendingSummaryWidget()
        WarrantyExpirationWidget()
        RecentItemsWidget()
    }
}