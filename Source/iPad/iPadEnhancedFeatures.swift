//
//  iPadEnhancedFeatures.swift
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
//  Dependencies: SwiftUI, PencilKit, UniformTypeIdentifiers, Core, SharedUI
//  Testing: HomeInventoryModularTests/iPadEnhancedFeaturesTests.swift
//
//  Description: Comprehensive iPad features including Split View, Slide Over, Multi-window,
//              Mouse/Trackpad support, and Apple Pencil support
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import PencilKit
import UniformTypeIdentifiers
import Core
import SharedUI

// MARK: - Split View Support

struct SplitViewContainer: View {
    @StateObject private var splitViewState = SplitViewState()
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                // Primary view
                NavigationStack(path: $splitViewState.primaryPath) {
                    primaryContent
                        .frame(minWidth: 320, idealWidth: 400)
                }
                
                Divider()
                
                // Secondary view
                NavigationStack(path: $splitViewState.secondaryPath) {
                    secondaryContent
                        .frame(minWidth: 500)
                }
            }
        } else {
            // Compact view for smaller screens
            NavigationStack(path: $splitViewState.primaryPath) {
                primaryContent
            }
        }
    }
    
    @ViewBuilder
    private var primaryContent: some View {
        coordinator.itemsModule.makeItemsListView()
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { splitViewState.showNewWindow.toggle() }) {
                        Image(systemName: "square.split.2x1")
                    }
                }
            }
    }
    
    @ViewBuilder
    private var secondaryContent: some View {
        if let selectedItem = splitViewState.selectedItem {
            coordinator.itemsModule.makeItemDetailView(item: selectedItem)
        } else {
            ContentUnavailableView("Select an Item", 
                                 systemImage: "square.grid.2x2",
                                 description: Text("Choose an item from the list to view details"))
        }
    }
}

// MARK: - Split View State

class SplitViewState: ObservableObject {
    @Published var primaryPath = NavigationPath()
    @Published var secondaryPath = NavigationPath()
    @Published var selectedItem: Item?
    @Published var showNewWindow = false
    @Published var splitRatio: CGFloat = 0.4
}

// MARK: - Slide Over Support

struct SlideOverContainer<Content: View>: View {
    @State private var isSlideOverVisible = false
    @State private var slideOverWidth: CGFloat = 320
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    
    let content: Content
    let slideOverContent: AnyView
    
    init(@ViewBuilder content: () -> Content, slideOver: AnyView) {
        self.content = content()
        self.slideOverContent = slideOver
    }
    
    var body: some View {
        ZStack {
            // Main content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Slide over panel
            if isSlideOverVisible {
                HStack(spacing: 0) {
                    Spacer()
                    
                    slideOverPanel
                        .frame(width: slideOverWidth + dragOffset)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSlideOverVisible)
            }
        }
        .gesture(slideGesture)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isSlideOverVisible.toggle() }) {
                    Image(systemName: "sidebar.right")
                        .symbolVariant(isSlideOverVisible ? .fill : .none)
                }
            }
        }
    }
    
    private var slideOverPanel: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.vertical, 8)
            
            // Content
            slideOverContent
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: slideOverWidth)
        .background(Color(UIColor.systemBackground))
        .overlay(alignment: .leading) {
            // Resize handle
            Rectangle()
                .fill(Color.clear)
                .frame(width: 10)
                .contentShape(Rectangle())
                // Cursor modifier is not available on iOS
                .gesture(resizeGesture)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, x: -5, y: 0)
    }
    
    private var slideGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                if value.startLocation.x > UIScreen.main.bounds.width - 50 {
                    isSlideOverVisible = true
                    dragOffset = max(-slideOverWidth, min(0, value.translation.width))
                }
            }
            .onEnded { value in
                if value.translation.width > 100 {
                    isSlideOverVisible = false
                }
                dragOffset = 0
            }
    }
    
    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newWidth = slideOverWidth - value.translation.width
                slideOverWidth = max(250, min(600, newWidth))
            }
    }
}

// MARK: - Multi-Window Support

struct MultiWindowCoordinator {
    static let shared = MultiWindowCoordinator()
    
    func createNewWindow(for item: Item? = nil) {
        let activity = NSUserActivity(activityType: "com.homeinventory.newWindow")
        
        if let item = item {
            activity.userInfo = ["itemId": item.id.uuidString]
            activity.title = "View \(item.name)"
        } else {
            activity.title = "New Window"
        }
        
        let options = UIScene.ActivationRequestOptions()
        options.requestingScene = nil
        
        UIApplication.shared.requestSceneSessionActivation(
            nil,
            userActivity: activity,
            options: options,
            errorHandler: { error in
                print("Failed to create new window: \(error)")
            }
        )
    }
    
    func configureScene(_ scene: UIWindowScene, with activity: NSUserActivity?) {
        // Configure scene based on activity
        if let activity = activity,
           let itemId = activity.userInfo?["itemId"] as? String {
            // Load specific item in new window
            scene.title = activity.title
            scene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 400)
        }
    }
}

// MARK: - Mouse/Trackpad Support

struct MouseTrackingModifier: ViewModifier {
    @State private var isHovered = false
    @State private var hoverLocation: CGPoint = .zero
    
