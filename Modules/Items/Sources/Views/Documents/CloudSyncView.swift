import SwiftUI
import Core
import Core
import SharedUI

/// Cloud sync view for managing document synchronization
/// Swift 5.9 - No Swift 6 features
struct CloudSyncView: View {
    @StateObject private var viewModel: CloudSyncViewModel
    @State private var showingEncryptionAlert = false
    @State private var documentToToggleEncryption: CloudDocumentMetadata?
    @State private var showingRetryOptions = false
    @State private var errorToRetry: CloudSyncError?
    
    init(cloudStorage: CloudDocumentStorageProtocol,
         documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol) {
        self._viewModel = StateObject(wrappedValue: CloudSyncViewModel(
            cloudStorage: cloudStorage,
            documentRepository: documentRepository,
            documentStorage: documentStorage
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // iCloud availability status
                    iCloudStatusCard
                    
                    // Storage usage
                    storageUsageSection
                    
                    // Sync settings
                    syncSettingsSection
                    
                    // Sync status
                    syncStatusSection
                    
                    // Documents list
                    documentsListSection
                    
                    // Sync errors
                    if !viewModel.syncErrors.isEmpty {
                        syncErrorsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Cloud Sync")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .alert("Toggle Encryption", isPresented: $showingEncryptionAlert) {
                Button("Cancel", role: .cancel) {
                    documentToToggleEncryption = nil
                }
                Button("Continue") {
                    if let document = documentToToggleEncryption {
                        Task {
                            await viewModel.toggleEncryption(for: document)
                            documentToToggleEncryption = nil
                        }
                    }
                }
            } message: {
                Text("Changing encryption will re-upload the document. This may take a moment.")
            }
            .confirmationDialog("Retry Options", isPresented: $showingRetryOptions) {
                Button("Retry Now") {
                    if let error = errorToRetry {
                        Task {
                            await viewModel.retrySync(for: error.documentId)
                        }
                    }
                }
                Button("Retry All Failed") {
                    Task {
                        await viewModel.retryAllFailed()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - iCloud Status Card
    
    private var iCloudStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.iCloudAvailable ? "checkmark.icloud.fill" : "exclamationmark.icloud.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.iCloudAvailable ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.iCloudAvailable ? "iCloud Available" : "iCloud Not Available")
                        .font(.headline)
                    
                    Text(viewModel.iCloudAvailable ? 
                         "Documents can be synced to iCloud" : 
                         "Check your iCloud settings in Settings app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Storage Usage Section
    
    private var storageUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Usage")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 20)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    storageGradientColor(for: viewModel.storageUsage.percentageUsed).opacity(0.8),
                                    storageGradientColor(for: viewModel.storageUsage.percentageUsed)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * (viewModel.storageUsage.percentageUsed / 100), height: 20)
                    }
                }
                .frame(height: 20)
                
                // Storage details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.storageUsage.formattedUsed)
                            .font(.subheadline)
                            .bold()
                        Text("Used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(Int(viewModel.storageUsage.percentageUsed))%")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(storageGradientColor(for: viewModel.storageUsage.percentageUsed))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.storageUsage.formattedTotal)
                            .font(.subheadline)
                            .bold()
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Document count
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.storageUsage.documentCount) documents synced")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sync Settings Section
    
    private var syncSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Settings")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Automatic sync toggle
                HStack {
                    Label("Automatic Sync", systemImage: "arrow.triangle.2.circlepath")
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.automaticSyncEnabled)
                        .labelsHidden()
                }
                .padding()
                
                Divider()
                    .padding(.horizontal)
                
                // Manual sync button
                Button(action: {
                    Task {
                        await viewModel.performManualSync()
                    }
                }) {
                    HStack {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                        
                        Spacer()
                        
                        if viewModel.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSyncing || !viewModel.iCloudAvailable)
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sync Status Section
    
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sync Status", systemImage: "clock.fill")
                    .font(.headline)
                
                Spacer()
                
                if let lastSyncDate = viewModel.lastSyncDate {
                    Text(lastSyncDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                // Sync status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.syncStatusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(viewModel.syncStatusText)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Pending count
                if viewModel.pendingDocuments > 0 {
                    Label("\(viewModel.pendingDocuments) pending", systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Documents List Section
    
    private var documentsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Documents")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.cloudDocuments.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.cloudDocuments) { metadata in
                    CloudDocumentRow(
                        metadata: metadata,
                        localDocument: viewModel.localDocument(for: metadata.documentId),
                        onToggleEncryption: {
                            documentToToggleEncryption = metadata
                            showingEncryptionAlert = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Sync Errors Section
    
    private var syncErrorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Sync Errors", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Button("Retry All") {
                    Task {
                        await viewModel.retryAllFailed()
                    }
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.syncErrors) { error in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(error.documentName)
                                .font(.subheadline)
                            
                            Text(error.errorDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            errorToRetry = error
                            showingRetryOptions = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func storageGradientColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<50:
            return .green
        case 50..<75:
            return .yellow
        case 75..<90:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Cloud Document Row

struct CloudDocumentRow: View {
    let metadata: CloudDocumentMetadata
    let localDocument: Document?
    let onToggleEncryption: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Document icon
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: documentIcon)
                        .foregroundStyle(documentColor)
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localDocument?.name ?? "Document")
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Sync status
                        HStack(spacing: 4) {
                            Image(systemName: syncStatusIcon)
                                .font(.caption2)
                            Text(metadata.syncStatus.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .foregroundStyle(syncStatusColor)
                        
                        // File size
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: metadata.fileSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Encryption toggle
                Button(action: onToggleEncryption) {
                    Image(systemName: metadata.encrypted ? "lock.fill" : "lock.open")
                        .foregroundStyle(metadata.encrypted ? .green : .secondary)
                }
            }
            .padding()
            
            // Last synced
            HStack {
                Text("Last synced")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(metadata.lastModified, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var documentIcon: String {
        localDocument?.type.icon ?? "doc.fill"
    }
    
    private var documentColor: Color {
        if let category = localDocument?.category {
            return Color(hex: category.color)
        }
        return .secondary
    }
    
    private var syncStatusIcon: String {
        switch metadata.syncStatus {
        case .synced:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .uploading:
            return "arrow.up.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        switch metadata.syncStatus {
        case .synced:
            return .green
        case .pending:
            return .orange
        case .uploading:
            return .blue
        case .failed:
            return .red
        }
    }
}

// MARK: - View Model

@MainActor
final class CloudSyncViewModel: ObservableObject {
    @Published var iCloudAvailable = false
    @Published var storageUsage = CloudStorageUsage(usedBytes: 0, totalBytes: 0, documentCount: 0)
    @Published var automaticSyncEnabled = true {
        didSet {
            UserDefaults.standard.set(automaticSyncEnabled, forKey: "automaticCloudSync")
        }
    }
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatusText = "Not synced"
    @Published var syncStatusColor = Color.gray
    @Published var pendingDocuments = 0
    @Published var cloudDocuments: [CloudDocumentMetadata] = []
    @Published var localDocuments: [Document] = []
    @Published var syncErrors: [CloudSyncError] = []
    
    private let cloudStorage: CloudDocumentStorageProtocol
    private let documentRepository: any DocumentRepository
    private let documentStorage: DocumentStorageProtocol
    
    init(cloudStorage: CloudDocumentStorageProtocol,
         documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol) {
        self.cloudStorage = cloudStorage
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        
        // Load settings
        self.automaticSyncEnabled = UserDefaults.standard.bool(forKey: "automaticCloudSync")
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastCloudSyncDate") as? Date
    }
    
    func loadData() async {
        // Check iCloud availability
        do {
            _ = try ICloudDocumentStorage()
            iCloudAvailable = true
        } catch {
            iCloudAvailable = false
            return
        }
        
        // Load storage usage
        do {
            storageUsage = try await cloudStorage.getStorageUsage()
        } catch {
            print("Failed to load storage usage: \(error)")
        }
        
        // Load documents
        do {
            cloudDocuments = try await cloudStorage.listDocuments()
            localDocuments = try await documentRepository.fetchAll()
            
            // Calculate pending documents
            let syncedIds = Set(cloudDocuments.filter { $0.syncStatus == CloudDocumentMetadata.SyncStatus.synced }.map { $0.documentId })
            pendingDocuments = localDocuments.filter { !syncedIds.contains($0.id) }.count
            
            updateSyncStatus()
        } catch {
            print("Failed to load documents: \(error)")
        }
    }
    
    func performManualSync() async {
        guard iCloudAvailable else { return }
        
        isSyncing = true
        syncErrors.removeAll()
        
        // Sync each local document
        for document in localDocuments {
            do {
                // Check if document exists in cloud
                let existsInCloud = cloudDocuments.contains { $0.documentId == document.id }
                
                if !existsInCloud {
                    // Upload new document
                    if let data = try? await documentStorage.loadDocument(documentId: document.id) {
                        let encrypted = UserDefaults.standard.bool(forKey: "encryptDocuments_\(document.id)")
                        _ = try await cloudStorage.uploadDocument(data, documentId: document.id, encrypted: encrypted)
                    }
                }
            } catch {
                syncErrors.append(CloudSyncError(
                    documentId: document.id,
                    documentName: document.name,
                    errorDescription: error.localizedDescription
                ))
            }
        }
        
        // Update sync date
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")
        
        // Reload data
        await loadData()
        
        isSyncing = false
    }
    
    func toggleEncryption(for metadata: CloudDocumentMetadata) async {
        do {
            // Download document
            let data = try await cloudStorage.downloadDocument(documentId: metadata.documentId)
            
            // Re-upload with different encryption setting
            _ = try await cloudStorage.uploadDocument(
                data,
                documentId: metadata.documentId,
                encrypted: !metadata.encrypted
            )
            
            // Update local preference
            UserDefaults.standard.set(!metadata.encrypted, forKey: "encryptDocuments_\(metadata.documentId)")
            
            // Reload data
            await loadData()
        } catch {
            print("Failed to toggle encryption: \(error)")
        }
    }
    
    func retrySync(for documentId: UUID) async {
        // Remove from errors
        syncErrors.removeAll { $0.documentId == documentId }
        
        // Try to sync this document
        if let document = localDocuments.first(where: { $0.id == documentId }) {
            do {
                if let data = try? await documentStorage.loadDocument(documentId: document.id) {
                    let encrypted = UserDefaults.standard.bool(forKey: "encryptDocuments_\(document.id)")
                    _ = try await cloudStorage.uploadDocument(data, documentId: document.id, encrypted: encrypted)
                }
            } catch {
                syncErrors.append(CloudSyncError(
                    documentId: document.id,
                    documentName: document.name,
                    errorDescription: error.localizedDescription
                ))
            }
        }
        
        await loadData()
    }
    
    func retryAllFailed() async {
        let failedIds = syncErrors.map { $0.documentId }
        syncErrors.removeAll()
        
        for documentId in failedIds {
            await retrySync(for: documentId)
        }
    }
    
    func localDocument(for documentId: UUID) -> Document? {
        localDocuments.first { $0.id == documentId }
    }
    
    private func updateSyncStatus() {
        if isSyncing {
            syncStatusText = "Syncing..."
            syncStatusColor = .blue
        } else if !syncErrors.isEmpty {
            syncStatusText = "Sync failed"
            syncStatusColor = .red
        } else if pendingDocuments > 0 {
            syncStatusText = "Pending sync"
            syncStatusColor = .orange
        } else {
            syncStatusText = "All synced"
            syncStatusColor = .green
        }
    }
}

// MARK: - Sync Error Model

struct CloudSyncError: Identifiable {
    let id = UUID()
    let documentId: UUID
    let documentName: String
    let errorDescription: String
}