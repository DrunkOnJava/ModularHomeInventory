import SwiftUI
import Combine

/// Theme manager for handling dark mode preferences
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var colorScheme: ColorScheme?
    @Published public var isDarkMode: Bool = false
    @Published public var useSystemTheme: Bool = true
    
    private init() {
        // Load saved preferences
        loadPreferences()
    }
    
    private func loadPreferences() {
        // Check if user has previously set a preference
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            // User has set a preference, use it
            useSystemTheme = false
            isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            colorScheme = isDarkMode ? .dark : .light
        } else {
            // No preference set, use system theme
            useSystemTheme = true
            colorScheme = nil
        }
    }
    
    public func setDarkMode(_ isDark: Bool) {
        isDarkMode = isDark
        useSystemTheme = false
        colorScheme = isDarkMode ? .dark : .light
        
        // Save preference
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

// MARK: - Additional Theme Colors
public extension AppColors {
    // Additional dynamic colors that aren't in the main Colors.swift
    static var groupedBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    static var divider: Color {
        Color(UIColor.separator)
    }
    
    static var primaryMuted: Color {
        primary.opacity(0.1)
    }
    
    static var successMuted: Color {
        success.opacity(0.1)
    }
    
    static var warningMuted: Color {
        warning.opacity(0.1)
    }
    
    static var danger: Color {
        error
    }
    
    static var dangerMuted: Color {
        error.opacity(0.1)
    }
}

// MARK: - View Modifier for Theme
public struct ThemedView: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

public extension View {
    func themedView() -> some View {
        modifier(ThemedView())
    }
}