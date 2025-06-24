import SwiftUI
import Core

/// View modifier to apply user's text size preference from settings
public struct DynamicTypeModifier: ViewModifier {
    @ObservedObject private var settingsStorage: any SettingsStorageProtocol
    
    public init(settingsStorage: any SettingsStorageProtocol) {
        self.settingsStorage = settingsStorage
    }
    
    public func body(content: Content) -> some View {
        content
            .textSizePreference(textSizePreference)
            .environment(\.legibilityWeight, legibilityWeight)
    }
    
    private var textSizePreference: TextSizePreference? {
        guard let savedSize = settingsStorage.string(forKey: .textSizePreference),
              let preference = TextSizePreference(rawValue: savedSize) else {
            return nil
        }
        return preference
    }
    
    private var legibilityWeight: LegibilityWeight? {
        guard let enableBold = settingsStorage.bool(forKey: .enableBoldText),
              enableBold else {
            return nil
        }
        return .bold
    }
}

// MARK: - View Extension

public extension View {
    /// Apply user's text size and accessibility preferences
    func applyDynamicType(settingsStorage: any SettingsStorageProtocol) -> some View {
        modifier(DynamicTypeModifier(settingsStorage: settingsStorage))
    }
}

// MARK: - Accessibility Layout Helpers

public struct AccessibilityLayoutModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    
    public func body(content: Content) -> some View {
        if sizeCategory.isAccessibilityCategory {
            // Use vertical layout for accessibility sizes
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                content
            }
        } else {
            // Use horizontal layout for regular sizes
            HStack(spacing: AppSpacing.md) {
                content
            }
        }
    }
}

public extension View {
    /// Automatically switch between horizontal and vertical layout based on text size
    func accessibilityAdaptiveLayout() -> some View {
        modifier(AccessibilityLayoutModifier())
    }
}

