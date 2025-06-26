//
//  iPadApp.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Main App Target
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: HomeInventoryModularTests/iPadAppTests.swift
//
//  Description: iPad-specific app structure with optimizations for large screen layouts
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Main iPad app structure with all optimizations
struct iPadApp: View {
    @StateObject private var navigationState = IPadNavigationState()
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showKeyboardShortcuts = false
    
    var body: some View {
        Group {
            if isIPad {
                iPadInterface
            } else {
                // Fall back to iPhone interface
                iPhoneInterface
            }
        }
        .environmentObject(navigationState)
        .environmentObject(coordinator)
        .sheet(isPresented: $showKeyboardShortcuts) {
            KeyboardShortcutHelpView()
        }
        .onAppear {
            setupIPadFeatures()
        }
    }
    
    // MARK: - iPad Interface
    
    @ViewBuilder
    private var iPadInterface: some View {
        if shouldUseColumnView {
            iPadColumnView()
                .iPadKeyboardShortcuts(navigationState: navigationState)
                .enableMultitasking()
        } else {
            IPadSidebarView()
                .iPadKeyboardShortcuts(navigationState: navigationState)
                .enableMultitasking()
        }
    }
    
    // MARK: - iPhone Interface
    
    private var iPhoneInterface: some View {
        // Use the standard tab view interface for iPhone
        TabView {
            Text("Items")
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
            
            Text("Collections")
                .tabItem {
                    Label("Collections", systemImage: "folder")
                }
            
            Text("Analytics")
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
            
            Text("Scanner")
                .tabItem {
                    Label("Scanner", systemImage: "barcode.viewfinder")
                }
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
    
    // MARK: - Configuration
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var shouldUseColumnView: Bool {
        // Use column view in landscape on larger iPads
        horizontalSizeClass == .regular && 
        verticalSizeClass == .regular &&
        UIScreen.main.bounds.width > 1000
    }
    
    private func setupIPadFeatures() {
        // Enable keyboard shortcuts
        NotificationCenter.default.addObserver(
            forName: .showKeyboardShortcuts,
            object: nil,
            queue: .main
        ) { _ in
            showKeyboardShortcuts = true
        }
        
        // Setup drag and drop
        configureDragDrop()
        
        // Enable pointer interactions
        configurePointerInteractions()
    }
    
    private func configureDragDrop() {
        // Global drag/drop configuration
    }
    
    private func configurePointerInteractions() {
        // Enable hover effects for mouse/trackpad
    }
}

// MARK: - Multitasking Support

struct MultitaskingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

struct WindowAccessor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Configure window for multitasking
                window.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 768, height: 768)
                window.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 4096, height: 4096)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Scene Configuration

struct iPadSceneDelegate: App {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            iPadApp()
                .environmentObject(coordinator)
                // Commands are added at the scene level
        }
        .commands {
            // File menu additions
            CommandGroup(after: .newItem) {
                Button("Import from CSV...") {
                    NotificationCenter.default.post(name: .showImport, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            
            // View menu
            CommandMenu("View") {
                Button("Show Keyboard Shortcuts") {
                    NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil)
                }
                .keyboardShortcut("/", modifiers: .command)
                
                Divider()
                
                Button("Increase Text Size") {
                    NotificationCenter.default.post(name: .increaseTextSize, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Decrease Text Size") {
                    NotificationCenter.default.post(name: .decreaseTextSize, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)
            }
        }
        
        // Settings window is not available on iOS
    }
}

// MARK: - Slide Over Support

struct SlideOverModifier: ViewModifier {
    @State private var slideOverWidth: CGFloat = 320
    @State private var isSlideOverVisible = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                // Slide over functionality disabled - needs coordination with iPadSidebarEnhanced.swift
                // if isSlideOverVisible {
                //     SlideOverPanel(
                //         content: .scanner,
                //         coordinator: coordinator,
                //         isVisible: $isSlideOverVisible
                //     )
                //         .transition(.move(edge: .trailing))
                // }
            }
    }
}

// SlideOverPanel definition moved to iPadSidebarEnhanced.swift to avoid redeclaration

// MARK: - Mouse/Trackpad Support

struct PointerInteractionModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .pointerStyle(isHovered ? .lift : .automatic)
    }
}

// MARK: - Extensions

extension View {
    func enableMultitasking() -> some View {
        self.modifier(MultitaskingModifier())
    }
    
    func enableSlideOver() -> some View {
        self.modifier(SlideOverModifier())
    }
    
    func pointerInteraction() -> some View {
        self.modifier(PointerInteractionModifier())
    }
    
    func pointerStyle(_ style: PointerStyle) -> some View {
        self.onHover { _ in
            // Pointer style is handled automatically on iPadOS
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
    static let increaseTextSize = Notification.Name("increaseTextSize")
    static let decreaseTextSize = Notification.Name("decreaseTextSize")
    static let showImport = Notification.Name("showImport")
}