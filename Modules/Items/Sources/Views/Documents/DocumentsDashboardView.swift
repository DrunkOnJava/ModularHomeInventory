import SwiftUI
import Core
import SharedUI

/// Documents dashboard for organizing all documents
/// Swift 5.9 - No Swift 6 features
struct DocumentsDashboardView: View {
    @StateObject private var viewModel: DocumentsDashboardViewModel
    @State private var selectedViewMode: ViewMode = .byCategory
    @State private var searchText = ""
    @State private var selectedDocument: Document?
    @State private var showingAddDocument = false
    @State private var showingDocumentSearch = false
    
    enum ViewMode: String, CaseIterable {
        case byCategory = "By Category"
        case byItem = "By Item"
        case recent = "Recent"
        case all = "All Documents"
        case thumbnails = "Thumbnails"
        
        var icon: String {
            switch self {
            case .byCategory: return "folder.fill"
            case .byItem: return "cube.box.fill"
            case .recent: return "clock.fill"
            case .all: return "doc.text.fill"
            case .thumbnails: return "square.grid.2x2.fill"
            }
        }
    }
    
    init(documentRepository: any DocumentRepository, 
         documentStorage: DocumentStorageProtocol,
         itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: DocumentsDashboardViewModel(
            documentRepository: documentRepository,
            documentStorage: documentStorage,
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search documents", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // View mode picker
                Picker("View Mode", selection: $selectedViewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content based on view mode
                Group {
                    switch selectedViewMode {
                    case .byCategory:
                        categoryView
                    case .byItem:
                        itemView
                    case .recent:
                        recentView
                    case .all:
                        allDocumentsView
                    case .thumbnails:
                        thumbnailView
                    }
                }
                
                // Statistics bar
                statisticsBar
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingDocumentSearch = true }) {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                        
                        Button(action: { showingAddDocument = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadDocuments()
            }
            .refreshable {
                await viewModel.loadDocuments()
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentSheet(
                    documentRepository: viewModel.documentRepository,
                    documentStorage: viewModel.documentStorage
                )
            }
            .sheet(item: $selectedDocument) { document in
                if let url = viewModel.documentStorage.getDocumentURL(documentId: document.id) {
                    if document.isPDF && (document.pageCount ?? 1) > 1 {
                        PDFViewerEnhanced(url: url, title: document.name)
                    } else {
                        PDFViewerView(url: url, title: document.name)
                    }
                }
            }
            .sheet(isPresented: $showingDocumentSearch) {
                DocumentSearchView(
                    documentRepository: viewModel.documentRepository,
                    documentStorage: viewModel.documentStorage,
                    itemRepository: viewModel.itemRepository
                )
            }
        }
    }
    
    private var thumbnailView: some View {
        DocumentThumbnailGrid(
            documents: viewModel.filteredDocuments(searchText: searchText),
            documentStorage: viewModel.documentStorage,
            onSelectDocument: { document in
                selectedDocument = document
            },
            onDeleteDocument: { document in
                Task {
                    await viewModel.deleteDocument(document)
                }
            }
        )
    }
    
    private var categoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Document.DocumentCategory.allCases, id: \.self) { category in
                    let documents = viewModel.filteredDocuments(searchText: searchText)
                        .filter { $0.category == category }
                    
                    if !documents.isEmpty {
                        CategorySection(
                            category: category,
                            documents: documents,
                            onSelectDocument: { selectedDocument = $0 }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var itemView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.itemsWithDocuments) { item in
                    let documents = viewModel.documentsForItem(item.id)
                        .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if !documents.isEmpty {
                        ItemDocumentSection(
                            item: item,
                            documents: documents,
                            onSelectDocument: { selectedDocument = $0 }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var recentView: some View {
        List {
            ForEach(viewModel.recentDocuments(searchText: searchText)) { document in
                DocumentListRow(
                    document: document,
                    showItemName: true,
                    itemName: viewModel.itemName(for: document.itemId)
                ) {
                    selectedDocument = document
                }
            }
        }
    }
    
    private var allDocumentsView: some View {
        List {
            ForEach(viewModel.filteredDocuments(searchText: searchText)) { document in
                DocumentListRow(
                    document: document,
                    showItemName: true,
                    itemName: viewModel.itemName(for: document.itemId)
                ) {
                    selectedDocument = document
                }
            }
        }
    }
    
    private var statisticsBar: some View {
        HStack(spacing: 20) {
            StatisticItem(
                title: "Total",
                value: "\(viewModel.documents.count)",
                icon: "doc.fill"
            )
            
            StatisticItem(
                title: "Storage",
                value: viewModel.totalStorageSize,
                icon: "externaldrive.fill"
            )
            
            StatisticItem(
                title: "Items",
                value: "\(viewModel.itemsWithDocuments.count)",
                icon: "cube.box.fill"
            )
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: Document.DocumentCategory
    let documents: [Document]
    let onSelectDocument: (Document) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.color))
                Text(category.displayName)
                    .font(.headline)
                Text("(\(documents.count))")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            // Documents grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                ForEach(documents) { document in
                    Button(action: { onSelectDocument(document) }) {
                        DocumentGridCard(document: document)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Item Document Section
struct ItemDocumentSection: View {
    let item: Item
    let documents: [Document]
    let onSelectDocument: (Document) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: item.category.icon)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(documents.count) docs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Documents
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(documents) { document in
                        Button(action: { onSelectDocument(document) }) {
                            DocumentGridCard(document: document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Document List Row
struct DocumentListRow: View {
    let document: Document
    let showItemName: Bool
    let itemName: String?
    let onTap: () -> Void
    
    @State private var syncStatus: SyncStatus = .notSynced
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon or thumbnail with sync status overlay
                ZStack(alignment: .bottomTrailing) {
                    if let thumbnailData = document.thumbnailData,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: document.category.color).opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: document.type.icon)
                                .foregroundStyle(Color(hex: document.category.color))
                        }
                    }
                    
                    // Sync status indicator overlay
                    if syncStatus != .notSynced {
                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 18, height: 18)
                            
                            Image(systemName: syncStatusIcon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: syncStatus.color))
                                .frame(width: 16, height: 16)
                        }
                        .offset(x: 4, y: 4)
                    }
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(document.name)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        
                        // Cloud icon for synced documents
                        if syncStatus == .synced {
                            Image(systemName: "icloud.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Warning icon for conflicts
                        if syncStatus == .conflict {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: SyncStatus.conflict.color))
                        }
                    }
                    
                    HStack {
                        Text(document.category.displayName)
                            .font(.caption)
                            .foregroundStyle(Color(hex: document.category.color))
                        
                        if let subcategory = document.subcategory {
                            Text("• \(subcategory)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if showItemName, let itemName = itemName {
                            Text("• \(itemName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Metadata
                VStack(alignment: .trailing, spacing: 4) {
                    if let pageCount = document.pageCount {
                        Text("\(pageCount) pages")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(document.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await updateSyncStatus()
        }
    }
    
    private var syncStatusIcon: String {
        switch syncStatus {
        case .synced:
            return "checkmark.circle.fill"
        case .pending, .uploading:
            return "arrow.triangle.2.circlepath"
        case .conflict:
            return "exclamationmark.triangle.fill"
        case .error, .failed:
            return "xmark.circle.fill"
        case .notSynced:
            return "icloud.slash"
        }
    }
    
    private func updateSyncStatus() async {
        let cloudSyncService = CloudSyncService.shared
        
        // Check if document is in conflict
        if cloudSyncService.conflictedDocuments.contains(where: { $0.documentId == document.id }) {
            syncStatus = .conflict
            return
        }
        
        // Check if document is in sync queue
        if let queueItem = cloudSyncService.syncQueue.first(where: { $0.documentId == document.id }) {
            // If currently syncing and this document is being processed
            if cloudSyncService.isSyncing && queueItem.operation == SyncQueueItem.SyncOperation.upload {
                syncStatus = .pending
            } else {
                syncStatus = .pending
            }
            return
        }
        
        // Check if document had sync errors
        if cloudSyncService.syncErrors.contains(where: { $0.documentId == document.id }) {
            syncStatus = .error
            return
        }
        
        // Get actual sync status from service
        syncStatus = await cloudSyncService.getSyncStatus(for: document.id)
    }
}

// MARK: - Statistic Item
struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - View Model
@MainActor
final class DocumentsDashboardViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var items: [Item] = []
    
    let documentRepository: any DocumentRepository
    let documentStorage: DocumentStorageProtocol
    let itemRepository: any ItemRepository
    
    init(documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol,
         itemRepository: any ItemRepository) {
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        self.itemRepository = itemRepository
    }
    
    func loadDocuments() async {
        do {
            documents = try await documentRepository.fetchAll()
            items = try await itemRepository.fetchAll()
        } catch {
            print("Failed to load documents: \(error)")
        }
    }
    
    func filteredDocuments(searchText: String) -> [Document] {
        if searchText.isEmpty {
            return documents
        }
        return documents.filter { document in
            document.name.localizedCaseInsensitiveContains(searchText) ||
            document.category.displayName.localizedCaseInsensitiveContains(searchText) ||
            (document.subcategory?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            document.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func recentDocuments(searchText: String) -> [Document] {
        filteredDocuments(searchText: searchText)
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(20)
            .map { $0 }
    }
    
    func documentsForItem(_ itemId: UUID) -> [Document] {
        documents.filter { $0.itemId == itemId }
    }
    
    var itemsWithDocuments: [Item] {
        let itemIds = Set(documents.compactMap { $0.itemId })
        return items.filter { itemIds.contains($0.id) }
    }
    
    func itemName(for itemId: UUID?) -> String? {
        guard let itemId = itemId else { return nil }
        return items.first { $0.id == itemId }?.name
    }
    
    var totalStorageSize: String {
        let totalBytes = documents.reduce(0) { $0 + $1.fileSize }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    func deleteDocument(_ document: Document) async {
        do {
            // Delete file
            try await documentStorage.deleteDocument(documentId: document.id)
            
            // Delete record
            try await documentRepository.delete(document)
            
            // Remove from local array
            documents.removeAll { $0.id == document.id }
        } catch {
            print("Failed to delete document: \(error)")
        }
    }
}

// MARK: - Document Grid Card
struct DocumentGridCard: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail or icon
            ZStack {
                if let thumbnailData = document.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 160)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(hex: document.category.color).opacity(0.1))
                        .frame(width: 120, height: 160)
                        .overlay {
                            Image(systemName: document.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(Color(hex: document.category.color))
                        }
                }
            }
            .cornerRadius(8)
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                if let subcategory = document.subcategory {
                    Text(subcategory)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if let pageCount = document.pageCount {
                        Text("\(pageCount)p")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(document.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, alignment: .leading)
        }
    }
}