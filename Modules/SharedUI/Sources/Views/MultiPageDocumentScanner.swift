import SwiftUI
import VisionKit
import Core

/// SwiftUI wrapper for multi-page document scanning
/// Swift 5.9 - No Swift 6 features
@available(iOS 16.0, *)
public struct MultiPageDocumentScanner: UIViewControllerRepresentable {
    let onCompletion: (Result<Data, Error>) -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(onCompletion: @escaping (Result<Data, Error>) -> Void) {
        self.onCompletion = onCompletion
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: MultiPageDocumentScanner
        private let pdfService = PDFService()
        
        init(_ parent: MultiPageDocumentScanner) {
            self.parent = parent
        }
        
        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            Task {
                do {
                    let pdfData = try await processScannedPages(scan)
                    await MainActor.run {
                        parent.onCompletion(.success(pdfData))
                    }
                } catch {
                    await MainActor.run {
                        parent.onCompletion(.failure(error))
                    }
                }
            }
        }
        
        public func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            parent.onCompletion(.failure(DocumentScannerError.cancelled))
        }
        
        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onCompletion(.failure(error))
        }
        
        private func processScannedPages(_ scan: VNDocumentCameraScan) async throws -> Data {
            var pageImages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                pageImages.append(scannedImage)
            }
            
            guard let pdfData = await createPDFFromImages(pageImages) else {
                throw DocumentScannerError.pdfCreationFailed
            }
            
            return pdfData
        }
        
        private func createPDFFromImages(_ images: [UIImage]) async -> Data? {
            let pdfDocument = NSMutableData()
            
            UIGraphicsBeginPDFContextToData(pdfDocument, .zero, nil)
            
            for image in images {
                let bounds = CGRect(origin: .zero, size: image.size)
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                
                image.draw(in: bounds)
            }
            
            UIGraphicsEndPDFContext()
            
            return pdfDocument as Data
        }
    }
}

/// Document scanner errors
public enum DocumentScannerError: LocalizedError {
    case cancelled
    case pdfCreationFailed
    case noPages
    
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Document scanning was cancelled"
        case .pdfCreationFailed:
            return "Failed to create PDF from scanned pages"
        case .noPages:
            return "No pages were scanned"
        }
    }
}

/// SwiftUI button for initiating multi-page document scanning
@available(iOS 16.0, *)
public struct MultiPageDocumentScannerButton: View {
    let title: String
    let onScan: (Data) -> Void
    
    @State private var showingScanner = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init(
        title: String = "Scan Multi-Page Document",
        onScan: @escaping (Data) -> Void
    ) {
        self.title = title
        self.onScan = onScan
    }
    
    public var body: some View {
        Button(action: { showingScanner = true }) {
            Label(title, systemImage: "doc.text.viewfinder")
        }
        .sheet(isPresented: $showingScanner) {
            MultiPageDocumentScanner { result in
                showingScanner = false
                
                switch result {
                case .success(let data):
                    onScan(data)
                case .failure(let error):
                    if case DocumentScannerError.cancelled = error {
                        // User cancelled, no need to show error
                        return
                    }
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
        .alert("Scanning Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}