import SwiftUI
import SharedUI

/// Document scanner view
/// Swift 5.9 - No Swift 6 features
struct DocumentScannerView: View {
    @StateObject private var viewModel: DocumentScannerViewModel
    
    init(viewModel: DocumentScannerViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        FeatureUnavailableView(
            feature: "Document Scanner",
            reason: "Document scanning integration coming soon",
            icon: "doc.text.viewfinder"
        )
    }
}

@MainActor
final class DocumentScannerViewModel: ObservableObject {
    private let completion: (UIImage) -> Void
    
    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
    }
    
    func handleScannedDocument(_ image: UIImage) {
        completion(image)
    }
}