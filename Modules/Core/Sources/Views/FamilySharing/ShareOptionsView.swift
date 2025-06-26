//
//  ShareOptionsView.swift
//  Core
//
//  View for displaying options to join an existing family share
//

import SwiftUI
import CloudKit

@available(iOS 15.0, *)
public struct ShareOptionsView: View {
    @ObservedObject var sharingService: FamilySharingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var invitationCode = ""
    @State private var isJoining = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var shareMetadata: CKShare.Metadata?
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Join a Family")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter an invitation code or accept an invitation from Messages or Email")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Invitation Code Entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invitation Code")
                        .font(.headline)
                    
                    TextField("Enter code", text: $invitationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Ask a family member to send you an invitation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: joinWithCode) {
                        Text("Join Family")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(invitationCode.isEmpty || isJoining)
                    
                    Text("Or")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        HowToJoinRow(
                            icon: "message.fill",
                            color: .green,
                            title: "From Messages",
                            description: "Tap the invitation link in Messages"
                        )
                        
                        HowToJoinRow(
                            icon: "envelope.fill",
                            color: .blue,
                            title: "From Email",
                            description: "Click the invitation link in your email"
                        )
                        
                        HowToJoinRow(
                            icon: "link",
                            color: .orange,
                            title: "From Link",
                            description: "Open the shared link in Safari"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isJoining {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Joining family...")
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
            .onOpenURL { url in
                handleShareURL(url)
            }
        }
    }
    
    // MARK: - Actions
    
    private func joinWithCode() {
        guard !invitationCode.isEmpty else { return }
        
        isJoining = true
        
        // In real implementation, would validate code and fetch share metadata
        // For now, simulate the process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isJoining = false
            
            // Simulate success/failure
            if invitationCode.count >= 6 {
                // Success - would normally use real share metadata
                dismiss()
            } else {
                errorMessage = "Invalid invitation code. Please check and try again."
                showingError = true
            }
        }
    }
    
    private func handleShareURL(_ url: URL) {
        // Parse CloudKit share URL
        guard url.scheme == "https",
              url.host == "www.icloud.com",
              url.pathComponents.contains("share") else {
            return
        }
        
        isJoining = true
        
        // Fetch share metadata
        let container = CKContainer.default()
        container.fetchShareMetadata(with: url) { metadata, error in
            DispatchQueue.main.async {
                if let metadata = metadata {
                    self.shareMetadata = metadata
                    self.acceptShare(metadata)
                } else if let error = error {
                    self.isJoining = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func acceptShare(_ metadata: CKShare.Metadata) {
        sharingService.joinFamilyShare(shareMetadata: metadata) { result in
            DispatchQueue.main.async {
                isJoining = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - How to Join Row

private struct HowToJoinRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}