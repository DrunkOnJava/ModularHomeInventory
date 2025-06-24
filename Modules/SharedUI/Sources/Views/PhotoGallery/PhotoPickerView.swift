import SwiftUI
import PhotosUI
import Core

/// Photo picker view for selecting multiple photos
/// Swift 5.9 - No Swift 6 features
public struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    let maxSelectionCount: Int
    
    public init(
        selectedImages: Binding<[UIImage]>,
        maxSelectionCount: Int = 10
    ) {
        self._selectedImages = selectedImages
        self.maxSelectionCount = maxSelectionCount
    }
    
    public var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelectionCount,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Select Photos", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
}

/// Camera capture view
public struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    public init(capturedImage: Binding<UIImage?>) {
        self._capturedImage = capturedImage
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}