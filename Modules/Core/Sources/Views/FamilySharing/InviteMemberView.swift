//
//  InviteMemberView.swift
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
//  Dependencies: SwiftUI, MessageUI
//  Testing: CoreTests/InviteMemberViewTests.swift
//
//  Description: View for inviting new family members with role selection and multiple invitation methods
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import MessageUI

@available(iOS 15.0, *)
public struct InviteMemberView: View {
    @ObservedObject var sharingService: FamilySharingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var name = ""
    @State private var selectedRole: FamilySharingService.FamilyMember.MemberRole = .member
    @State private var showingMailComposer = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isInviting = false
    
    public var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    TextField("Name (Optional)", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("Recipient Information")
                }
                
                Section {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(FamilySharingService.FamilyMember.MemberRole.allCases.filter { $0 != .owner }, id: \.self) { role in
                            HStack {
                                Text(role.rawValue)
                                Spacer()
                                Image(systemName: roleIcon(for: role))
                                    .foregroundColor(.secondary)
                            }
                            .tag(role)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                } header: {
                    Text("Permissions")
                } footer: {
                    Text(roleDescription(for: selectedRole))
                        .font(.caption)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionRow(
                            permission: .read,
                            isEnabled: selectedRole.permissions.contains(.read)
                        )
                        
                        PermissionRow(
                            permission: .write,
                            isEnabled: selectedRole.permissions.contains(.write)
                        )
                        
                        PermissionRow(
                            permission: .delete,
                            isEnabled: selectedRole.permissions.contains(.delete)
                        )
                        
                        if selectedRole == .admin {
                            PermissionRow(
                                permission: .invite,
                                isEnabled: selectedRole.permissions.contains(.invite)
                            )
                        }
                    }
                } header: {
                    Text("Role Permissions")
                }
                
                Section {
                    VStack(spacing: 16) {
                        // Send via Messages
                        Button(action: sendViaMessages) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.green)
                                Text("Send via Messages")
                                Spacer()
                            }
                        }
                        .disabled(!canSendInvitation)
                        
                        // Send via Email
                        Button(action: sendViaEmail) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("Send via Email")
                                Spacer()
                            }
                        }
                        .disabled(!canSendInvitation || !MFMailComposeViewController.canSendMail())
                        
                        // Copy Link
                        Button(action: copyInvitationLink) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.orange)
                                Text("Copy Invitation Link")
                                Spacer()
                            }
                        }
                        .disabled(!canSendInvitation)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Send Invitation")
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Invite") {
                        sendInvitation()
                    }
                    .disabled(!canSendInvitation || isInviting)
                }
            }
            .disabled(isInviting)
            .overlay {
                if isInviting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Sending invitation...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    subject: "Join my Home Inventory Family",
                    recipients: [email],
                    body: invitationEmailBody()
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSendInvitation: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".")
    }
    
    // MARK: - Actions
    
    private func sendInvitation() {
        isInviting = true
        
        sharingService.inviteMember(
            email: email,
            name: name.isEmpty ? nil : name,
            role: selectedRole
        ) { result in
            isInviting = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendViaMessages() {
        // In real implementation, would open Messages with invitation
        sendInvitation()
    }
    
    private func sendViaEmail() {
        showingMailComposer = true
    }
    
    private func copyInvitationLink() {
        // Generate and copy invitation link
        let invitationLink = "https://homeinventory.app/join/\(UUID().uuidString)"
        UIPasteboard.general.string = invitationLink
        
        // Show confirmation
        // In real app, would show a toast or alert
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
    
    private func roleDescription(for role: FamilySharingService.FamilyMember.MemberRole) -> String {
        switch role {
        case .owner:
            return "Full control over the family inventory and all settings"
        case .admin:
            return "Can add, edit, and delete items, plus invite new members"
        case .member:
            return "Can add and edit items, but cannot delete or invite others"
        case .viewer:
            return "Can only view items, cannot make any changes"
        }
    }
    
    private func invitationEmailBody() -> String {
        """
        Hi\(name.isEmpty ? "" : " \(name)"),
        
        You've been invited to join my Home Inventory family as a \(selectedRole.rawValue).
        
        With Home Inventory, we can:
        • Track all our household items together
        • Get warranty expiration reminders
        • See who added or updated items
        • Access the inventory from any device
        
        Click the link below to join:
        https://homeinventory.app/join/[invitation-id]
        
        This invitation expires in 7 days.
        
        Best regards,
        \(getUserName())
        """
    }
    
    private func getUserName() -> String {
        // In real implementation, would get from user profile
        return "Your Family Member"
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let permission: FamilySharingService.Permission
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: permissionIcon)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Text(permissionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var permissionIcon: String {
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
    
    private var permissionDescription: String {
        switch permission {
        case .read:
            return "View all shared items"
        case .write:
            return "Add and edit items"
        case .delete:
            return "Remove items"
        case .invite:
            return "Invite new members"
        case .manage:
            return "Manage family settings"
        }
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        composer.setMessageBody(body, isHTML: false)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}