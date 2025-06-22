import SwiftUI
import Core
import SharedUI
import PhotosUI

/// View for adding a new receipt with photo capture
/// Swift 5.9 - No Swift 6 features
struct AddReceiptView: View {
    @StateObject private var viewModel: AddReceiptViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingDocumentScanner = false
    @State private var selectedImage: UIImage?
    @State private var scannedImages: [UIImage] = []
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case storeName, totalAmount, notes
    }
    
    init(viewModel: AddReceiptViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                photoSection
                receiptInfoSection
                itemsSection
                notesSection
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .confirmationDialog("Add Photo", isPresented: $showingImagePicker) {
                photoOptionsDialog
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingDocumentScanner) {
                documentScannerSheet
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    Task {
                        await viewModel.processImage(image)
                    }
                }
            }
            .overlay {
                processingOverlay
            }
            .sheet(isPresented: $viewModel.showingItemPicker) {
                ItemPickerView(
                    selectedItems: $viewModel.linkedItems,
                    itemRepository: viewModel.itemRepository
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var photoSection: some View {
        Section {
            if let image = selectedImage {
                receiptImageView(image)
            } else {
                photoPlaceholder
            }
        } header: {
            Text("Receipt Photo")
        } footer: {
            Text("Take a photo or select from library")
                .textStyle(.labelSmall)
        }
    }
    
    @ViewBuilder
    private var receiptInfoSection: some View {
        Section {
            TextField("Store Name", text: $viewModel.storeName)
                .focused($focusedField, equals: .storeName)
                .textContentType(.organizationName)
            
            DatePicker(
                "Date",
                selection: $viewModel.date,
                displayedComponents: [.date]
            )
            
            HStack {
                Label("Total Amount", systemImage: "dollarsign.circle")
                Spacer()
                TextField("0.00", value: $viewModel.totalAmount, format: .currency(code: "USD"))
                    .focused($focusedField, equals: .totalAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Receipt Information")
        }
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        Section {
            if viewModel.linkedItems.isEmpty {
                Button(action: { viewModel.showingItemPicker = true }) {
                    Label("Link Items", systemImage: "link")
                        .foregroundStyle(AppColors.primary)
                }
            } else {
                ForEach(viewModel.linkedItems) { item in
                    linkedItemRow(item)
                }
                
                Button(action: { viewModel.showingItemPicker = true }) {
                    Label("Add More Items", systemImage: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                }
            }
        } header: {
            Text("Linked Items")
        } footer: {
            Text("Link items from your inventory to this receipt")
                .textStyle(.labelSmall)
        }
    }
    
    @ViewBuilder
    private func linkedItemRow(_ item: Item) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .textStyle(.bodyMedium)
                if let brand = item.brand {
                    Text(brand)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer()
            Button(action: { viewModel.unlinkItem(item) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        Section {
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .focused($focusedField, equals: .notes)
                .lineLimit(3...6)
        } header: {
            Text("Additional Notes")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                Task {
                    await viewModel.saveReceipt(image: selectedImage)
                }
            }
            .disabled(!viewModel.isValid)
        }
        
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                focusedField = nil
            }
        }
    }
    
    @ViewBuilder
    private var photoOptionsDialog: some View {
        Button("Take Photo") {
            showingCamera = true
        }
        Button("Scan Document") {
            showingDocumentScanner = true
        }
        Button("Choose from Library") {
            showingImagePicker = true
        }
        Button("Cancel", role: .cancel) { }
    }
    
    @ViewBuilder
    private var documentScannerSheet: some View {
        DocumentScannerWrapper(scannedImages: $scannedImages) { images in
            if images.count == 1 {
                selectedImage = images.first
            } else if images.count > 1 {
                // For multi-page documents, process all pages
                viewModel.multiPageImages = images
                selectedImage = images.first
                Task {
                    await viewModel.processMultiPageImages(images)
                }
            }
        }
    }
    
    @ViewBuilder
    private var processingOverlay: some View {
        if viewModel.isProcessingOCR {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Processing Receipt...")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(.white)
                    }
                    .padding(AppSpacing.xl)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
        }
    }
    
    @ViewBuilder
    private var photoPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: { showingImagePicker = true }) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.primary)
                    
                    Text("Add Receipt Photo")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(AppColors.primary.opacity(0.3))
                )
            }
        }
    }
    
    @ViewBuilder
    private func receiptImageView(_ image: UIImage) -> some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
            
            Button(action: { showingImagePicker = true }) {
                Label("Change Photo", systemImage: "arrow.triangle.2.circlepath")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.primary)
            }
            .appPadding(.top, AppSpacing.sm)
        }
    }
}

// MARK: - View Model
@MainActor
final class AddReceiptViewModel: ObservableObject {
    // Form fields
    @Published var storeName = ""
    @Published var date = Date()
    @Published var totalAmount: Decimal?
    @Published var notes = ""
    @Published var linkedItems: [Item] = []
    
    // UI State
    @Published var showingItemPicker = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isProcessingOCR = false
    @Published var ocrExtractedText = ""
    @Published var showingMultiPageReceipt = false
    @Published var multiPageImages: [UIImage] = []
    
