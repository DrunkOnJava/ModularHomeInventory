//
//  iPadSidebarEnhanced.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, Items, BarcodeScanner, AppSettings, Receipts
//  Testing: HomeInventoryModularTests/iPadSidebarEnhancedTests.swift
//
//  Description: Enhanced iPad sidebar with Split View, Slide Over, Multi-window,
//              Mouse support, and Pencil support
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import PencilKit

/// Enhanced iPad sidebar view with all advanced features
struct IPadSidebarEnhanced: View {
    @StateObject private var navigationState = IPadNavigationState()
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isSlideOverVisible = false
    @State private var slideOverContent: SlideOverContent = .scanner
    @State private var selectedDetailItem: Item?
    @State private var canvasView = PKCanvasView()
    @State private var isHovering = false
    @State private var hoverLocation: CGPoint = .zero
    
    var body: some View {
        ZStack {
            // Main split view interface
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Enhanced sidebar with mouse tracking
                sidebarContent
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            } content: {
                // Middle column for list views
                contentView
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600)
            } detail: {
                // Detail column
                detailView
            }
            .navigationSplitViewStyle(.balanced)
            
            // Slide over panel
            if isSlideOverVisible {
                HStack {
                    Spacer()
                    SlideOverPanel(
                        content: slideOverContent,
                        coordinator: coordinator,
                        isVisible: $isSlideOverVisible
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSlideOverVisible)
            }
        }
        .toolbar {
            toolbarContent
        }
        .onAppear {
            configureiPadFeatures()
        }
    }
    
    // MARK: - Sidebar Content
    
    @ViewBuilder
    private var sidebarContent: some View {
        List {
            Section("Inventory") {
                ForEach(InventorySection.allCases, id: \.self) { section in
                    NavigationButton(
                        title: section.title,
                        icon: section.icon,
                        isSelected: navigationState.selectedTab == section.tab,
                        action: {
                            navigationState.selectedTab = section.tab
                        }
                    )
                    .onHover { hovering in
                        // Mouse cursor changes are handled automatically on iOS
                    }
                }
            }
            
            Section("Insights") {
                ForEach(InsightsSection.allCases, id: \.self) { section in
                    NavigationButton(
                        title: section.title,
                        icon: section.icon,
                        isSelected: navigationState.selectedTab == section.tab,
                        action: {
                            navigationState.selectedTab = section.tab
                        }
                    )
                }
            }
            
            Section("Tools") {
                ForEach(ToolsSection.allCases, id: \.self) { section in
                    NavigationButton(
                        title: section.title,
                        icon: section.icon,
                        isSelected: navigationState.selectedTab == section.tab,
                        action: {
                            navigationState.selectedTab = section.tab
                        }
                    )
                }
            }
            
            Section {
                NavigationButton(
                    title: "Settings",
                    icon: "gear",
                    isSelected: navigationState.selectedTab == .settings,
                    action: {
                        navigationState.selectedTab = .settings
                    }
                )
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Home Inventory")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            switch navigationState.selectedTab {
            case .items:
                ItemsListContent(selectedItem: $selectedDetailItem)
                    .environmentObject(coordinator)
            case .insurance:
                coordinator.itemsModule.makeInsuranceDashboardView()
            case .locations:
                coordinator.itemsModule.makeStorageUnitsListView()
            case .categories:
                coordinator.itemsModule.makeTagsManagementView()
            case .analytics:
                coordinator.itemsModule.makeSpendingDashboardView()
            case .reports:
                coordinator.itemsModule.makeDepreciationReportView()
            case .budget:
                coordinator.itemsModule.makeBudgetDashboardView()
            case .scanner:
                coordinator.scannerModule.makeScannerView()
            case .search:
                coordinator.itemsModule.makeNaturalLanguageSearchView()
            case .importExport:
                ImportExportDashboard()
                    .environmentObject(coordinator)
            case .settings:
                coordinator.settingsModule.makeSettingsView()
            }
        }
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        if let item = selectedDetailItem {
            ItemDetailEnhanced(item: item, canvasView: $canvasView)
                .environmentObject(coordinator)
                .id(item.id)
        } else {
            ContentUnavailableView(
                "Select an Item",
                systemImage: "square.grid.2x2",
                description: Text("Choose an item to view details")
            )
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // New window button (disabled - MultiWindowCoordinator not available)
            // Button(action: {
            //     MultiWindowCoordinator.shared.createNewWindow(for: selectedDetailItem)
            // }) {
            //     Image(systemName: "square.split.2x1")
            //         .help("Open in New Window")
            // }
            // .keyboardShortcut("n", modifiers: [.command, .shift])
            
            // Slide over toggle
            Button(action: {
                isSlideOverVisible.toggle()
            }) {
                Image(systemName: "sidebar.right")
                    .symbolVariant(isSlideOverVisible ? .fill : .none)
                    .help("Toggle Slide Over")
            }
            .keyboardShortcut("\\", modifiers: .command)
            
            // Quick scanner
            Menu {
                Button(action: {
                    slideOverContent = .scanner
                    isSlideOverVisible = true
                }) {
                    Label("Barcode Scanner", systemImage: "barcode.viewfinder")
                }
                
                Button(action: {
                    slideOverContent = .receiptScanner
                    isSlideOverVisible = true
                }) {
                    Label("Receipt Scanner", systemImage: "doc.text.viewfinder")
                }
                
                Button(action: {
                    slideOverContent = .pencilNote
                    isSlideOverVisible = true
                }) {
                    Label("Quick Note", systemImage: "pencil.tip")
                }
            } label: {
                Image(systemName: "plus.circle")
                    .help("Quick Actions")
            }
        }
    }
    
    // MARK: - Configuration
    
    private func configureiPadFeatures() {
        // Enable enhanced pointer interactions
        UIApplication.shared.windows.first?.interactions.forEach { interaction in
            if interaction is UIPointerInteraction {
                // Already configured
            }
        }
        
        // Configure for pencil support
        // Note: supportsMultipleScenes is read-only, configuration is done in Info.plist
        // if #available(iOS 14.0, *) {
        //     UIApplication.shared.supportsMultipleScenes = true
        // }
    }
}