    let onHover: (Bool, CGPoint) -> Void
    
    func body(content: Content) -> some View {
        content
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    isHovered = true
                    hoverLocation = location
                    onHover(true, location)
                case .ended:
                    isHovered = false
                    onHover(false, .zero)
                }
            }
            .pointerStyle(.automatic)
    }
}

struct EnhancedPointerStyle: ViewModifier {
    let isActive: Bool
    let style: PointerStyle
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && style == .lift ? 1.05 : 1.0)
            .shadow(
                color: .black.opacity(isActive && style == .lift ? 0.2 : 0.1),
                radius: isActive && style == .lift ? 8 : 4,
                y: isActive && style == .lift ? 4 : 2
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Apple Pencil Support

struct PencilDrawingView: UIViewControllerRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isToolPickerVisible: Bool
    let onDrawingChanged: (PKDrawing) -> Void
    
    func makeUIViewController(context: Context) -> PencilDrawingViewController {
        let controller = PencilDrawingViewController()
        controller.canvasView = canvasView
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PencilDrawingViewController, context: Context) {
        uiViewController.isToolPickerVisible = isToolPickerVisible
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PencilDrawingView
        
        init(_ parent: PencilDrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChanged(canvasView.drawing)
        }
    }
}

class PencilDrawingViewController: UIViewController {
    var canvasView = PKCanvasView()
    var toolPicker: PKToolPicker?
    weak var delegate: PKCanvasViewDelegate?
    
    var isToolPickerVisible = true {
        didSet {
            updateToolPicker()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvas()
    }
    
    private func setupCanvas() {
        canvasView.delegate = delegate
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.drawingPolicy = .pencilOnly
        canvasView.backgroundColor = .systemBackground
        canvasView.isOpaque = false
        
        view.addSubview(canvasView)
        NSLayoutConstraint.activate([
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup tool picker
        if let window = view.window {
            toolPicker = PKToolPicker.shared(for: window)
            updateToolPicker()
        }
    }
    
    private func updateToolPicker() {
        if isToolPickerVisible {
            toolPicker?.setVisible(true, forFirstResponder: canvasView)
            toolPicker?.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        } else {
            toolPicker?.setVisible(false, forFirstResponder: canvasView)
            toolPicker?.removeObserver(canvasView)
        }
    }
}

// MARK: - Enhanced Item Card with Pencil Annotation

struct AnnotatableItemCard: View {
    let item: Item
    @State private var showAnnotation = false
    @State private var canvasView = PKCanvasView()
    @State private var annotationImage: UIImage?
    
    var body: some View {
        VStack {
            // Item content
            ItemCard(item: item)
                .overlay(alignment: .topTrailing) {
                    if annotationImage != nil {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .padding(8)
                    }
                }
                .onTapGesture {
                    showAnnotation.toggle()
                }
        }
        .sheet(isPresented: $showAnnotation) {
            NavigationStack {
                PencilAnnotationView(
                    item: item,
                    canvasView: $canvasView,
                    annotationImage: $annotationImage
                )
            }
        }
    }
}

struct PencilAnnotationView: View {
    let item: Item
    @Binding var canvasView: PKCanvasView
    @Binding var annotationImage: UIImage?
    @State private var isToolPickerVisible = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            PencilDrawingView(
                canvasView: $canvasView,
                isToolPickerVisible: $isToolPickerVisible
            ) { drawing in
                // Save drawing as image
                let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
                annotationImage = image
            }
        }
        .navigationTitle("Annotate \(item.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Save annotation
                    saveAnnotation()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button(action: { isToolPickerVisible.toggle() }) {
                    Image(systemName: "pencil.tip.crop.circle")
                        .symbolVariant(isToolPickerVisible ? .fill : .none)
                }
            }
        }
    }
    
    private func saveAnnotation() {
        // Save the annotation to the item
        // This would integrate with your item storage system
    }
}

// MARK: - View Extensions

extension View {
    func splitViewContainer() -> some View {
        SplitViewContainer()
    }
    
    func slideOver<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SlideOverContainer(content: { self }, slideOver: AnyView(content()))
    }
    
    func mouseTracking(onHover: @escaping (Bool, CGPoint) -> Void) -> some View {
        self.modifier(MouseTrackingModifier(onHover: onHover))
    }
    
    func enhancedPointerStyle(_ style: PointerStyle, isActive: Bool) -> some View {
        self.modifier(EnhancedPointerStyle(isActive: isActive, style: style))
    }
    
    // NSCursor is not available on iOS/iPadOS
}

// MARK: - Enhanced Pointer Styles

enum PointerStyle {
    case automatic
    case lift
    case highlight
    case link
    case text
    case resizeLeftRight
    case resizeUpDown
}

// MARK: - Cursor Extensions
// NSCursor is macOS-only, not available on iOS/iPadOS

// MARK: - Item Card for demonstration

struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
            
            // Show item category instead of description
            Text(item.category.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                if let price = item.purchasePrice {
                    let priceDouble = NSDecimalNumber(decimal: price).doubleValue
                    Text("$\(priceDouble, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Price N/A")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let purchaseDate = item.purchaseDate {
                    Text(purchaseDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}