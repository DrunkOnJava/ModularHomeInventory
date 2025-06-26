//
//  MemberDetailView.swift
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
//  Dependencies: SwiftUI
//  Testing: CoreTests/MemberDetailViewTests.swift
//
//  Description: View for displaying and managing family member details with role management and activity tracking
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct MemberDetailView: View {
    let member: FamilySharingService.FamilyMember
    @ObservedObject var sharingService: FamilySharingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingRoleChangeSheet = false
    @State private var showingRemoveConfirmation = false
    @State private var showingActivityHistory = false
    @State private var isUpdating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isOwner: Bool {
        if case .owner = sharingService.shareStatus {
            return true
        }
        return false
    }
    
    private var canEditMember: Bool {
        isOwner && member.role != .owner
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Member Header
                    memberHeader
                    
                    // Member Info
                    memberInfoSection
                    
                    // Permissions
                    permissionsSection
                    
                    // Activity
                    activitySection
                    
                    // Actions
                    if canEditMember {
                        actionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRoleChangeSheet) {
                RoleChangeView(
                    member: member,
                    currentRole: member.role,
                    sharingService: sharingService
                )
            }
            .confirmationDialog(
                "Remove Member",
                isPresented: $showingRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove from Family", role: .destructive) {
                    removeMember()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \(member.name) from the family? They will lose access to all shared items.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isUpdating)
            .overlay {
                if isUpdating {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Member Header
    
    private var memberHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let avatarData = member.avatarData,
                   let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Text(member.name.prefix(2).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let email = member.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Role Badge
            Label(member.role.rawValue, systemImage: roleIcon(for: member.role))
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(roleColor(for: member.role).opacity(0.2))
                .foregroundColor(roleColor(for: member.role))
                .cornerRadius(20)
        }
    }
    
    // MARK: - Member Info Section
    
    private var memberInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Member Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                MemberInfoRow(
                    label: "Joined",
                    value: member.joinedDate.formatted(date: .abbreviated, time: .omitted)
                )
                
                MemberInfoRow(
                    label: "Last Active",
                    value: member.lastActiveDate.formatted(.relative(presentation: .named))
                )
                
                if canEditMember {
                    Button(action: { showingRoleChangeSheet = true }) {
                        HStack {
                            Text("Role")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(member.role.rawValue)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permissions")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(FamilySharingService.Permission.allCases, id: \.self) { permission in
                    HStack {
                        Image(systemName: permissionIcon(for: permission))
                            .foregroundColor(member.role.permissions.contains(permission) ? .green : .gray)
                            .frame(width: 24)
                        
                        Text(permission.rawValue)
                            .foregroundColor(member.role.permissions.contains(permission) ? .primary : .secondary)
                        
                        Spacer()
                        
                        if member.role.permissions.contains(permission) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingActivityHistory = true }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                // Mock activity items
                ActivityRow(
                    icon: "plus.circle",
                    action: "Added iPhone 15 Pro",
                    time: "2 hours ago"
                )
                
                ActivityRow(
                    icon: "pencil.circle",
                    action: "Updated Office Chair",
                    time: "Yesterday"
                )
                
                ActivityRow(
                    icon: "camera.circle",
                    action: "Added photos to MacBook Pro",
                    time: "3 days ago"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingRemoveConfirmation = true }) {
                HStack {
                    Image(systemName: "person.badge.minus")
                    Text("Remove from Family")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Actions
    
    private func removeMember() {
        isUpdating = true
        
        sharingService.removeMember(member) { result in
            isUpdating = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func roleIcon(for role: FamilySharingService.FamilyMember.MemberRole) -> String {
        switch role {
        case .owner:
            return "crown.fill"
        case .admin:
            return "star.fill"
        case .member:
            return "person.fill"
        case .viewer:
            return "eye.fill"
        }
    }
    
    private func roleColor(for role: FamilySharingService.FamilyMember.MemberRole) -> Color {
        switch role {
        case .owner:
            return .purple
        case .admin:
            return .orange
        case .member:
            return .blue
        case .viewer:
            return .gray
        }
    }
    
    private func permissionIcon(for permission: FamilySharingService.Permission) -> String {
        switch permission {
        case .read:
            return "eye"
        case .write:
            return "pencil"
        case .delete:
            return "trash"
        case .invite:
            return "person.badge.plus"
        case .manage:
            return "gearshape"
        }
    }
}

// MARK: - Info Row

private struct MemberInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let icon: String
    let action: String
    let time: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action)
                    .font(.subheadline)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Role Change View

@available(iOS 15.0, *)
struct RoleChangeView: View {
    let member: FamilySharingService.FamilyMember
    let currentRole: FamilySharingService.FamilyMember.MemberRole
    @ObservedObject var sharingService: FamilySharingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRole: FamilySharingService.FamilyMember.MemberRole
    @State private var isUpdating = false
    
    init(member: FamilySharingService.FamilyMember, currentRole: FamilySharingService.FamilyMember.MemberRole, sharingService: FamilySharingService) {
        self.member = member
        self.currentRole = currentRole
        self.sharingService = sharingService
        self._selectedRole = State(initialValue: currentRole)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(FamilySharingService.FamilyMember.MemberRole.allCases.filter { $0 != .owner }, id: \.self) { role in
                        Button(action: { selectedRole = role }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.rawValue)
                                        .foregroundColor(.primary)
                                    Text(roleDescription(for: role))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select New Role")
                }
            }
            .navigationTitle("Change Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateRole()
                    }
                    .disabled(selectedRole == currentRole || isUpdating)
                }
            }
            .disabled(isUpdating)
        }
    }
    
    private func updateRole() {
        isUpdating = true
        
        // In real implementation, would update role via service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isUpdating = false
            dismiss()
        }
    }
    
    private func roleDescription(for role: FamilySharingService.FamilyMember.MemberRole) -> String {
        switch role {
        case .owner:
            return "Full control over the family inventory"
        case .admin:
            return "Can manage items and invite members"
        case .member:
            return "Can add and edit items"
        case .viewer:
            return "Can only view items"
        }
    }
}