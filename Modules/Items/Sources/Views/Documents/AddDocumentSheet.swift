import SwiftUI
import Core
import SharedUI
import UniformTypeIdentifiers

/// Sheet for adding documents with category selection
/// Swift 5.9 - No Swift 6 features
struct AddDocumentSheet: View {
    let documentRepository: any DocumentRepository
    let documentStorage: DocumentStorageProtocol
    let itemId: UUID?
    
    @Environment(\.dismiss) private var dismiss
    @State private var documentName = ""
    @State private var category: Document.DocumentCategory = .other
    @State private var subcategory: String?
    @State private var tags: [String] = []
    @State private var notes = ""
    @State private var showingDocumentPicker = false
    @State private var showingScanner = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private let pdfService = PDFService()
    
    init(documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol,
         itemId: UUID? = nil) {
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        self.itemId = itemId
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Document source section
                Section("Add Document") {
                    Button(action: { showingDocumentPicker = true }) {
                        Label("Choose from Files", systemImage: "folder")
                    }
                    
                    if #available(iOS 16.0, *) {
                        Button(action: { showingScanner = true }) {
                            Label("Scan Document", systemImage: "doc.text.viewfinder")
                        }
                    }
                }
                
                // Document details section
                Section("Document Details") {
                    TextField("Document Name", text: $documentName)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            ForEach(Document.DocumentCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    category = cat
                                    subcategory = nil
                                }) {
                                    Label(cat.displayName, systemImage: cat.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Color(hex: category.color))
                                Text(category.displayName)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if !category.subcategories.isEmpty {
                            Menu {
                                Button(action: { subcategory = nil }) {
                                    Text("None")
                                }
                                Divider()
                                ForEach(category.subcategories, id: \.self) { subcat in
                                    Button(action: { subcategory = subcat }) {
                                        Text(subcat)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Subcategory")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(subcategory ?? "Select")
                                        .foregroundStyle(subcategory != nil ? .primary : .secondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    TagInputField(tags: $tags)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Smart categorization tip
                if documentName.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Tip: We'll suggest a category based on the file name")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    documentTypes: [.pdf, .image, .text],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            Task {
                                await processSelectedDocument(url)
                            }
                        }
                    case .failure(let error):
                        if case DocumentPickerError.cancelled = error {
                            return
                        }
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                if #available(iOS 16.0, *) {
                    MultiPageDocumentScanner { result in
                        showingScanner = false
                        switch result {
                        case .success(let pdfData):
                            Task {
                                await processScannedDocument(pdfData)
                            }
                        case .failure(let error):
                            if case DocumentScannerError.cancelled = error {
                                return
                            }
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func processSelectedDocument(_ url: URL) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Access security-scoped resource
            let gotAccess = url.startAccessingSecurityScopedResource()
            defer {
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Read document data
            let data = try Data(contentsOf: url)
            
            // Auto-fill name if empty
            if documentName.isEmpty {
                documentName = url.deletingPathExtension().lastPathComponent
            }
            
            // Auto-suggest category if not changed
            if category == .other {
                category = suggestCategory(for: url.lastPathComponent)
            }
            
            // Save document
            await saveDocument(data: data, fileName: url.lastPathComponent)
            
        } catch {
            errorMessage = "Failed to process document: \(error.localizedDescription)"
        }
    }
    
    private func processScannedDocument(_ pdfData: Data) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Auto-fill name if empty
        if documentName.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            documentName = "Scan \(formatter.string(from: Date()))"
        }
        
        await saveDocument(data: pdfData, fileName: "\(documentName).pdf")
    }
    
    private func saveDocument(data: Data, fileName: String) async {
        do {
            let fileSize = Int64(data.count)
            let mimeType = getMimeType(for: fileName)
            let documentType = Document.DocumentType.from(mimeType: mimeType)
            
            // Extract additional info for PDFs
            var pageCount: Int?
            var searchableText: String?
            var thumbnailData: Data?
            
            if documentType == .pdf {
                pageCount = pdfService.getPageCount(from: data)
                searchableText = await pdfService.extractText(from: data)
                if let thumbnail = pdfService.generateThumbnail(from: data) {
                    thumbnailData = thumbnail.pngData()
                }
            }
            
            // Create document
            let document = Document(
                name: documentName.isEmpty ? fileName : documentName,
                type: documentType,
                category: category,
                subcategory: subcategory,
                fileSize: fileSize,
                mimeType: mimeType,
                itemId: itemId,
                tags: tags,
                notes: notes.isEmpty ? nil : notes,
                pageCount: pageCount,
                thumbnailData: thumbnailData,
                searchableText: searchableText
            )
            
            // Save document data
            _ = try await documentStorage.saveDocument(data, documentId: document.id)
            
            // Save document record
            try await documentRepository.save(document)
            
            // Dismiss sheet
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save document: \(error.localizedDescription)"
            }
        }
    }
    
    private func getMimeType(for filename: String) -> String {
        let pathExtension = (filename as NSString).pathExtension
        if let uti = UTType(filenameExtension: pathExtension) {
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
        } else if lowercased.contains("insurance") || lowercased.contains("policy") {
            return .insurance
        } else if lowercased.contains("contract") || lowercased.contains("agreement") {
            return .contract
        } else if lowercased.contains("spec") || lowercased.contains("specification") {
            return .specification
        } else {
            return .other
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing document...")
                    .font(.headline)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Tag Input Field
struct TagInputField: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .foregroundStyle(.secondary)
            
            // Existing tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(
                                name: tag,
                                color: .accentColor,
                                onDelete: {
                                    tags.removeAll { $0 == tag }
                                }
                            )
                        }
                    }
                }
            }
            
            // Add new tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
                .disabled(newTag.isEmpty)
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}