    // Dependencies
    private let receiptRepository: any ReceiptRepository
    let itemRepository: any ItemRepository
    private let ocrService: any OCRServiceProtocol
    private let completion: (Receipt) -> Void
    
    var isValid: Bool {
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        totalAmount != nil && totalAmount! > 0
    }
    
    init(
        receiptRepository: any ReceiptRepository,
        itemRepository: any ItemRepository,
        ocrService: any OCRServiceProtocol,
        completion: @escaping (Receipt) -> Void
    ) {
        self.receiptRepository = receiptRepository
        self.itemRepository = itemRepository
        self.ocrService = ocrService
        self.completion = completion
    }
    
    func unlinkItem(_ item: Item) {
        linkedItems.removeAll { $0.id == item.id }
    }
    
    func processImage(_ image: UIImage) async {
        isProcessingOCR = true
        
        do {
            #if canImport(UIKit)
            // Extract text using OCR
            let receiptData = try await ocrService.extractReceiptData(from: image)
            
            await MainActor.run {
                // Update fields with extracted data
                if let data = receiptData {
                    if let extractedStoreName = data.storeName, storeName.isEmpty {
                        storeName = extractedStoreName
                    }
                    if let extractedDate = data.date {
                        date = extractedDate
                    }
                    if let extractedTotal = data.totalAmount, totalAmount == nil {
                        totalAmount = extractedTotal
                    }
                    
                    // Store raw text for reference
                    ocrExtractedText = data.rawText
                    
                    // Show confidence level in notes if low
                    if data.confidence < 0.7 {
                        notes = "OCR Confidence: \(Int(data.confidence * 100))%\n\(notes)"
                    }
                }
                
                isProcessingOCR = false
            }
            #endif
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process image: \(error.localizedDescription)"
                showError = true
                isProcessingOCR = false
            }
        }
    }
    
    func processMultiPageImages(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        
        isProcessingOCR = true
        var combinedText = ""
        var totalConfidence: Double = 0
        var extractedDataCount = 0
        
        do {
            #if canImport(UIKit)
            // Process each page
            for (index, image) in images.enumerated() {
                let result = try await ocrService.extractText(from: image)
                combinedText += "--- Page \(index + 1) ---\n"
                combinedText += result.text + "\n\n"
                totalConfidence += result.confidence
                extractedDataCount += 1
                
                // Try to extract receipt data from the first page
                if index == 0 {
                    if let receiptData = try await ocrService.extractReceiptData(from: image) {
                        await MainActor.run {
                            // Update fields with extracted data
                            if let extractedStoreName = receiptData.storeName, storeName.isEmpty {
                                storeName = extractedStoreName
                            }
                            if let extractedDate = receiptData.date {
                                date = extractedDate
                            }
                            if let extractedTotal = receiptData.totalAmount, totalAmount == nil {
                                totalAmount = extractedTotal
                            }
                        }
                    }
                }
            }
            
            await MainActor.run {
                ocrExtractedText = combinedText
                let avgConfidence = extractedDataCount > 0 ? totalConfidence / Double(extractedDataCount) : 0
                if avgConfidence < 0.7 {
                    notes = "Multi-page scan - OCR Confidence: \(Int(avgConfidence * 100))%\n\(notes)"
                } else {
                    notes = "Multi-page receipt (\(images.count) pages)\n\(notes)"
                }
                isProcessingOCR = false
            }
            #endif
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process documents: \(error.localizedDescription)"
                showError = true
                isProcessingOCR = false
            }
        }
    }
    
    func saveReceipt(image: UIImage?) async {
        guard isValid else { return }
        
        var imageData: Data?
        if let image = image {
            imageData = image.jpegData(compressionQuality: 0.8)
        } else if !multiPageImages.isEmpty {
            // For multi-page documents, save the first page as the main image
            imageData = multiPageImages.first?.jpegData(compressionQuality: 0.8)
        }
        
        let receipt = Receipt(
            storeName: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            totalAmount: totalAmount ?? 0,
            itemIds: linkedItems.map { $0.id },
            imageData: imageData,
            rawText: ocrExtractedText.isEmpty ? (notes.isEmpty ? nil : notes) : ocrExtractedText,
            confidence: ocrExtractedText.isEmpty ? 1.0 : 0.85 // Adjust confidence based on OCR usage
        )
        
        do {
            try await receiptRepository.save(receipt)
            
            // TODO: In the future, save additional pages as separate documents or in a different format
            
            await MainActor.run {
                completion(receipt)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Item Picker View
struct ItemPickerView: View {
    @Binding var selectedItems: [Item]
    let itemRepository: any ItemRepository
    @State private var allItems: [Item] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return allItems
        }
        return allItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading items...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            ItemPickerRow(
                                item: item,
                                isSelected: selectedItems.contains(where: { $0.id == item.id }),
                                onToggle: { toggleItem(item) }
                            )
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search items")
                }
            }
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            do {
                allItems = try await itemRepository.fetchAll()
                isLoading = false
            } catch {
                print("Failed to load items: \(error)")
                isLoading = false
            }
        }
    }
    
    private func toggleItem(_ item: Item) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
}

struct ItemPickerRow: View {
    let item: Item
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if let brand = item.brand {
                        Text(brand)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
            }
        }
    }
}