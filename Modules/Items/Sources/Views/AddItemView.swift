import SwiftUI
import Core
import SharedUI
import Scanner
import PhotosUI

struct AddItemView: View {
    @StateObject private var viewModel: AddItemViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    init(viewModel: AddItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    enum Field: Hashable {
        case name, brand, model, serialNumber, barcode, notes
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Template Section
                if !viewModel.templates.isEmpty {
                    Section {
                        Button(action: { viewModel.showTemplateSheet = true }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(AppColors.primary)
                                Text("Use Template")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    } header: {
                        Text("Quick Start")
                    }
                }
                
                // Basic Information Section
                Section {
                    TextField("Item Name", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                    
                    TextField("Brand (Optional)", text: $viewModel.brand)
                        .focused($focusedField, equals: .brand)
                    
                    TextField("Model (Optional)", text: $viewModel.model)
                        .focused($focusedField, equals: .model)
                } header: {
                    Text("Basic Information")
                }
                
                // Category & Condition Section
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Picker("Category", selection: $viewModel.category) {
                            ForEach(ItemCategory.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        // Smart category suggestion
                        if viewModel.showCategorySuggestion {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppColors.primary)
                                    .font(.caption)
                                
                                Text("Suggested: \(viewModel.suggestedCategory.displayName)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.primary)
                                
                                Text("(\(Int(viewModel.suggestionConfidence * 100))% match)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Spacer()
                                
                                Button("Use") {
                                    viewModel.acceptCategorySuggestion()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    
                    Picker("Condition", selection: $viewModel.condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Label(condition.displayName, systemImage: condition.icon)
                                .tag(condition)
                        }
                    }
                    
                    HStack {
                        Label("Quantity", systemImage: "number.square")
                        Spacer()
                        Stepper("\(viewModel.quantity)", value: $viewModel.quantity, in: 1...999)
                    }
                } header: {
                    Text("Details")
                }
                
                // Purchase Information Section
                Section {
                    HStack {
                        Label("Purchase Price", systemImage: "dollarsign.circle")
                        Spacer()
                        TextField("0.00", value: $viewModel.purchasePrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Label("Current Value", systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                        TextField("0.00", value: $viewModel.currentValue, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker(
                        "Purchase Date",
                        selection: $viewModel.purchaseDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Purchase Information")
                } footer: {
                    Text("Leave blank if unknown")
                        .textStyle(.labelSmall)
                }
                
                // Identification Section
                Section {
                    TextField("Serial Number", text: $viewModel.serialNumber)
                        .focused($focusedField, equals: .serialNumber)
                    
                    HStack {
                        TextField("Barcode", text: $viewModel.barcode)
                            .focused($focusedField, equals: .barcode)
                            .disabled(viewModel.isLookingUpBarcode)
                        
                        if viewModel.isLookingUpBarcode {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button(action: { viewModel.showBarcodeScanner = true }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                    }
                } header: {
                    Text("Identification")
                } footer: {
                    if viewModel.isLookingUpBarcode {
                        Text("Looking up product information...")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.primary)
                    }
                }
                
                // Location Section
                if !viewModel.locations.isEmpty {
                    Section {
                        Picker("Location", selection: $viewModel.selectedLocationId) {
                            Text("No Location").tag(nil as UUID?)
                            ForEach(viewModel.locations) { location in
                                Label(location.name, systemImage: location.icon)
                                    .tag(location.id as UUID?)
                            }
                        }
                    } header: {
                        Text("Location")
                    }
                }
                
                // Tags Section
                Section {
                    TagInputView(
                        selectedTags: $viewModel.tags,
                        availableTags: viewModel.availableTags
                    )
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Add tags to organize and find items quickly")
                        .textStyle(.labelSmall)
                }
                
                // Notes Section
                Section {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(3...6)
                } header: {
                    Text("Additional Notes")
                }
                
                // Add Photos Section
                Section {
                    if viewModel.selectedPhotos.isEmpty {
                        Button(action: { viewModel.showPhotoOptions = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(AppColors.primary)
                                Text("Add Photos")
                                Spacer()
                            }
                        }
                    } else {
                        VStack(spacing: AppSpacing.md) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(Array(viewModel.selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                        Image(uiImage: photo)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(AppCornerRadius.small)
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: { viewModel.removePhoto(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white, Color.black.opacity(0.5))
                                                        .font(.system(size: 20))
                                                }
                                                .padding(4)
                                            }
                                    }
                                    
                                    // Add more photos button
                                    Button(action: { viewModel.showPhotoOptions = true }) {
                                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                                            .fill(AppColors.surface)
                                            .frame(width: 80, height: 80)
                                            .overlay {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 24))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            .overlay {
                                                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                                                    .strokeBorder(AppColors.border, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                            }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Photos")
                        if viewModel.photoCount > 0 {
                            Text("(\(viewModel.photoCount))")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveItem()
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
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showBarcodeScanner) {
                if let scannerView = viewModel.makeBarcodeScanner() {
                    scannerView
                }
            }
            .sheet(isPresented: $viewModel.showTemplateSheet) {
                TemplateSelectionView(
                    templates: viewModel.templates,
                    onSelect: { template in
                        viewModel.applyTemplate(template)
                    }
                )
            }
            .confirmationDialog("Add Photo", isPresented: $viewModel.showPhotoOptions) {
                Button("Take Photo") {
                    viewModel.photoSource = .camera
                    viewModel.showCamera = true
                }
                Button("Choose from Library") {
                    viewModel.photoSource = .library
                    viewModel.showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView(selectedImages: $viewModel.selectedPhotos)
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraCaptureView(capturedImage: .init(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            viewModel.selectedPhotos.append(image)
                        }
                    }
                ))
            }
        }
    }
}

@MainActor
final class AddItemViewModel: ObservableObject {
    // Dependencies
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let itemTemplateRepository: any ItemTemplateRepository
    private let photoRepository: any PhotoRepository
    private let barcodeLookupService: any BarcodeLookupService
    private let completion: (Item) -> Void
    weak var scannerModule: ScannerModuleAPI?
    
    // Form fields
    @Published var name = "" {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var brand = "" {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var model = "" {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var category: ItemCategory = .other
    @Published var condition: ItemCondition = .good
    @Published var quantity = 1
    @Published var purchasePrice: Decimal?
    @Published var currentValue: Decimal?
    @Published var purchaseDate = Date()
    @Published var serialNumber = ""
    @Published var barcode = ""
    @Published var selectedLocationId: UUID?
    @Published var notes = "" {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var tags: [String] = []
    @Published var selectedPhotos: [UIImage] = []
    
    var photoCount: Int {
        selectedPhotos.count
    }
    
    // UI State
    @Published var locations: [Location] = []
    @Published var templates: [ItemTemplate] = []
    @Published var availableTags: [Tag] = Tag.previews
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showBarcodeScanner = false
    @Published var showTemplateSheet = false
    @Published var showPhotoOptions = false
    @Published var photoSource: PhotoSource?
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var isLookingUpBarcode = false
    
    // Smart Category State
    @Published var showCategorySuggestion = false
    @Published var suggestedCategory: ItemCategory = .other
    @Published var suggestionConfidence: Double = 0
    
    enum PhotoSource {
        case camera, library
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        photoRepository: any PhotoRepository,
        barcodeLookupService: any BarcodeLookupService,
        completion: @escaping (Item) -> Void
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.photoRepository = photoRepository
        self.barcodeLookupService = barcodeLookupService
        self.completion = completion
        
        loadLocations()
        loadTemplates()
    }
    
    private func loadLocations() {
        Task {
            do {
                locations = try await locationRepository.getAllLocations()
            } catch {
                print("Failed to load locations: \(error)")
            }
        }
    }
    
    private func loadTemplates() {
        Task {
            do {
                templates = try await itemTemplateRepository.getAllTemplates()
            } catch {
                print("Failed to load templates: \(error)")
            }
        }
    }
    
    func applyTemplate(_ template: ItemTemplate) {
        name = template.name
        brand = template.brand ?? ""
        model = template.model ?? ""
        category = template.category
        condition = template.condition
        notes = template.notes ?? ""
        showTemplateSheet = false
    }
    
    func removePhoto(at index: Int) {
        guard index < selectedPhotos.count else { return }
        selectedPhotos.remove(at: index)
    }
    
    func saveItem() async {
        guard isValid else { return }
        
        let newItem = Item(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.isEmpty ? nil : model.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            condition: condition,
            quantity: quantity,
            value: currentValue,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            barcode: barcode.isEmpty ? nil : barcode.trimmingCharacters(in: .whitespacesAndNewlines),
            serialNumber: serialNumber.isEmpty ? nil : serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            imageIds: selectedPhotos.map { _ in UUID() }, // Generate IDs for each photo
            locationId: selectedLocationId,
            warrantyId: nil
        )
        
        do {
            try await itemRepository.createItem(newItem)
            
            // Save photos using PhotoRepository
            for (index, photo) in selectedPhotos.enumerated() {
                let photoId = newItem.imageIds[index]
                let photoModel = Photo(
                    id: photoId,
                    itemId: newItem.id,
                    sortOrder: index
                )
                try await photoRepository.savePhoto(photoModel, image: photo)
            }
            
            await MainActor.run {
                completion(newItem)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func makeBarcodeScanner() -> AnyView? {
        scannerModule?.makeBarcodeScannerView { [weak self] code in
            Task { @MainActor in
                self?.barcode = code
                self?.showBarcodeScanner = false
                await self?.lookupBarcodeProduct(code)
            }
        }
    }
    
    private func lookupBarcodeProduct(_ barcode: String) async {
        isLookingUpBarcode = true
        
        do {
            if let product = try await barcodeLookupService.lookupProduct(barcode: barcode) {
                // Auto-populate fields with product information
                if name.isEmpty {
                    name = product.name
                }
                if brand.isEmpty, let productBrand = product.brand {
                    brand = productBrand
                }
                if notes.isEmpty, let description = product.description {
                    notes = description
                }
                
                // Try to determine category from product category
                if let productCategory = product.category {
                    updateCategoryFromProductCategory(productCategory)
                }
                
                // Show success feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } catch {
            print("Barcode lookup failed: \(error)")
            // Continue without showing error - barcode is still saved
        }
        
        isLookingUpBarcode = false
    }
    
    private func updateCategoryFromProductCategory(_ productCategory: String) {
        let lowercased = productCategory.lowercased()
        
        // Map product categories to our item categories
        if lowercased.contains("electronic") || lowercased.contains("computer") || lowercased.contains("phone") {
            category = .electronics
        } else if lowercased.contains("furniture") || lowercased.contains("chair") || lowercased.contains("table") {
            category = .furniture
        } else if lowercased.contains("appliance") || lowercased.contains("kitchen") {
            category = .appliances
        } else if lowercased.contains("clothing") || lowercased.contains("apparel") || lowercased.contains("fashion") {
            category = .clothing
        } else if lowercased.contains("book") || lowercased.contains("media") || lowercased.contains("dvd") {
            category = .books
        } else if lowercased.contains("tool") || lowercased.contains("hardware") {
            category = .tools
        } else if lowercased.contains("sport") || lowercased.contains("fitness") || lowercased.contains("outdoor") {
            category = .sports
        } else if lowercased.contains("toy") || lowercased.contains("game") {
            category = .toys
        } else if lowercased.contains("jewelry") || lowercased.contains("watch") || lowercased.contains("accessory") {
            category = .jewelry
        } else if lowercased.contains("collectible") || lowercased.contains("antique") || lowercased.contains("vintage") {
            category = .collectibles
        }
        // If no match, keep the current category
    }
    
    // MARK: - Smart Category Methods
    
    private func updateCategorySuggestion() {
        guard !name.isEmpty else {
            showCategorySuggestion = false
            return
        }
        
        // Don't suggest if user has already manually selected a category
        guard category == .other else {
            showCategorySuggestion = false
            return
        }
        
        let result = SmartCategoryService.shared.suggestCategory(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            model: model.isEmpty ? nil : model,
            description: notes.isEmpty ? nil : notes
        )
        
        // Only show suggestion if confidence is above threshold
        if result.confidence > 0.3 && result.category != .other {
            suggestedCategory = result.category
            suggestionConfidence = result.confidence
            showCategorySuggestion = true
        } else {
            showCategorySuggestion = false
        }
    }
    
    func acceptCategorySuggestion() {
        category = suggestedCategory
        showCategorySuggestion = false
        
        // Learn from the acceptance
        SmartCategoryService.shared.learnFromCorrection(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            correctCategory: suggestedCategory
        )
    }
}