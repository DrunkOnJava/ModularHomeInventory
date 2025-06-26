//
//  FamilySharingView.swift
//  Core
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
//  Module: Core
//  Dependencies: SwiftUI, CloudKit
//  Testing: CoreTests/FamilySharingViewTests.swift
//
//  Description: Main view for managing family sharing settings and members with invitation management and real-time sync
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import CloudKit

@available(iOS 15.0, *)
public struct FamilySharingView: View {
    @StateObject private var sharingService = FamilySharingService()
    @State private var showingInviteSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingShareOptions = false
    @State private var selectedMember: FamilySharingService.FamilyMember?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                if sharingService.isSharing {
                    familySharingContent
                } else {
                    notSharingContent
                }
                
                if sharingService.syncStatus == .syncing {
                    ProgressView("Syncing...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .navigationTitle("Family Sharing")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if sharingService.isSharing {
                        Menu {
                            Button(action: { showingInviteSheet = true }) {
                                Label("Invite Member", systemImage: "person.badge.plus")
                            }
                            
                            Button(action: { showingSettingsSheet = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: stopSharing) {
                                Label("Stop Sharing", systemImage: "xmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteMemberView(sharingService: sharingService)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                FamilySharingSettingsView(sharingService: sharingService)
            }
            .sheet(item: $selectedMember) { member in
                MemberDetailView(member: member, sharingService: sharingService)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Not Sharing Content
    
    private var notSharingContent: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Share Your Inventory")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Collaborate with family members to manage your home inventory together")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "checkmark.shield",
                    title: "Secure Sharing",
                    description: "Your data is encrypted and only shared with invited family members"
                )
                
                FeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Real-time Sync",
                    description: "Changes sync instantly across all family devices"
                )
                
                FeatureRow(
                    icon: "person.2",
                    title: "Role Management",
                    description: "Control who can view, edit, or manage items"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: createNewFamily) {
                    Text("Create Family Group")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: { showingShareOptions = true }) {
                    Text("Join Existing Family")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .sheet(isPresented: $showingShareOptions) {
            ShareOptionsView(sharingService: sharingService)
        }
    }
    
    // MARK: - Family Sharing Content
    
    private var familySharingContent: some View {
        List {
            // Family Overview
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Family Members")
                            .font(.headline)
                        Text("\(sharingService.familyMembers.count) members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if case .owner = sharingService.shareStatus {
                        Button(action: { showingInviteSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Family Members
            Section("Members") {
                ForEach(sharingService.familyMembers) { member in
                    MemberRow(member: member) {
                        selectedMember = member
                    }
                }
            }
            
            // Pending Invitations
            if !sharingService.pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(sharingService.pendingInvitations) { invitation in
                        InvitationRow(invitation: invitation, sharingService: sharingService)
                    }
                }
            }
            
            // Shared Items Summary
            Section("Shared Items") {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("\(sharingService.sharedItems.count) items shared")
                            .font(.headline)
                        Text("Last synced: \(lastSyncTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { sharingService.syncSharedItems() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(sharingService.syncStatus == .syncing)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewFamily() {
        sharingService.createFamilyShare(name: "My Family") { result in
            switch result {
            case .success:
                // Family created
                break
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func stopSharing() {
        // Show confirmation alert
        // In real implementation, would handle stopping family sharing
    }
    
    private var lastSyncTime: String {
        if case .syncing = sharingService.syncStatus {
            return "Syncing..."
        }
        
        // In real implementation, would track last sync time
        return "Just now"
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let member: FamilySharingService.FamilyMember
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(member.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.headline)
                    HStack {
                        Text(member.role.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let email = member.email {
                            Text("• \(email)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Invitation Row

private struct InvitationRow: View {
    let invitation: FamilySharingService.Invitation
    let sharingService: FamilySharingService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(invitation.recipientEmail)
                    .font(.headline)
                HStack {
                    Text(invitation.role.rawValue)
                        .font(.caption)
                    Text("• Expires \(invitation.expirationDate, style: .relative)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: resendInvitation) {
                Text("Resend")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func resendInvitation() {
        // Resend invitation logic
    }
}