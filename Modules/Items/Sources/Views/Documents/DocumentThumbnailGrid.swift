import SwiftUI
import Core
import SharedUI
import QuickLook

/// Grid view showing document thumbnails for quick preview
/// Swift 5.9 - No Swift 6 features
struct DocumentThumbnailGrid: View {
    let documents: [Document]
    let documentStorage: DocumentStorageProtocol
    let onSelectDocument: (Document) -> Void
    let onDeleteDocument: ((Document) -> Void)?
    
    @State private var thumbnails: [UUID: UIImage] = [:]
    @State private var loadingThumbnails: Set<UUID> = []
    @State private var selectedForPreview: Document?
    @State private var showingQuickLook = false
    
    private let thumbnailService = try? ThumbnailService()
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(documents) { document in
                    DocumentThumbnailCard(
                        document: document,
                        thumbnail: thumbnails[document.id],
                        isLoading: loadingThumbnails.contains(document.id),
                        onTap: {
                            selectedForPreview = document
                            showingQuickLook = true
                        },
                        onSelect: {
                            onSelectDocument(document)
                        },
                        onDelete: onDeleteDocument != nil ? {
                            onDeleteDocument?(document)
                        } : nil
                    )
                    .task {
                        await loadThumbnail(for: document)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingQuickLook) {
            if let document = selectedForPreview {
                DocumentQuickLookView(
                    document: document,
                    documentStorage: documentStorage,
                    thumbnailService: thumbnailService,
                    onClose: {
                        showingQuickLook = false
                    },
                    onOpenFull: {
                        showingQuickLook = false
                        onSelectDocument(document)
                    }
                )
            }
        }
    }
    
    private func loadThumbnail(for document: Document) async {
        guard thumbnails[document.id] == nil,
              !loadingThumbnails.contains(document.id),
              let thumbnailService = thumbnailService else { return }
        
        // Check if thumbnail already exists in document
        if let thumbnailData = document.thumbnailData,
           let image = UIImage(data: thumbnailData) {
            thumbnails[document.id] = image
            return
        }
        
        loadingThumbnails.insert(document.id)
        
        // Check cached thumbnail first
        if let cachedThumbnail = thumbnailService.getCachedThumbnail(for: document.id) {
            thumbnails[document.id] = cachedThumbnail
            loadingThumbnails.remove(document.id)
            return
        }
        
        // Generate thumbnail
        guard let url = documentStorage.getDocumentURL(documentId: document.id),
              let data = try? Data(contentsOf: url) else {
            loadingThumbnails.remove(document.id)
            return
        }
        
        let thumbnail = await thumbnailService.generateThumbnail(
            for: document.id,
            from: data,
            mimeType: document.mimeType
        )
        
        if let thumbnail = thumbnail {
            thumbnails[document.id] = thumbnail
        }
        loadingThumbnails.remove(document.id)
    }
}

// MARK: - Thumbnail Card
struct DocumentThumbnailCard: View {
    let document: Document
    let thumbnail: UIImage?
    let isLoading: Bool
    let onTap: () -> Void
    let onSelect: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            thumbnailView
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .overlay(alignment: .topTrailing) {
                    // Document type badge
                    documentTypeBadge
                        .padding(8)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label(document.category.displayName, systemImage: document.category.icon)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: document.category.color))
                    
                    Spacer()
                    
                    Text(document.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {
                // Show context menu
                showContextMenu()
            }
        )
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if isLoading {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                
                ProgressView()
                    .scaleEffect(0.8)
            }
        } else if let thumbnail = thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            ZStack {
                Rectangle()
                    .fill(Color(hex: document.category.color).opacity(0.1))
                
                Image(systemName: document.type.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: document.category.color))
            }
        }
    }
    
    private var documentTypeBadge: some View {
        Group {
            if document.pageCount ?? 1 > 1 {
                HStack(spacing: 2) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.caption2)
                    Text("\(document.pageCount ?? 0)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
    }
    
    private func showContextMenu() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // In a real implementation, this would show a context menu
        // For now, we'll trigger the select action
        onSelect()
    }
}

// MARK: - Quick Look View
struct DocumentQuickLookView: View {
    let document: Document
    let documentStorage: DocumentStorageProtocol
    let thumbnailService: ThumbnailService?
    let onClose: () -> Void
    let onOpenFull: () -> Void
    
    @State private var currentPage = 0
    @State private var pageThumbnails: [Int: UIImage] = [:]
    @State private var isLoadingPages = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Document preview
                if document.isPDF && (document.pageCount ?? 1) > 1 {
                    TabView(selection: $currentPage) {
                        ForEach(0..<(document.pageCount ?? 1), id: \.self) { pageIndex in
                            if let thumbnail = pageThumbnails[pageIndex] {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .tag(pageIndex)
                            } else {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(.systemGray6))
                                    .tag(pageIndex)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else if let url = documentStorage.getDocumentURL(documentId: document.id) {
                    // Single page or non-PDF document
                    DocumentPreviewController(url: url)
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            HStack {
                                Label(document.category.displayName, systemImage: document.category.icon)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: document.category.color))
                                
                                if let subcategory = document.subcategory {
                                    Text("• \(subcategory)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            if let pageCount = document.pageCount, pageCount > 1 {
                                Text("Page \(currentPage + 1) of \(pageCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(document.formattedFileSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: onOpenFull) {
                            Label("Open Full View", systemImage: "arrow.up.left.and.arrow.down.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        ShareLink(item: documentStorage.getDocumentURL(documentId: document.id) ?? URL(string: "https://example.com")!) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onClose)
                }
            }
            .task {
                await loadPageThumbnails()
            }
        }
    }
    
    private func loadPageThumbnails() async {
        guard document.isPDF,
              let pageCount = document.pageCount,
              pageCount > 1,
              let url = documentStorage.getDocumentURL(documentId: document.id),
              let data = try? Data(contentsOf: url),
              let thumbnailService = thumbnailService else { return }
        
        isLoadingPages = true
        
        let thumbnails = await thumbnailService.generatePageThumbnails(
            for: document.id,
            from: data,
            pageCount: pageCount,
            size: CGSize(width: 300, height: 400)
        )
        
        pageThumbnails = thumbnails
        isLoadingPages = false
    }
}

// MARK: - Document Preview Controller
struct DocumentPreviewController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let quickLookController = QLPreviewController()
        quickLookController.dataSource = context.coordinator
        context.coordinator.url = url
        return quickLookController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL?
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return url != nil ? 1 : 0
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url! as QLPreviewItem
        }
    }
}