// MARK: - Navigation Button

struct NavigationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Items List Content

struct ItemsListContent: View {
    @Binding var selectedItem: Item?
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var items: [Item] = []
    
    var body: some View {
        List {
            ForEach(items) { item in
                EnhancedItemRow(item: item)
                    .onTapGesture {
                        selectedItem = item
                    }
                    .contextMenu {
                        contextMenuItems(for: item)
                    }
            }
        }
        .navigationTitle("Items")
        .onAppear {
            loadItems()
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for item: Item) -> some View {
        // Button(action: {
        //     MultiWindowCoordinator.shared.createNewWindow(for: item)
        // }) {
        //     Label("Open in New Window", systemImage: "square.split.2x1")
        // }
        
        Divider()
        
        Button(action: {
            // Duplicate item
        }) {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        
        Button(action: {
            // Share item
        }) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            // Delete item
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func loadItems() {
        // Load items from repository
        Task {
                // TODO: Load items from data source
                items = []
        }
    }
}

// MARK: - Item Row

struct EnhancedItemRow: View {
    let item: Item
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if let description = item.notes {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let price = item.purchasePrice {
                    Text("$\(price)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                if let purchaseDate = item.purchaseDate {
                    Text(purchaseDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Enhanced Item Detail

struct ItemDetailEnhanced: View {
    let item: Item
    @Binding var canvasView: PKCanvasView
    @State private var showAnnotation = false
    @State private var annotations: [UIImage] = []
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Item header
                ItemDetailHeader(item: item)
                
                // Photos with annotation support
                if !item.imageIds.isEmpty {
                    PhotoGalleryWithAnnotations(
                        photoIds: item.imageIds,
                        annotations: annotations,
                        onAnnotate: { photoId in
                            showAnnotation = true
                        }
                    )
                }
                
                // Item details
                ItemDetailContent(item: item)
                
                // Documents (disabled - documentIds property not available)
                // if !item.documentIds.isEmpty {
                //     DocumentSection(documentIds: item.documentIds)
                // }
                
                // Warranty info (disabled - warranty property needs to be loaded separately)
                // if let warrantyId = item.warrantyId {
                //     WarrantySection(warranty: warranty)
                // }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAnnotation) {
            PencilAnnotationSheet(
                item: item,
                canvasView: $canvasView,
                annotations: $annotations
            )
        }
    }
}

// MARK: - Slide Over Content Types

enum SlideOverContent {
    case scanner
    case receiptScanner
    case pencilNote
    case quickAdd
}

// MARK: - Slide Over Panel

struct SlideOverPanel: View {
    let content: SlideOverContent
    let coordinator: AppCoordinator
    @Binding var isVisible: Bool
    
    @State private var panelWidth: CGFloat = 400
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            handleBar
            
            // Content
            slideOverContentView
                .frame(maxHeight: .infinity)
        }
        .frame(width: panelWidth + dragOffset)
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.15), radius: 10, x: -5, y: 0)
        .overlay(alignment: .leading) {
            resizeHandle
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(-150, min(150, value.translation.width))
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        panelWidth += dragOffset
                        panelWidth = max(300, min(600, panelWidth))
                        dragOffset = 0
                    }
                }
        )
    }
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 40, height: 5)
            .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var slideOverContentView: some View {
        NavigationStack {
            switch content {
            case .scanner:
                coordinator.scannerModule.makeScannerView()
            case .receiptScanner:
                coordinator.receiptsModule.makeReceiptImportView { receipt in
                    // Handle imported receipt
                    isVisible = false
                }
            case .pencilNote:
                QuickNoteView()
            case .quickAdd:
                coordinator.itemsModule.makeAddItemView { _ in
                    isVisible = false
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isVisible = false
                }
            }
        }
    }
    
    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10)
            .contentShape(Rectangle())
            .onHover { hovering in
                // Resize cursor is handled automatically on iOS
            }
    }
}

