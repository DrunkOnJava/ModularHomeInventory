import SwiftUI
import Core

/// View that displays network connection status
/// Swift 5.9 - No Swift 6 features
public struct OfflineIndicator: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showDetails = false
    
    public init() {}
    
    public var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                
                Text("Offline Mode")
                    .textStyle(.labelMedium)
                
                Spacer()
                
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.warning)
            .cornerRadius(AppCornerRadius.small)
            .shadow(radius: 2)
            .padding(.horizontal, AppSpacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
            
            if showDetails {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("You're currently offline")
                        .textStyle(.bodyMedium)
                    
                    Text("• Changes will be saved locally")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("• Data will sync when connection returns")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.small)
                .padding(.horizontal, AppSpacing.md)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

/// View modifier to add offline indicator to any view
public struct OfflineAwareModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    public func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineIndicator()
                .animation(.spring(), value: networkMonitor.isConnected)
            
            content
        }
    }
}

public extension View {
    /// Adds offline indicator to the view
    func withOfflineIndicator() -> some View {
        modifier(OfflineAwareModifier())
    }
}

/// Sync status view - simplified version
public struct SyncStatusView: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var lastSyncDate: Date?
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Connection Status
            HStack {
                Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                    .foregroundStyle(networkMonitor.isConnected ? AppColors.success : AppColors.error)
                
                VStack(alignment: .leading) {
                    Text(networkMonitor.isConnected ? "Connected" : "Offline")
                        .textStyle(.bodyMedium)
                    
                    if networkMonitor.isConnected {
                        Text(networkMonitor.connectionType.displayName)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if networkMonitor.isConnected && networkMonitor.isExpensive {
                    Label("Cellular", systemImage: "antenna.radiowaves.left.and.right")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.warning)
                }
            }
            
            Divider()
            
            // Sync Status
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
                
                VStack(alignment: .leading) {
                    Text("All data synced")
                        .textStyle(.bodyMedium)
                    
                    if let lastSync = lastSyncDate {
                        Text("Last sync: \(lastSync, style: .relative) ago")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button("Sync Now") {
                    // Simplified - just update the date
                    lastSyncDate = Date()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!networkMonitor.isConnected)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
        .onAppear {
            lastSyncDate = Date()
        }
    }
}

/// Offline data management view - simplified version
public struct OfflineDataView: View {
    @State private var dataSize: String = "0 MB"
    @State private var showingClearAlert = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Offline Data")
                    .textStyle(.headlineMedium)
                
                Text("Manage data stored for offline access")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            // Storage Info
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading) {
                    Text("Storage Used")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(dataSize)
                        .textStyle(.bodyLarge)
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
            
            // Clear Data Button
            Button(action: { showingClearAlert = true }) {
                Label("Clear Offline Data", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.error)
            
            // Info
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Offline data includes:", systemImage: "info.circle")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                ForEach([
                    "Cached items and photos",
                    "Pending changes waiting to sync",
                    "Temporary data for offline access"
                ], id: \.self) { info in
                    HStack {
                        Text("•")
                        Text(info)
                    }
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.leading, AppSpacing.md)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .alert("Clear Offline Data?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                // Simplified - just reset the size
                dataSize = "0 MB"
            }
        } message: {
            Text("This will remove all cached data. Any unsynced changes will be lost.")
        }
    }
}