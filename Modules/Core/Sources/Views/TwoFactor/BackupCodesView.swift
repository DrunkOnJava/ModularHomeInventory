//
//  BackupCodesView.swift
//  Core
//
//  View for displaying and managing backup codes
//

import SwiftUI

@available(iOS 15.0, *)
public struct BackupCodesView: View {
    let codes: [String]
    @Environment(\.dismiss) private var dismiss
    
    @State private var copiedCode: String?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning banner
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Keep These Codes Safe")
                                .font(.headline)
                            
                            Text("Each code can only be used once. Store them securely.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Codes grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(codes.enumerated()), id: \.offset) { index, code in
                            BackupCodeCard(
                                number: index + 1,
                                code: code,
                                isCopied: copiedCode == code
                            ) {
                                copyCode(code)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        InstructionRow(
                            icon: "printer",
                            title: "Print these codes",
                            description: "Keep a physical copy in a secure location"
                        )
                        
                        InstructionRow(
                            icon: "lock.doc",
                            title: "Store securely",
                            description: "Save in a password manager or safe"
                        )
                        
                        InstructionRow(
                            icon: "xmark.circle",
                            title: "Don't share online",
                            description: "Never store in email or cloud notes"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: downloadCodes) {
                            Label("Download as Text File", systemImage: "arrow.down.doc")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: printCodes) {
                            Label("Print Codes", systemImage: "printer")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Backup Codes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        
        withAnimation {
            copiedCode = code
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedCode = nil
            }
        }
    }
    
    private func downloadCodes() {
        let content = generateTextContent()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("homeinventory_backup_codes.txt")
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            shareURL = tempURL
            showingShareSheet = true
        } catch {
            // Handle error
        }
    }
    
    private func printCodes() {
        let content = generateTextContent()
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Home Inventory Backup Codes"
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = content
        
        printController.present(animated: true)
    }
    
    private func generateTextContent() -> String {
        """
        Home Inventory - Two-Factor Authentication Backup Codes
        Generated: \(Date().formatted())
        
        IMPORTANT: Keep these codes in a safe place. Each code can only be used once.
        
        \(codes.enumerated().map { index, code in
            "\(String(format: "%02d", index + 1)). \(code)"
        }.joined(separator: "\n"))
        
        Instructions:
        - Store these codes securely (password manager, safe, etc.)
        - Do not share these codes with anyone
        - Each code can only be used once
        - Generate new codes after using most of them
        
        If you lose access to your two-factor authentication method, you can use one of these codes to sign in.
        """
    }
}

// MARK: - Backup Code Card

struct BackupCodeCard: View {
    let number: Int
    let code: String
    let isCopied: Bool
    let onCopy: () -> Void
    
    var body: some View {
        Button(action: onCopy) {
            VStack(spacing: 8) {
                HStack {
                    Text("#\(number)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(isCopied ? .green : .blue)
                }
                
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                if isCopied {
                    Text("Copied!")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCopied ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
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

// ShareSheet is now defined in Common/ShareSheet.swift