// MARK: - Supporting Types

enum InventorySection: CaseIterable {
    case items, insurance, locations, categories
    
    var title: String {
        switch self {
        case .items: return "Items"
        case .insurance: return "Insurance"
        case .locations: return "Locations"
        case .categories: return "Categories"
        }
    }
    
    var icon: String {
        switch self {
        case .items: return "shippingbox.fill"
        case .insurance: return "shield.fill"
        case .locations: return "location.fill"
        case .categories: return "square.grid.2x2.fill"
        }
    }
    
    var tab: IPadTab {
        switch self {
        case .items: return .items
        case .insurance: return .insurance
        case .locations: return .locations
        case .categories: return .categories
        }
    }
}

enum InsightsSection: CaseIterable {
    case analytics, reports, budget
    
    var title: String {
        switch self {
        case .analytics: return "Analytics"
        case .reports: return "Reports"
        case .budget: return "Budget"
        }
    }
    
    var icon: String {
        switch self {
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .reports: return "doc.text.fill"
        case .budget: return "dollarsign.circle.fill"
        }
    }
    
    var tab: IPadTab {
        switch self {
        case .analytics: return .analytics
        case .reports: return .reports
        case .budget: return .budget
        }
    }
}

enum ToolsSection: CaseIterable {
    case scanner, search, importExport
    
    var title: String {
        switch self {
        case .scanner: return "Scanner"
        case .search: return "Search"
        case .importExport: return "Import/Export"
        }
    }
    
    var icon: String {
        switch self {
        case .scanner: return "barcode.viewfinder"
        case .search: return "magnifyingglass"
        case .importExport: return "square.and.arrow.up.on.square.fill"
        }
    }
    
