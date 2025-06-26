//
//  RestoreBackupView.swift
//  Core
//
//  View for restoring from backup
//

import SwiftUI
import UniformTypeIdentifiers

@available(iOS 15.0, *)
public struct RestoreBackupView: View {
    @StateObject private var backupService = BackupService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedBackup: BackupService.BackupInfo?
    @State private var showingFilePicker = false
    @State private var showingPasswordPrompt = false
    @State private var password = ""
    @State private var showingRestoreOptions = false
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Restore options
    @State private var replaceExisting = true
    @State private var mergeData = false
    @State private var restorePhotos = true
    @State private var restoreDocuments = true
    @State private var restoreSettings = true
    
    // Results
    @State private var restoredContents: BackupService.BackupContents?
    @State private var restoreResults: RestoreResults?
    
    struct RestoreResults {
        let itemsRestored: Int
        let photosRestored: Int
        let documentsRestored: Int
        let conflicts: Int
        let errors: [String]
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if backupService.availableBackups.isEmpty {
                    emptyView
                } else {
                    backupList
                }
            }
            .navigationTitle("Restore Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(backupService.isRestoringBackup)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilePicker = true }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .disabled(backupService.isRestoringBackup)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(contentTypes: [.item]) { url in
                    restoreFromFile(url)
                }
            }
            .sheet(isPresented: $showingRestoreOptions) {
                if let backup = selectedBackup {
                    RestoreOptionsSheet(
                        backup: backup,
                        replaceExisting: $replaceExisting,
                        mergeData: $mergeData,
                        restorePhotos: $restorePhotos,
                        restoreDocuments: $restoreDocuments,
                        restoreSettings: $restoreSettings,
                        onRestore: performRestore
                    )
                }
            }
            .alert("Enter Password", isPresented: $showingPasswordPrompt) {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                
                Button("Restore") {
                    performRestore()
                }
                Button("Cancel", role: .cancel) {
                    password = ""
                    selectedBackup = nil
                }
            } message: {
                Text("This backup is encrypted. Enter the password to restore.")
            }
            .alert("Restore Complete", isPresented: $showingRestoreSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let results = restoreResults {
                    Text("""
                    Successfully restored:
                    • \(results.itemsRestored) items
                    • \(results.photosRestored) photos
                    • \(results.documentsRestored) documents
                    """)
                } else {
                    Text("Backup restored successfully")
                }
            }
            .alert("Restore Failed", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "externaldrive.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Backups Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Import a backup file to restore your data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingFilePicker = true }) {
                Label("Import Backup File", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    private var backupList: some View {
        List {
            Section {
                ForEach(backupService.availableBackups) { backup in
                    RestoreBackupRow(backup: backup) {
                        selectedBackup = backup
                        if backup.isEncrypted {
                            showingPasswordPrompt = true
                        } else {
                            showingRestoreOptions = true
                        }
                    }
                }
            } header: {
                Text("Available Backups")
            } footer: {
                Text("Select a backup to restore from")
                    .font(.caption)
            }
            
            Section {
                Button(action: { showingFilePicker = true }) {
                    Label("Import Backup File", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
    
    private func restoreFromFile(_ url: URL) {
        // Create a temporary BackupInfo for the imported file
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            let tempBackup = BackupService.BackupInfo(
                id: UUID(),
                createdDate: attributes[.creationDate] as? Date ?? Date(),
                fileName: url.lastPathComponent,
                fileSize: fileSize,
                itemCount: 0,
                photoCount: 0,
                receiptCount: 0,
                appVersion: "Unknown",
                deviceName: "Imported",
                isEncrypted: false, // Will be determined during restore
                compressionRatio: 1.0,
                checksum: ""
            )
            
            selectedBackup = tempBackup
            showingRestoreOptions = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func performRestore() {
        guard let backup = selectedBackup else { return }
        
        Task {
            do {
                let backupURL = backupService.exportBackup(backup)
                let contents = try await backupService.restoreBackup(
                    from: backupURL,
                    password: backup.isEncrypted ? password : nil
                )
                
                restoredContents = contents
                
                // Calculate results
                restoreResults = RestoreResults(
                    itemsRestored: contents.items.count,
                    photosRestored: contents.photoReferences.count,
                    documentsRestored: contents.documentReferences.count,
                    conflicts: 0,
                    errors: []
                )
                
                showingRestoreSuccess = true
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            // Clear password
            password = ""
        }
    }
}

// MARK: - Subviews

struct RestoreBackupRow: View {
    let backup: BackupService.BackupInfo
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(backup.createdDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(backup.itemCount) items • \(backup.formattedFileSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if backup.isEncrypted {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label(backup.deviceName, systemImage: "iphone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("v\(backup.appVersion)", systemImage: "app.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RestoreOptionsSheet: View {
    let backup: BackupService.BackupInfo
    @Binding var replaceExisting: Bool
    @Binding var mergeData: Bool
    @Binding var restorePhotos: Bool
    @Binding var restoreDocuments: Bool
    @Binding var restoreSettings: Bool
    let onRestore: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(backup.createdDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            Label("\(backup.itemCount) items", systemImage: "cube.box")
                                .font(.caption)
                            
                            Label(backup.formattedFileSize, systemImage: "internaldrive")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Backup Details")
                }
                
                Section {
                    Picker("Restore Method", selection: $replaceExisting) {
                        Text("Replace All Data").tag(true)
                        Text("Merge with Existing").tag(false)
                    }
                } header: {
                    Text("Restore Method")
                } footer: {
                    Text(replaceExisting ? 
                         "⚠️ Warning: This will replace all existing data with the backup data" :
                         "Merge will combine backup data with existing data, keeping newer versions")
                        .font(.caption)
                }
                
                Section {
                    Toggle("Restore Photos", isOn: $restorePhotos)
                        .disabled(backup.photoCount == 0)
                    
                    Toggle("Restore Documents", isOn: $restoreDocuments)
                        .disabled(backup.receiptCount == 0)
                    
                    Toggle("Restore Settings", isOn: $restoreSettings)
                } header: {
                    Text("Restore Options")
                }
                
                Section {
                    Button(action: {
                        dismiss()
                        onRestore()
                    }) {
                        Label("Restore Backup", systemImage: "arrow.down.doc.fill")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Restore Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Document picker for backup files
struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}