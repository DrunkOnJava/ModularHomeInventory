import SwiftUI
import Core

/// View modifier to make an item searchable in Spotlight
/// Swift 5.9 - No Swift 6 features
public struct SearchableItemModifier: ViewModifier {
    let item: Item
    let location: Location?
    
    public func body(content: Content) -> some View {
        content
            .userActivity(SpotlightService.viewItemActivityType) { activity in
                // Create user activity for this item
                let itemActivity = SpotlightService.shared.createViewItemActivity(for: item)
                
                // Copy properties to the provided activity
                activity.title = itemActivity.title
                activity.userInfo = itemActivity.userInfo
                activity.contentAttributeSet = itemActivity.contentAttributeSet
                activity.isEligibleForSearch = true
                activity.isEligibleForHandoff = true
                activity.keywords = itemActivity.keywords
            }
            .onAppear {
                // Index item when it appears
                Task {
                    try? await SpotlightService.shared.indexItem(item, location: location)
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Makes an item searchable in Spotlight
    func searchableItem(_ item: Item, location: Location? = nil) -> some View {
        modifier(SearchableItemModifier(item: item, location: location))
    }
}