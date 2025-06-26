//
//  ViewOnlyModifier.swift
//  Core
//
//  View modifier to enforce view-only mode restrictions
//

import SwiftUI

// MARK: - View Only Modifier

public struct ViewOnlyModifier: ViewModifier {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    let feature: ViewOnlyFeature
    let hiddenView: AnyView?
    
    public init(feature: ViewOnlyFeature, hiddenView: AnyView? = nil) {
        self.feature = feature
        self.hiddenView = hiddenView
    }
    
    public func body(content: Content) -> some View {
        if viewOnlyService.isViewOnlyMode && !viewOnlyService.isFeatureAllowed(feature) {
            if let hiddenView = hiddenView {
                hiddenView
            } else {
                EmptyView()
            }
        } else {
            content
        }
    }
}

// MARK: - View Only Overlay Modifier

public struct ViewOnlyOverlayModifier: ViewModifier {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if viewOnlyService.isViewOnlyMode {
                VStack {
                    HStack {
                        Label("View Only", systemImage: "eye")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Watermark if set
                    if !viewOnlyService.viewOnlySettings.watermarkText.isEmpty {
                        Text(viewOnlyService.viewOnlySettings.watermarkText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.gray.opacity(0.1))
                            .rotationEffect(.degrees(-45))
                            .allowsHitTesting(false)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Disabled In View Only Modifier

public struct DisabledInViewOnlyModifier: ViewModifier {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    let showAlert: Bool
    
    public init(showAlert: Bool = true) {
        self.showAlert = showAlert
    }
    
    @State private var showingAlert = false
    
    public func body(content: Content) -> some View {
        content
            .disabled(viewOnlyService.isViewOnlyMode)
            .opacity(viewOnlyService.isViewOnlyMode ? 0.5 : 1.0)
            .onTapGesture {
                if viewOnlyService.isViewOnlyMode && showAlert {
                    showingAlert = true
                }
            }
            .alert("View Only Mode", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text("This feature is not available in view-only mode")
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Hide or show content based on view-only mode and feature permissions
    func viewOnly(_ feature: ViewOnlyFeature, hiddenView: AnyView? = nil) -> some View {
        modifier(ViewOnlyModifier(feature: feature, hiddenView: hiddenView))
    }
    
    /// Add view-only mode overlay indicator
    func viewOnlyOverlay() -> some View {
        modifier(ViewOnlyOverlayModifier())
    }
    
    /// Disable interaction in view-only mode
    func disabledInViewOnly(showAlert: Bool = true) -> some View {
        modifier(DisabledInViewOnlyModifier(showAlert: showAlert))
    }
}

// MARK: - Conditional Content View

public struct ViewOnlyConditionalContent<TrueContent: View, FalseContent: View>: View {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    let feature: ViewOnlyFeature
    let trueContent: () -> TrueContent
    let falseContent: () -> FalseContent
    
    public init(
        feature: ViewOnlyFeature,
        @ViewBuilder trueContent: @escaping () -> TrueContent,
        @ViewBuilder falseContent: @escaping () -> FalseContent
    ) {
        self.feature = feature
        self.trueContent = trueContent
        self.falseContent = falseContent
    }
    
    public var body: some View {
        if viewOnlyService.isViewOnlyMode && !viewOnlyService.isFeatureAllowed(feature) {
            falseContent()
        } else {
            trueContent()
        }
    }
}

// MARK: - View Only Banner

public struct ViewOnlyBanner: View {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    
    public var body: some View {
        if viewOnlyService.isViewOnlyMode {
            HStack {
                Image(systemName: "eye")
                    .font(.subheadline)
                
                Text("View Only Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Editing Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 2),
                alignment: .bottom
            )
        }
    }
}

// MARK: - View Only Toolbar Item

public struct ViewOnlyToolbarItem: ToolbarContent {
    @ObservedObject private var viewOnlyService = ViewOnlyModeService.shared
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewOnlyService.isViewOnlyMode {
                Label("View Only", systemImage: "eye")
                    .font(.caption)
                    .labelStyle(.titleAndIcon)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Example Usage

struct ExampleItemDetailView: View {
    let item: Item
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Always visible
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Hidden in view-only if prices not allowed
                ViewOnlyConditionalContent(feature: .viewPrices) {
                    if let value = item.value {
                        Text("Value: \(value, format: .currency(code: "USD"))")
                            .font(.title2)
                    }
                } falseContent: {
                    Text("Price Hidden")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Edit button disabled in view-only
                Button("Edit Item") {
                    // Edit action
                }
                .disabledInViewOnly()
                
                // Serial number hidden if not allowed
                if let serial = item.serialNumber {
                    Text("Serial: \(serial)")
                        .viewOnly(.viewSerialNumbers)
                }
                
                // Notes with alternative content
                Text(item.notes ?? "No notes")
                    .viewOnly(.viewNotes, hiddenView: AnyView(
                        Text("Notes Hidden")
                            .foregroundColor(.secondary)
                    ))
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ViewOnlyToolbarItem()
        }
        .viewOnlyOverlay()
    }
}