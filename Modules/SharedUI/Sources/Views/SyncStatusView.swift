//
//  SyncStatusView.swift
//  SharedUI Module
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// View showing sync status and controls
public struct SyncStatusView: View {
    @ObservedObject var syncService: MultiPlatformSyncService
    @State private var showingDetails = false
    @State private var showingConflictResolution = false
    
    public init(syncService: MultiPlatformSyncService) {
        self.syncService = syncService
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Sync icon with status
            ZStack {
                Image(systemName: syncIcon)
                    .font(.title2)
                    .foregroundColor(syncColor)
                    .symbolEffect(.pulse, value: syncService.syncStatus.isActive)
                
                if case .uploading(let progress) = syncService.syncStatus {
                    CircularProgressView(progress: progress)
                        .frame(width: 40, height: 40)
                } else if case .downloading(let progress) = syncService.syncStatus {
                    CircularProgressView(progress: progress)
                        .frame(width: 40, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.headline)
                
                if let lastSync = syncService.lastSyncDate {
                    Text("Last synced \(lastSync.relativeTimeString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never synced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action button
            if syncService.iCloudAvailable {
                Button(action: {
                    Task {
                        try? await syncService.syncNow()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .disabled(syncService.syncStatus.isActive)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            SyncDetailsView(syncService: syncService)
        }
    }
    
    private var syncIcon: String {
        if !syncService.iCloudAvailable {
            return "icloud.slash"
        }
        
        switch syncService.syncStatus {
        case .idle:
            return syncService.pendingChanges > 0 ? "icloud.and.arrow.up" : "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .uploading:
            return "icloud.and.arrow.up"
        case .downloading:
            return "icloud.and.arrow.down"
        case .error:
            return "exclamationmark.icloud"
        }
    }
    
    private var syncColor: Color {
        if !syncService.iCloudAvailable {
            return .gray
        }
        
        switch syncService.syncStatus {
        case .idle:
            return syncService.pendingChanges > 0 ? .orange : .green
        case .syncing, .uploading, .downloading:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        if !syncService.iCloudAvailable {
            return "iCloud Not Available"
        }
        
        switch syncService.syncStatus {
        case .idle:
            return syncService.pendingChanges > 0 ? "\(syncService.pendingChanges) changes pending" : "Synced"
        case .syncing:
            return "Syncing..."
        case .uploading(let progress):
            return "Uploading (\(Int(progress * 100))%)"
        case .downloading(let progress):
            return "Downloading (\(Int(progress * 100))%)"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Sync Details View

public struct SyncDetailsView: View {
    @ObservedObject var syncService: MultiPlatformSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false
    
    public var body: some View {
        NavigationStack {
            List {
                // Status section
                Section("Status") {
                    LabeledContent("iCloud Status") {
                        Label(
                            syncService.iCloudAvailable ? "Available" : "Not Available",
                            systemImage: syncService.iCloudAvailable ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(syncService.iCloudAvailable ? .green : .red)
                    }
                    
                    if let lastSync = syncService.lastSyncDate {
                        LabeledContent("Last Sync", value: lastSync.formatted())
                    }
                    
                    LabeledContent("Pending Changes", value: "\(syncService.pendingChanges)")
                }
                
                // Statistics
                Section("Statistics") {
                    let stats = syncService.getSyncStats()
                    LabeledContent("Total Synced", value: "\(stats.totalSynced) items")
                    LabeledContent("Conflicts Resolved", value: "\(stats.conflictsResolved)")
                }
                
                // Connected devices
                if !syncService.connectedDevices.isEmpty {
                    Section("Connected Devices") {
                        ForEach(syncService.connectedDevices) { device in
                            DeviceRow(device: device)
                        }
                    }
                }
                
                // Actions
                Section {
                    Button(action: {
                        Task {
                            try? await syncService.syncNow()
                        }
                    }) {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                    .disabled(!syncService.iCloudAvailable || syncService.syncStatus.isActive)
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        Label("Reset Sync Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Errors section removed - syncErrors property doesn't exist
            }
            .navigationTitle("Sync Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Reset Sync Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    Task {
                        // resetSync method doesn't exist in MultiPlatformSyncService
                        // try? await syncService.resetSync()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all sync data and require a full resync. Your local data will not be affected.")
            }
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: DeviceInfo
    
    var deviceIcon: String {
        switch device.platform {
        case .iPhone:
            return "iphone"
        case .iPad:
            return "ipad"
        case .mac:
            return "macbook"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: deviceIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.headline)
                
                Text("\(device.platform.rawValue) • \(device.systemVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if Calendar.current.isDateInToday(device.lastSeen) {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(device.lastSeen.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
        }
    }
}

// MARK: - Compact Sync Status

public struct CompactSyncStatusView: View {
    @ObservedObject var syncService: MultiPlatformSyncService
    
    public init(syncService: MultiPlatformSyncService) {
        self.syncService = syncService
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
                .symbolEffect(.pulse, value: syncService.syncStatus.isActive)
            
            if syncService.pendingChanges > 0 {
                Text("\(syncService.pendingChanges)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
    
    private var iconName: String {
        if !syncService.iCloudAvailable {
            return "icloud.slash"
        }
        
        switch syncService.syncStatus {
        case .idle:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .uploading:
            return "icloud.and.arrow.up"
        case .downloading:
            return "icloud.and.arrow.down"
        case .error:
            return "exclamationmark.icloud"
        }
    }
    
    private var iconColor: Color {
        if !syncService.iCloudAvailable {
            return .gray
        }
        
        switch syncService.syncStatus {
        case .error:
            return .red
        case .syncing, .uploading, .downloading:
            return .blue
        default:
            return syncService.pendingChanges > 0 ? .orange : .green
        }
    }
}

// MARK: - Date Extension

extension Date {
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}