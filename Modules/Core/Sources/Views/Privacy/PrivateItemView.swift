//
//  PrivateItemView.swift
//  Core
//
//  Views and modifiers for displaying private items
//

import SwiftUI

@available(iOS 15.0, *)
public struct PrivateItemView: View {
    let item: Item
    @StateObject private var privateModeService = PrivateModeService.shared
    @State private var showingAuthentication = false
    @State private var showingPrivacySettings = false
    
    private var isPrivate: Bool {
        privateModeService.isItemPrivate(item.id) ||
        privateModeService.shouldHideItem(category: item.category.rawValue, tags: item.tags)
    }
    
    private var privacySettings: PrivateModeService.PrivateItemSettings? {
        privateModeService.getPrivacySettings(for: item.id)
    }
    
    public var body: some View {
        if !privateModeService.isPrivateModeEnabled || !isPrivate || privateModeService.isAuthenticated {
            // Show normal item view
            ItemRowView(item: item)
        } else {
            // Show private item view
            PrivateItemRowView(
                item: item,
                privacySettings: privacySettings,
                onAuthenticate: {
                    showingAuthentication = true
                }
            )
            .sheet(isPresented: $showingAuthentication) {
                AuthenticationView()
            }
        }
    }
}

// MARK: - Private Item Row View

@available(iOS 15.0, *)
struct PrivateItemRowView: View {
    let item: Item
    let privacySettings: PrivateModeService.PrivateItemSettings?
    let onAuthenticate: () -> Void
    
    @StateObject private var privateModeService = PrivateModeService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if privateModeService.shouldBlurPhotos(for: item.id) {
                BlurredImageView()
                    .frame(width: 60, height: 60)
            } else if let firstImageId = item.imageIds.first {
                // Show actual image
                AsyncImage(url: URL(string: "image://\(firstImageId)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Name
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Category and brand
                HStack {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let brand = item.brand {
                        Text("• \(brand)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Value
                Text(privateModeService.getDisplayValue(for: item.purchasePrice, itemId: item.id))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Lock icon
            Button(action: onAuthenticate) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Blurred Image View

struct BlurredImageView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "photo.fill")
                .font(.title3)
                .foregroundColor(.gray.opacity(0.5))
            
            // Blur overlay
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Authentication View

@available(iOS 15.0, *)
struct AuthenticationView: View {
    @StateObject private var privateModeService = PrivateModeService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Title
                VStack(spacing: 8) {
                    Text("Private Items")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Authentication required to view")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Authenticate button
                Button(action: authenticate) {
                    HStack {
                        Image(systemName: "faceid")
                            .font(.title2)
                        
                        Text("Authenticate")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isAuthenticating)
                
                Spacer()
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Authentication Failed", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .interactiveDismissDisabled(isAuthenticating)
    }
    
    private func authenticate() {
        isAuthenticating = true
        
        Task {
            do {
                try await privateModeService.authenticate()
                dismiss()
            } catch {
                isAuthenticating = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Privacy Settings View

@available(iOS 15.0, *)
public struct ItemPrivacySettingsView: View {
    let item: Item
    @StateObject private var privateModeService = PrivateModeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var privacyLevel: PrivateModeService.PrivacyLevel
    @State private var hideValue = true
    @State private var hidePhotos = true
    @State private var hideLocation = true
    @State private var hideSerialNumber = true
    @State private var hidePurchaseInfo = true
    @State private var hideFromFamily = true
    @State private var customMessage = ""
    
    public init(item: Item) {
        self.item = item
        
        let settings = PrivateModeService.shared.getPrivacySettings(for: item.id)
        _privacyLevel = State(initialValue: settings?.privacyLevel ?? .none)
        _hideValue = State(initialValue: settings?.hideValue ?? true)
        _hidePhotos = State(initialValue: settings?.hidePhotos ?? true)
        _hideLocation = State(initialValue: settings?.hideLocation ?? true)
        _hideSerialNumber = State(initialValue: settings?.hideSerialNumber ?? true)
        _hidePurchaseInfo = State(initialValue: settings?.hidePurchaseInfo ?? true)
        _hideFromFamily = State(initialValue: settings?.hideFromFamily ?? true)
        _customMessage = State(initialValue: settings?.customMessage ?? "")
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Privacy Level
                Section {
                    Picker("Privacy Level", selection: $privacyLevel) {
                        ForEach(PrivateModeService.PrivacyLevel.allCases, id: \.self) { level in
                            Label(level.displayName, systemImage: level.icon)
                                .tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } footer: {
                    Text(privacyLevel.description)
                }
                
                if privacyLevel != .none {
                    // Custom Settings
                    Section {
                        Toggle("Hide Value", isOn: $hideValue)
                        Toggle("Hide Photos", isOn: $hidePhotos)
                        Toggle("Hide Location", isOn: $hideLocation)
                        Toggle("Hide Serial Number", isOn: $hideSerialNumber)
                        Toggle("Hide Purchase Info", isOn: $hidePurchaseInfo)
                        Toggle("Hide from Family Members", isOn: $hideFromFamily)
                    } header: {
                        Text("Custom Privacy Settings")
                    } footer: {
                        Text("Choose what information to hide for this item")
                    }
                    
                    // Custom Message
                    Section {
                        TextField("Custom message (optional)", text: $customMessage, axis: .vertical)
                            .lineLimit(2...4)
                    } header: {
                        Text("Custom Message")
                    } footer: {
                        Text("This message will be shown when someone tries to view this private item")
                    }
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        let settings = PrivateModeService.PrivateItemSettings(
            itemId: item.id,
            privacyLevel: privacyLevel,
            hideValue: hideValue,
            hidePhotos: hidePhotos,
            hideLocation: hideLocation,
            hideSerialNumber: hideSerialNumber,
            hidePurchaseInfo: hidePurchaseInfo,
            hideFromFamily: hideFromFamily,
            customMessage: customMessage.isEmpty ? nil : customMessage
        )
        
        privateModeService.updatePrivacySettings(settings)
        dismiss()
    }
}

// MARK: - View Modifiers

@available(iOS 15.0, *)
public struct PrivateValueModifier: ViewModifier {
    let itemId: UUID
    @StateObject private var privateModeService = PrivateModeService.shared
    
    public func body(content: Content) -> some View {
        if privateModeService.shouldHideValue(for: itemId) {
            Text("••••")
                .foregroundColor(.secondary)
        } else {
            content
        }
    }
}

@available(iOS 15.0, *)
public struct PrivateImageModifier: ViewModifier {
    let itemId: UUID
    @StateObject private var privateModeService = PrivateModeService.shared
    
    public func body(content: Content) -> some View {
        if privateModeService.shouldBlurPhotos(for: itemId) {
            content
                .blur(radius: 20)
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                )
        } else {
            content
        }
    }
}

// MARK: - View Extensions

public extension View {
    @available(iOS 15.0, *)
    func privateValue(for itemId: UUID) -> some View {
        modifier(PrivateValueModifier(itemId: itemId))
    }
    
    @available(iOS 15.0, *)
    func privateImage(for itemId: UUID) -> some View {
        modifier(PrivateImageModifier(itemId: itemId))
    }
}

// MARK: - Item Row View (Stub)

struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            // Thumbnail
            if let firstImageId = item.imageIds.first {
                AsyncImage(url: URL(string: "image://\(firstImageId)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let brand = item.brand {
                        Text("• \(brand)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let price = item.purchasePrice {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}