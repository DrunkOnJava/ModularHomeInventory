//
//  SyncSettingsView.swift
//  AppSettings Module
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Settings view for multi-platform sync configuration
public struct SyncSettingsView: View {
    @ObservedObject var syncService: MultiPlatformSyncService
    @State private var configuration: MultiPlatformSyncService.SyncConfiguration
    @State private var showingResetConfirmation = false
    @State private var showingSignInPrompt = false
    
    public init(syncService: MultiPlatformSyncService) {
        self.syncService = syncService
        self._configuration = State(initialValue: MultiPlatformSyncService.SyncConfiguration())
    }
    
    public var body: some View {
        List {
            // iCloud status
            Section {
                HStack {
                    Image(systemName: syncService.iCloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud.fill")
                        .font(.largeTitle)
                        .foregroundColor(syncService.iCloudAvailable ? .green : .red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(syncService.iCloudAvailable ? "iCloud Connected" : "iCloud Not Available")
                            .font(.headline)
                        
                        Text(syncService.iCloudAvailable ? 
                             "Your data syncs across all your devices" : 
                             "Sign in to iCloud to enable sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                if !syncService.iCloudAvailable {
                    Button(action: {
                        showingSignInPrompt = true
                    }) {
                        Label("Set Up iCloud", systemImage: "gear")
                    }
                }
            }
            
            // Sync status
            if syncService.iCloudAvailable {
                Section {
                    SyncStatusView(syncService: syncService)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            
            // Sync settings
            Section("Sync Settings") {
                Toggle("Automatic Sync", isOn: $configuration.automaticSync)
                    .onChange(of: configuration.automaticSync) { _ in
                        updateConfiguration()
                    }
                
                if configuration.automaticSync {
                    Picker("Sync Interval", selection: $configuration.syncInterval) {
                        Text("Every 5 minutes").tag(TimeInterval(300))
                        Text("Every 15 minutes").tag(TimeInterval(900))
                        Text("Every 30 minutes").tag(TimeInterval(1800))
                        Text("Every hour").tag(TimeInterval(3600))
                    }
                    .onChange(of: configuration.syncInterval) { _ in
                        updateConfiguration()
                    }
                }
                
                Toggle("Wi-Fi Only", isOn: $configuration.wifiOnlySync)
                    .onChange(of: configuration.wifiOnlySync) { _ in
                        updateConfiguration()
                    }
                
                Toggle("Sync on App Launch", isOn: $configuration.syncOnAppLaunch)
                    .onChange(of: configuration.syncOnAppLaunch) { _ in
                        updateConfiguration()
                    }
                
                Toggle("Sync on Background", isOn: $configuration.syncOnAppBackground)
                    .onChange(of: configuration.syncOnAppBackground) { _ in
                        updateConfiguration()
                    }
            }
            
            // Connected devices
            if !syncService.connectedDevices.isEmpty {
                Section("Connected Devices (\(syncService.connectedDevices.count))") {
                    ForEach(syncService.connectedDevices) { device in
                        ConnectedDeviceRow(device: device)
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
                    HStack {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                        Spacer()
                        if syncService.syncStatus.isActive {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(!syncService.iCloudAvailable || syncService.syncStatus.isActive)
                
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    Label("Reset Sync Data", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("About Multi-Platform Sync", systemImage: "info.circle")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text("• Syncs your inventory across iPhone, iPad, and Mac")
                        .font(.caption)
                    Text("• Uses iCloud for secure, private synchronization")
                        .font(.caption)
                    Text("• Automatically resolves conflicts between devices")
                        .font(.caption)
                    Text("• Works offline with automatic sync when connected")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Sync Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("iCloud Sign In Required", isPresented: $showingSignInPrompt) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please sign in to iCloud in Settings to enable sync across your devices.")
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
            Text("This will clear all sync metadata and require a full resync. Your local data will not be affected.")
        }
    }
    
    private func updateConfiguration() {
        syncService.configure(configuration)
    }
}

// MARK: - Connected Device Row

struct ConnectedDeviceRow: View {
    let device: DeviceInfo
    @State private var showingDetails = false
    
    var deviceIcon: String {
        switch device.platform {
        case .iPhone:
            return "iphone"
        case .iPad:
            return "ipad"
        case .mac:
            return "desktopcomputer"
        }
    }
    
    var isCurrentDevice: Bool {
        device.id == UIDevice.current.identifierForVendor?.uuidString
    }
    
    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack {
                Image(systemName: deviceIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(device.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isCurrentDevice {
                            Text("This Device")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(device.platform.rawValue) • iOS \(device.systemVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            DeviceDetailsView(device: device)
        }
    }
}

// MARK: - Device Details View

struct DeviceDetailsView: View {
    let device: DeviceInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Device Information") {
                    LabeledContent("Name", value: device.name)
                    LabeledContent("Platform", value: device.platform.rawValue)
                    LabeledContent("System Version", value: "iOS \(device.systemVersion)")
                    LabeledContent("Device ID") {
                        Text(device.id)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sync Activity") {
                    LabeledContent("Last Seen") {
                        VStack(alignment: .trailing) {
                            Text(device.lastSeen.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                            Text(device.lastSeen, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if Calendar.current.isDateInToday(device.lastSeen) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Active Today")
                        }
                    }
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}