    var tab: IPadTab {
        switch self {
        case .scanner: return .scanner
        case .search: return .search
        case .importExport: return .importExport
        }
    }
}

// MARK: - Drag and Drop Support

struct ItemDragPreview: View {
    let item: Item
    
    var body: some View {
        VStack {
            Image(systemName: "shippingbox.fill")
                .font(.largeTitle)
            Text(item.name)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ItemDropDelegate: DropDelegate {
    @Binding var selectedItem: Item?
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle drop
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.text])
    }
}

// MARK: - Helper Views

struct ItemDetailHeader: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.largeTitle)
                .bold()
            
            if let description = item.notes {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let price = item.purchasePrice {
                    Label("$\(price)", systemImage: "dollarsign.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if let purchaseDate = item.purchaseDate {
                    Label {
                        Text(purchaseDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ItemDetailContent: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let brand = item.brand {
                EnhancedDetailRow(label: "Brand", value: brand)
            }
            
            if let model = item.model {
                EnhancedDetailRow(label: "Model", value: model)
            }
            
            if let serialNumber = item.serialNumber {
                EnhancedDetailRow(label: "Serial Number", value: serialNumber)
            }
            
            if let storeName = item.storeName {
                EnhancedDetailRow(label: "Store", value: storeName)
            }
        }
    }
}

struct EnhancedDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct DocumentSection: View {
    let documentIds: [UUID]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Documents")
                .font(.headline)
            
            // Document list would go here
        }
    }
}

struct WarrantySection: View {
    let warranty: Warranty
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Warranty")
                .font(.headline)
            
            EnhancedDetailRow(label: "Expires", value: warranty.endDate.formatted())
            EnhancedDetailRow(label: "Provider", value: warranty.provider ?? "Unknown")
        }
    }
}

struct PhotoGalleryWithAnnotations: View {
    let photoIds: [UUID]
    let annotations: [UIImage]
    let onAnnotate: (UUID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(photoIds, id: \.self) { photoId in
                    VStack {
                        Image(uiImage: UIImage()) // Placeholder
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(10)
                            .overlay(alignment: .topTrailing) {
                                if annotations.contains(where: { _ in true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                        .padding(8)
                                }
                            }
                            .onTapGesture {
                                onAnnotate(photoId)
                            }
                    }
                }
            }
        }
    }
}

struct PencilAnnotationSheet: View {
    let item: Item
    @Binding var canvasView: PKCanvasView
    @Binding var annotations: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @State private var isToolPickerVisible = true
    
    var body: some View {
        NavigationStack {
            SimplePencilDrawingView(
                canvasView: $canvasView,
                isToolPickerVisible: isToolPickerVisible,
                onDrawingChanged: { drawing in
                    let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
                    annotations.append(image)
                }
            )
            .navigationTitle("Annotate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
    }
}

// MARK: - Pencil Drawing View (Simplified)

struct SimplePencilDrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let isToolPickerVisible: Bool
    let onDrawingChanged: (PKDrawing) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .systemBackground
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let window = uiView.window {
            let toolPicker = PKToolPicker.shared(for: window)
            toolPicker?.setVisible(isToolPickerVisible, forFirstResponder: canvasView)
            if isToolPickerVisible {
                toolPicker?.addObserver(canvasView)
                canvasView.becomeFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: (PKDrawing) -> Void
        
        init(onDrawingChanged: @escaping (PKDrawing) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged(canvasView.drawing)
        }
    }
}

struct QuickNoteView: View {
    @State private var noteText = ""
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        VStack {
            TextEditor(text: $noteText)
                .frame(height: 150)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
            
            SimplePencilDrawingView(
                canvasView: $canvasView,
                isToolPickerVisible: true,
                onDrawingChanged: { _ in
                    // Handle drawing changes
                }
            )
        }
        .navigationTitle("Quick Note")
    }
}
