import SwiftUI
import Core
import SharedUI

/// Receipt preview/edit view
/// Swift 5.9 - No Swift 6 features
struct ReceiptPreviewView: View {
    @StateObject private var viewModel: ReceiptPreviewViewModel
    
    init(viewModel: ReceiptPreviewViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            FeatureUnavailableView(
                feature: "Receipt Preview",
                reason: "Receipt editing coming soon",
                icon: "doc.text.viewfinder"
            )
            .navigationTitle("Preview Receipt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}