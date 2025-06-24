import SwiftUI

/// VoiceOver modifiers and helpers for accessibility
/// Swift 5.9 - No Swift 6 features

// MARK: - Accessibility Label Helpers

public extension View {
    /// Add a VoiceOver label to describe the element
    func voiceOverLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }
    
    /// Add a VoiceOver hint to provide additional context
    func voiceOverHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }
    
    /// Combine multiple elements into a single VoiceOver element
    func voiceOverCombine() -> some View {
        self.accessibilityElement(children: .combine)
    }
    
    /// Ignore this element for VoiceOver
    func voiceOverIgnore() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// Mark this as a container that VoiceOver should navigate
    func voiceOverContainer() -> some View {
        self.accessibilityElement(children: .contain)
    }
}

// MARK: - Accessibility Value Helpers

public extension View {
    /// Add a value description for VoiceOver (e.g., "50%" for a progress bar)
    func voiceOverValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }
    
    /// Add a numeric value with range for VoiceOver
    func voiceOverValue<V: BinaryFloatingPoint>(_ value: V, in range: ClosedRange<V>) -> some View {
        self
            .accessibilityValue("\(Int(value))")
            .accessibilityAdjustableAction { direction in
                // This would need to be handled by the parent view
            }
    }
}

// MARK: - Accessibility Traits

public extension View {
    /// Mark as a button for VoiceOver
    func voiceOverButton() -> some View {
        self.accessibilityAddTraits(.isButton)
    }
    
    /// Mark as a header for VoiceOver
    func voiceOverHeader() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
    
    /// Mark as an image for VoiceOver
    func voiceOverImage() -> some View {
        self.accessibilityAddTraits(.isImage)
    }
    
    /// Mark as selected for VoiceOver
    func voiceOverSelected(_ isSelected: Bool) -> some View {
        self.accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Mark as a search field for VoiceOver
    func voiceOverSearchField() -> some View {
        self.accessibilityAddTraits(.isSearchField)
    }
}

// MARK: - Custom Actions

public struct VoiceOverAction {
    public let name: String
    public let action: () -> Void
    
    public init(name: String, action: @escaping () -> Void) {
        self.name = name
        self.action = action
    }
}

public extension View {
    /// Add custom VoiceOver actions
    func voiceOverActions(_ actions: [VoiceOverAction]) -> some View {
        self.modifier(VoiceOverActionsModifier(actions: actions))
    }
}

private struct VoiceOverActionsModifier: ViewModifier {
    let actions: [VoiceOverAction]
    
    func body(content: Content) -> some View {
        content
            .accessibilityActions {
                ForEach(actions, id: \.name) { action in
                    Button(action.name) {
                        action.action()
                    }
                }
            }
    }
}

// MARK: - Focus Management

@available(iOS 15.0, *)
public extension View {
    /// Request VoiceOver focus when a condition is met
    func voiceOverFocus(when condition: Bool, equals value: Bool = true) -> some View {
        self.modifier(VoiceOverFocusModifier(condition: condition, value: value))
    }
}

@available(iOS 15.0, *)
private struct VoiceOverFocusModifier: ViewModifier {
    let condition: Bool
    let value: Bool
    @AccessibilityFocusState private var isVoiceOverFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isVoiceOverFocused)
            .onChange(of: condition) { newCondition in
                if newCondition == value {
                    isVoiceOverFocused = true
                }
            }
    }
}

// MARK: - Announcements

public struct VoiceOverAnnouncement {
    /// Announce a message to VoiceOver users
    public static func announce(_ message: String) {
        #if !os(macOS)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
    
    /// Announce that the screen content has changed
    public static func announceScreenChange() {
        #if !os(macOS)
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        #endif
    }
    
    /// Announce that layout has changed and focus should move
    public static func announceLayoutChange(focusOn view: Any? = nil) {
        #if !os(macOS)
        UIAccessibility.post(notification: .layoutChanged, argument: view)
        #endif
    }
}

// MARK: - Complex View Helpers

/// A view that provides proper VoiceOver support for item cards
public struct AccessibleItemCard<Content: View>: View {
    let itemName: String
    let category: String
    let location: String?
    let quantity: Int
    let value: String?
    let content: Content
    
    public init(
        itemName: String,
        category: String,
        location: String? = nil,
        quantity: Int = 1,
        value: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.itemName = itemName
        self.category = category
        self.location = location
        self.quantity = quantity
        self.value = value
        self.content = content()
    }
    
    public var body: some View {
        content
            .voiceOverCombine()
            .voiceOverLabel(accessibilityLabel)
            .voiceOverHint("Double tap to view details")
    }
    
    private var accessibilityLabel: String {
        var components = [itemName, category]
        
        if let location = location {
            components.append("at \(location)")
        }
        
        if quantity > 1 {
            components.append("\(quantity) items")
        }
        
        if let value = value {
            components.append("valued at \(value)")
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - List Item Helpers

public extension View {
    /// Provide position information for list items
    func voiceOverListItem(position: Int, total: Int) -> some View {
        self.accessibilityLabel("\(position) of \(total)")
    }
}

// MARK: - Image Accessibility

public extension View {
    /// Make an image accessible with a label
    func accessibleImage(_ label: String, isDecorative: Bool = false) -> some View {
        Group {
            if isDecorative {
                self.voiceOverIgnore()
            } else {
                self
                    .voiceOverLabel(label)
                    .voiceOverImage()
            }
        }
    }
}

// MARK: - TextField Accessibility

public extension View {
    /// Add VoiceOver support for text fields
    func voiceOverTextField(
        label: String,
        hint: String? = nil,
        errorMessage: String? = nil
    ) -> some View {
        self
            .voiceOverLabel(label)
            .voiceOverHint(hint ?? "Double tap to edit")
            .overlay(alignment: .bottomLeading) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .voiceOverLabel("Error: \(error)")
                }
            }
    }
}

// MARK: - Progress Indicators

public struct AccessibleProgressView: View {
    let value: Double
    let total: Double
    let label: String
    
    public init(value: Double, total: Double, label: String) {
        self.value = value
        self.total = total
        self.label = label
    }
    
    public var body: some View {
        ProgressView(value: value, total: total)
            .voiceOverLabel(label)
            .voiceOverValue("\(Int(value)) of \(Int(total))")
    }
}

// MARK: - Navigation Helpers

public extension NavigationLink {
    /// Add VoiceOver support for navigation links
    func voiceOverNavigationLink(
        label: String,
        hint: String = "Double tap to navigate"
    ) -> some View {
        self
            .voiceOverLabel(label)
            .voiceOverHint(hint)
            .voiceOverButton()
    }
}

// MARK: - Tab Bar Helpers

public extension View {
    /// Add VoiceOver support for tab items
    func voiceOverTabItem(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .voiceOverLabel(label)
            .voiceOverHint(hint ?? "Double tap to select tab")
    }
}