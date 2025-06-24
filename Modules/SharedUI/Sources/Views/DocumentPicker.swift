import SwiftUI
import UniformTypeIdentifiers

/// Document picker for selecting files
/// Swift 5.9 - No Swift 6 features
public struct DocumentPicker: UIViewControllerRepresentable {
    let documentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: (Result<[URL], Error>) -> Void
    
    public init(
        documentTypes: [UTType] = [.pdf, .image],
        allowsMultipleSelection: Bool = false,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) {
        self.documentTypes = documentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onCompletion = onCompletion
    }
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onCompletion(.success(urls))
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCompletion(.failure(DocumentPickerError.cancelled))
        }
    }
}

// MARK: - Error Types
public enum DocumentPickerError: LocalizedError {
    case cancelled
    case accessDenied
    case unsupportedType
    
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Document selection was cancelled"
        case .accessDenied:
            return "Access to the document was denied"
        case .unsupportedType:
            return "The selected document type is not supported"
        }
    }
}

// MARK: - SwiftUI Wrapper View
public struct DocumentPickerButton: View {
    let title: String
    let documentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onSelection: ([URL]) -> Void
    
    @State private var showingPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init(
        title: String = "Select Document",
        documentTypes: [UTType] = [.pdf],
        allowsMultipleSelection: Bool = false,
        onSelection: @escaping ([URL]) -> Void
    ) {
        self.title = title
        self.documentTypes = documentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onSelection = onSelection
    }
    
    public var body: some View {
        Button(action: { showingPicker = true }) {
            Label(title, systemImage: "doc.badge.plus")
        }
        .sheet(isPresented: $showingPicker) {
            DocumentPicker(
                documentTypes: documentTypes,
                allowsMultipleSelection: allowsMultipleSelection
            ) { result in
                switch result {
                case .success(let urls):
                    onSelection(urls)
                case .failure(let error):
                    if case DocumentPickerError.cancelled = error {
                        // User cancelled, no need to show error
                        return
                    }
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}