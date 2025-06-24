import SwiftUI
import PDFKit

/// PDF viewer component for displaying PDF documents
/// Swift 5.9 - No Swift 6 features
public struct PDFViewer: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    
    public init(url: URL, currentPage: Binding<Int> = .constant(1)) {
        self.url = url
        self._currentPage = currentPage
    }
    
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.delegate = context.coordinator
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            
            // Set initial page
            if currentPage > 0 && currentPage <= document.pageCount,
               let page = document.page(at: currentPage - 1) {
                pdfView.go(to: page)
            }
        }
        
        return pdfView
    }
    
    public func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = pdfView.document,
           currentPage > 0 && currentPage <= document.pageCount,
           let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewer
        
        init(_ parent: PDFViewer) {
            self.parent = parent
        }
        
        public func pdfViewPageChanged(_ sender: PDFView) {
            if let currentPage = sender.currentPage,
               let pageIndex = sender.document?.index(for: currentPage) {
                parent.currentPage = pageIndex + 1
            }
        }
    }
}

/// SwiftUI wrapper for PDF viewing with controls
public struct PDFViewerView: View {
    let url: URL
    let title: String
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // PDF Viewer
                PDFViewer(url: url, currentPage: $currentPage)
                    .onAppear {
                        loadPageCount()
                    }
                
                // Page indicator
                if totalPages > 0 {
                    HStack {
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .overlay(
                        Divider()
                            .frame(maxWidth: .infinity)
                            .frame(height: 0.5)
                            .background(Color(.separator)),
                        alignment: .top
                    )
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func loadPageCount() {
        if let document = PDFDocument(url: url) {
            totalPages = document.pageCount
        }
    }
}

/// Share sheet for sharing PDFs
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}