import SwiftUI
import Core
import SharedUI
import UniformTypeIdentifiers
import UIKit

/// View for managing documents attached to an item
/// Swift 5.9 - No Swift 6 features
struct ItemDocumentsView: View {
    let itemId: UUID
    @StateObject private var viewModel: ItemDocumentsViewModel
    @State private var selectedDocument: Document?
    @State private var showingDocumentPicker = false
    @State private var showingPDFViewer = false
    @State private var pdfURL: URL?
    @State private var showingAddDocument = false
    @State private var searchText = ""
    
    init(itemId: UUID, documentRepository: any DocumentRepository, documentStorage: DocumentStorageProtocol) {
        self.itemId = itemId
        self._viewModel = StateObject(wrappedValue: ItemDocumentsViewModel(
            itemId: itemId,
            documentRepository: documentRepository,
            documentStorage: documentStorage
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            if !viewModel.documents.isEmpty {
                searchBar
            }
            
            List {
            // Add Document Button
            Section {
                Button(action: { showingAddDocument = true }) {
                    Label("Add Document", systemImage: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                }
            }
            
            // Documents by Category
            ForEach(Document.DocumentCategory.allCases, id: \.self) { category in
                let documents = filteredDocuments(for: category)
                if !documents.isEmpty {
                    Section(header: categoryHeader(category, count: documents.count)) {
                        ForEach(documents) { document in
                            DocumentRow(
                                document: document,
                                onTap: {
                                    if document.isPDF {
                                        openPDF(document)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteDocument(document)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // Storage Usage
            if viewModel.totalStorageSize > 0 {
                Section {
                    HStack {
                        Label("Total Storage", systemImage: "externaldrive")
                        Spacer()
                        Text(viewModel.formattedStorageSize)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDocuments()
        }
        .refreshable {
            await viewModel.loadDocuments()
        }
        .sheet(item: $selectedDocument) { document in
            if let url = viewModel.documentStorage.getDocumentURL(documentId: document.id) {
                if let pageCount = document.pageCount, pageCount > 1 {
                    // Use enhanced viewer for multi-page documents
                    PDFViewerEnhanced(url: url, title: document.name)
                } else {
                    // Use simple viewer for single page
                    PDFViewerView(url: url, title: document.name)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingAddDocument) {
            AddDocumentSheet(
                documentRepository: viewModel.documentRepository,
                documentStorage: viewModel.documentStorage,
                itemId: itemId
            )
        }
    }
    
    private func categoryHeader(_ category: Document.DocumentCategory, count: Int) -> some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundStyle(Color(hex: category.color))
            Text(category.displayName)
            Text("(\(count))")
                .foregroundStyle(.secondary)
        }
    }
    
    private func openPDF(_ document: Document) {
        selectedDocument = document
    }
    
    private var searchBar: some View {
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
    }
    
    private func filteredDocuments(for category: Document.DocumentCategory) -> [Document] {
        let categoryDocuments = viewModel.documentsByCategory[category] ?? []
        
        if searchText.isEmpty {
            return categoryDocuments
        }
        
        let query = searchText.lowercased()
        return categoryDocuments.filter { document in
            document.name.lowercased().contains(query) ||
            (document.notes?.lowercased().contains(query) ?? false) ||
            document.tags.contains { $0.lowercased().contains(query) } ||
            (document.subcategory?.lowercased().contains(query) ?? false)
        }
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let document: Document
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Thumbnail or Icon
                if let thumbnailData = document.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    // Show thumbnail for PDFs
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                } else {
                    // Show icon
                    Image(systemName: document.type.icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Document Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        if let subcategory = document.subcategory {
                            Text(subcategory)
                                .textStyle(.bodySmall)
                                .foregroundStyle(Color(hex: document.category.color))
                        }
                        
                        if let pageCount = document.pageCount {
                            if document.subcategory != nil {
                                Text("•")
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(pageCount) pages")
                                .textStyle(.bodySmall)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(document.formattedFileSize)
                            .textStyle(.bodySmall)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                if document.isPDF {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var iconColor: Color {
        switch document.type {
        case .pdf: return .red
        case .image: return .blue
        case .text: return .green
        case .other: return .gray
        }
    }
}

// MARK: - View Model
@MainActor
final class ItemDocumentsViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var documentsByCategory: [Document.DocumentCategory: [Document]] = [:]
    @Published var totalStorageSize: Int64 = 0
    @Published var showingError = false
    @Published var errorMessage = ""
    
    let itemId: UUID
    let documentRepository: any DocumentRepository
    let documentStorage: DocumentStorageProtocol
    private let pdfService = PDFService()
    
    init(itemId: UUID, documentRepository: any DocumentRepository, documentStorage: DocumentStorageProtocol) {
        self.itemId = itemId
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
    }
    
    var formattedStorageSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageSize)
    }
    
    func loadDocuments() async {
        do {
            documents = try await documentRepository.fetchByItemId(itemId)
            updateDocumentsByCategory()
            calculateStorageSize()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func addDocuments(from urls: [URL]) async {
        for url in urls {
            do {
                // Start accessing security-scoped resource
                let gotAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if gotAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                // Read document data
                let data = try Data(contentsOf: url)
                let fileSize = Int64(data.count)
                
                // Determine document type
                let mimeType = getMimeType(for: url)
                let documentType = Document.DocumentType.from(mimeType: mimeType)
                
                // Extract page count for PDFs
                var pageCount: Int? = nil
                var searchableText: String? = nil
                
                if documentType == .pdf {
                    pageCount = pdfService.getPageCount(from: data)
                    searchableText = await pdfService.extractText(from: data)
                }
                
                // Create document record
                var document = Document(
                    name: url.lastPathComponent,
                    type: documentType,
                    category: suggestCategory(for: url.lastPathComponent),
                    fileSize: fileSize,
                    mimeType: mimeType,
                    itemId: itemId,
                    pageCount: pageCount,
                    searchableText: searchableText
                )
                
                // Generate thumbnail for PDFs
                if document.isPDF {
                    if let thumbnail = pdfService.generateThumbnail(from: data) {
                        document.thumbnailData = thumbnail.pngData()
                    }
                }
                
                // Save document data
                _ = try await documentStorage.saveDocument(data, documentId: document.id)
                
                // Save document record
                try await documentRepository.save(document)
                
            } catch {
                showError("Failed to add \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        await loadDocuments()
    }
    
    func deleteDocument(_ document: Document) async {
        do {
            // Delete file
            try await documentStorage.deleteDocument(documentId: document.id)
            
            // Delete record
            try await documentRepository.delete(document)
            
            await loadDocuments()
        } catch {
            showError("Failed to delete document: \(error.localizedDescription)")
        }
    }
    
    private func updateDocumentsByCategory() {
        documentsByCategory = Dictionary(grouping: documents, by: { $0.category })
    }
    
    private func calculateStorageSize() {
        totalStorageSize = documents.reduce(0) { $0 + $1.fileSize }
    }
    
    private func getMimeType(for url: URL) -> String {
        if let uti = UTType(filenameExtension: url.pathExtension) {
            return uti.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
    
    private func suggestCategory(for filename: String) -> Document.DocumentCategory {
        let lowercased = filename.lowercased()
        
        if lowercased.contains("receipt") {
            return .receipt
        } else if lowercased.contains("manual") || lowercased.contains("guide") {
            return .manual
        } else if lowercased.contains("warranty") {
            return .warranty
        } else if lowercased.contains("invoice") {
            return .invoice
        } else if lowercased.contains("certificate") {
            return .certificate
        } else {
            return .other
        }
    }
    
    
    func addScannedDocument(pdfData: Data) async {
        do {
            let fileSize = Int64(pdfData.count)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let fileName = "Scan \(dateFormatter.string(from: Date())).pdf"
            
            // Extract page count and text
            let pageCount = pdfService.getPageCount(from: pdfData)
            let searchableText = await pdfService.extractText(from: pdfData)
            
            // Create document record
            var document = Document(
                name: fileName,
                type: .pdf,
                category: suggestCategory(for: fileName),
                fileSize: fileSize,
                mimeType: "application/pdf",
                itemId: itemId,
                pageCount: pageCount,
                searchableText: searchableText
            )
            
            // Generate thumbnail
            if let thumbnail = pdfService.generateThumbnail(from: pdfData) {
                document.thumbnailData = thumbnail.pngData()
            }
            
            // Save document data
            _ = try await documentStorage.saveDocument(pdfData, documentId: document.id)
            
            // Save document record
            try await documentRepository.save(document)
            
            await loadDocuments()
        } catch {
            showError("Failed to save scanned document: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}