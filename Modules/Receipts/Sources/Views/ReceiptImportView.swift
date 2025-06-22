import SwiftUI
import Core
import SharedUI

/// Receipt import view
/// Swift 5.9 - No Swift 6 features
struct ReceiptImportView: View {
    @StateObject private var viewModel: ReceiptImportViewModel
    
    init(viewModel: ReceiptImportViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            FeatureUnavailableView(
                feature: "Import Receipt",
                reason: "Email and OCR import coming soon",
                icon: "doc.viewfinder"
            )
            .navigationTitle("Import Receipt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}