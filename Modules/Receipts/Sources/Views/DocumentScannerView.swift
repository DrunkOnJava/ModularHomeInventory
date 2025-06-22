import SwiftUI
import VisionKit
import Core
import SharedUI

/// Document scanner view using VisionKit
/// Swift 5.9 - No Swift 6 features
@available(iOS 13.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    let completion: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                scannedImages.append(scannedImage)
            }
            
            parent.scannedImages = scannedImages
            parent.completion(scannedImages)
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // Handle error
            print("Document scanner error: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}

/// View that checks for document scanner availability
struct DocumentScannerWrapper: View {
    @Binding var scannedImages: [UIImage]
    let completion: ([UIImage]) -> Void
    @State private var showingUnavailable = false
    
    var body: some View {
        Group {
            if VNDocumentCameraViewController.isSupported {
                DocumentScannerView(
                    scannedImages: $scannedImages,
                    completion: completion
                )
            } else {
                Color.clear
                    .onAppear {
                        showingUnavailable = true
                    }
                    .alert("Scanner Unavailable", isPresented: $showingUnavailable) {
                        Button("OK") { }
                    } message: {
                        Text("Document scanning is not available on this device.")
                    }
            }
        }
    }
}

/// Multi-page document view for receipts
struct MultiPageReceiptView: View {
    let images: [UIImage]
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    let onSave: ([UIImage]) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Page indicator
                if images.count > 1 {
                    Text("Page \(currentPage + 1) of \(images.count)")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .appPadding(.top)
                }
                
                // Image viewer
                TabView(selection: $currentPage) {
                    ForEach(images.indices, id: \.self) { index in
                        Image(uiImage: images[index])
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Actions
                HStack(spacing: AppSpacing.lg) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        onSave(images)
                        dismiss()
                    }) {
                        Text("Use All Pages")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .appPadding()
            }
            .navigationTitle("Scanned Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { onSave([images[currentPage]]) }) {
                            Label("Use Current Page Only", systemImage: "doc.text")
                        }
                        
                        Button(action: { onSave(images) }) {
                            Label("Use All \(images.count) Pages", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}