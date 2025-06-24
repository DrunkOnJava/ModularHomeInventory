import SwiftUI
import Core
import SharedUI

/// Main iPad app structure with all optimizations
struct iPadApp: View {
    @StateObject private var navigationState = iPadNavigationState()
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
            iPadSidebarView()
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
                window.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: .infinity, height: .infinity)
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
                .commands {
                    KeyboardCommandBuilder.buildCommands()
                }
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
        
        #if os(iOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - Slide Over Support

struct SlideOverModifier: ViewModifier {
    @State private var slideOverWidth: CGFloat = 320
    @State private var isSlideOverVisible = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                if isSlideOverVisible {
                    SlideOverPanel(width: $slideOverWidth)
                        .transition(.move(edge: .trailing))
                }
            }
    }
}

struct SlideOverPanel: View {
    @Binding var width: CGFloat
    
    var body: some View {
        VStack {
            // Quick access content
            BarcodeScannerView()
        }
        .frame(width: width)
        .background(AppColors.background)
        .shadow(radius: 10)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newWidth = width - value.translation.width
                    width = min(max(newWidth, 250), 500)
                }
        )
    }
}

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

enum PointerStyle {
    case automatic
    case lift
    case highlight
}

// MARK: - Notification Names

extension Notification.Name {
    static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
    static let increaseTextSize = Notification.Name("increaseTextSize")
    static let decreaseTextSize = Notification.Name("decreaseTextSize")
}