import SwiftUI
import PDFKit

/// Enhanced PDF viewer with multi-page support and thumbnails
/// Swift 5.9 - No Swift 6 features
public struct PDFViewerEnhanced: View {
    let url: URL
    let title: String
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0
    @State private var showingThumbnails = false
    @State private var showingPageJumper = false
    @State private var pageNumberText = ""
    @State private var pdfDocument: PDFDocument?
    @State private var displayMode: PDFDisplayMode = .singlePageContinuous
    @State private var scaleFactor: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss
    
    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Main PDF View
                PDFViewerRepresentable(
                    url: url,
                    currentPage: $currentPage,
                    totalPages: $totalPages,
                    pdfDocument: $pdfDocument,
                    displayMode: displayMode,
                    scaleFactor: scaleFactor
                )
                
                // Page controls overlay
                VStack {
                    Spacer()
                    
                    if totalPages > 1 {
                        pageControlsOverlay
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        // Display mode options
                        Section("Display Mode") {
                            Button(action: { displayMode = .singlePageContinuous }) {
                                Label("Continuous", systemImage: "doc.text")
                            }
                            Button(action: { displayMode = .singlePage }) {
                                Label("Single Page", systemImage: "doc")
                            }
                            Button(action: { displayMode = .twoUp }) {
                                Label("Two Pages", systemImage: "doc.on.doc")
                            }
                        }
                        
                        // Zoom options
                        Section("Zoom") {
                            Button(action: { scaleFactor = 0.5 }) {
                                Label("50%", systemImage: "minus.magnifyingglass")
                            }
                            Button(action: { scaleFactor = 1.0 }) {
                                Label("100%", systemImage: "magnifyingglass")
                            }
                            Button(action: { scaleFactor = 1.5 }) {
                                Label("150%", systemImage: "plus.magnifyingglass")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button(action: { showingThumbnails = true }) {
                        Image(systemName: "square.grid.2x2")
                    }
                    .disabled(totalPages <= 1)
                    
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingThumbnails) {
                PDFThumbnailsView(
                    pdfDocument: pdfDocument,
                    currentPage: $currentPage,
                    isPresented: $showingThumbnails
                )
            }
        }
    }
    
    private var pageControlsOverlay: some View {
        VStack(spacing: 12) {
            // Page info
            HStack {
                Button(action: { showingPageJumper = true }) {
                    Text("Page \(currentPage) of \(totalPages)")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .popover(isPresented: $showingPageJumper) {
                    pageJumperView
                }
            }
            
            // Navigation buttons
            HStack(spacing: 24) {
                Button(action: goToFirstPage) {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .disabled(currentPage <= 1)
                
                Button(action: goToPreviousPage) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .disabled(currentPage <= 1)
                
                Button(action: goToNextPage) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .disabled(currentPage >= totalPages)
                
                Button(action: goToLastPage) {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .disabled(currentPage >= totalPages)
            }
            .padding(.bottom, 20)
        }
    }
    
    private var pageJumperView: some View {
        VStack(spacing: 16) {
            Text("Go to Page")
                .font(.headline)
            
            HStack {
                TextField("Page number", text: $pageNumberText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                
                Text("/ \(totalPages)")
                    .foregroundStyle(.secondary)
            }
            
            Button("Go") {
                if let pageNumber = Int(pageNumberText),
                   pageNumber > 0 && pageNumber <= totalPages {
                    currentPage = pageNumber
                    showingPageJumper = false
                    pageNumberText = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pageNumberText.isEmpty)
        }
        .padding()
        .frame(width: 200)
    }
    
    private func goToFirstPage() {
        currentPage = 1
    }
    
    private func goToLastPage() {
        currentPage = totalPages
    }
    
    private func goToPreviousPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
    }
    
    private func goToNextPage() {
        if currentPage < totalPages {
            currentPage += 1
        }
    }
}

// MARK: - PDF Viewer UIKit Representable
struct PDFViewerRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var pdfDocument: PDFDocument?
    let displayMode: PDFDisplayMode
    let scaleFactor: CGFloat
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.delegate = context.coordinator
        pdfView.autoScales = true
        pdfView.displayMode = displayMode
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                self.pdfDocument = document
                self.totalPages = document.pageCount
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.displayMode = displayMode
        pdfView.scaleFactor = scaleFactor
        
        if let document = pdfView.document,
           currentPage > 0 && currentPage <= document.pageCount,
           let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewerRepresentable
        
        init(_ parent: PDFViewerRepresentable) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ sender: PDFView) {
            if let currentPage = sender.currentPage,
               let pageIndex = sender.document?.index(for: currentPage) {
                parent.currentPage = pageIndex + 1
            }
        }
    }
}

// MARK: - PDF Thumbnails View
struct PDFThumbnailsView: View {
    let pdfDocument: PDFDocument?
    @Binding var currentPage: Int
    @Binding var isPresented: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let document = pdfDocument {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<document.pageCount, id: \.self) { pageIndex in
                            PDFThumbnailView(
                                document: document,
                                pageIndex: pageIndex,
                                isSelected: currentPage == pageIndex + 1
                            ) {
                                currentPage = pageIndex + 1
                                isPresented = false
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("No pages available")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Individual Thumbnail View
struct PDFThumbnailView: View {
    let document: PDFDocument
    let pageIndex: Int
    let isSelected: Bool
    let action: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 150)
                            .cornerRadius(8)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                
                Text("Page \(pageIndex + 1)")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard let page = document.page(at: pageIndex) else { return }
        
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 150 / bounds.height
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        thumbnail = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}