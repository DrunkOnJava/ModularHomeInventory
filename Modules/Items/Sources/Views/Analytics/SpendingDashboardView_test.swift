import SwiftUI
import Core
import SharedUI
import Charts

/// Spending Dashboard view showing visual spending overview
/// Swift 5.9 - No Swift 6 features
struct SpendingDashboardView: View {
    @StateObject private var viewModel: SpendingDashboardViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingCategoryDetail = false
    @State private var selectedCategory: ItemCategory?
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        case all = "All Time"
        
        var displayName: String { rawValue }
    }
    
    init(viewModel: SpendingDashboardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Text("Test")
    }
}