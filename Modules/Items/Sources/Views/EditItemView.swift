import SwiftUI
import Core
import SharedUI
import Scanner

struct EditItemView: View {
    @StateObject private var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    init(viewModel: EditItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    enum Field: Hashable {
        case name, brand, model, serialNumber, barcode, notes
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                        
                        Button(action: { viewModel.showBarcodeScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                } header: {
                    Text("Identification")
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
                
                // Photos Section
                Section {
                    Button(action: { viewModel.showPhotoOptions = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("Manage Photos")
                            Spacer()
                            if viewModel.photoCount > 0 {
                                Text("\(viewModel.photoCount)")
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                } header: {
                    Text("Photos")
                }
                
                // Item Metadata Section
                Section {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(viewModel.item.createdAt, style: .date)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    HStack {
                        Text("Last Modified")
                        Spacer()
                        Text(viewModel.item.updatedAt, style: .date)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Edit Item")
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
                    .disabled(!viewModel.hasChanges || !viewModel.isValid)
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
            .confirmationDialog("Photo Options", isPresented: $viewModel.showPhotoOptions) {
                Button("Take Photo") {
                    viewModel.photoSource = .camera
                }
                Button("Choose from Library") {
                    viewModel.photoSource = .library
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

@MainActor
final class EditItemViewModel: ObservableObject {
    // Original item
    let item: Item
    
    // Dependencies
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let completion: (Item) -> Void
    weak var scannerModule: ScannerModuleAPI?
    
    // Form fields
    @Published var name: String {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var brand: String {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var model: String {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var category: ItemCategory
    @Published var condition: ItemCondition
    @Published var quantity: Int
    @Published var purchasePrice: Decimal?
    @Published var currentValue: Decimal?
    @Published var purchaseDate: Date
    @Published var serialNumber: String
    @Published var barcode: String
    @Published var selectedLocationId: UUID?
    @Published var notes: String {
        didSet {
            updateCategorySuggestion()
        }
    }
    @Published var tags: [String]
    @Published var photoCount: Int
    
    // UI State
    @Published var locations: [Location] = []
    @Published var availableTags: [Tag] = Tag.previews
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showBarcodeScanner = false
    @Published var showPhotoOptions = false
    @Published var photoSource: PhotoSource?
    
    // Smart Category State
    @Published var showCategorySuggestion = false
    @Published var suggestedCategory: ItemCategory = .other
    @Published var suggestionConfidence: Double = 0
    private var originalCategory: ItemCategory
    
    enum PhotoSource {
        case camera, library
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasChanges: Bool {
        name != item.name ||
        brand != (item.brand ?? "") ||
        model != (item.model ?? "") ||
        category != item.category ||
        condition != item.condition ||
        quantity != item.quantity ||
        purchasePrice != item.purchasePrice ||
        currentValue != item.value ||
        purchaseDate != (item.purchaseDate ?? Date()) ||
        serialNumber != (item.serialNumber ?? "") ||
        barcode != (item.barcode ?? "") ||
        selectedLocationId != item.locationId ||
        notes != (item.notes ?? "") ||
        tags != item.tags
    }
    
    init(
        item: Item,
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        completion: @escaping (Item) -> Void
    ) {
        self.item = item
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.completion = completion
        
        // Initialize form fields with item data
        self.name = item.name
        self.brand = item.brand ?? ""
        self.model = item.model ?? ""
        self.category = item.category
        self.condition = item.condition
        self.quantity = item.quantity
        self.purchasePrice = item.purchasePrice
        self.currentValue = item.value
        self.purchaseDate = item.purchaseDate ?? Date()
        self.serialNumber = item.serialNumber ?? ""
        self.barcode = item.barcode ?? ""
        self.selectedLocationId = item.locationId
        self.notes = item.notes ?? ""
        self.tags = item.tags
        self.photoCount = item.imageIds.count
        self.originalCategory = item.category
        
        loadLocations()
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
    
    func saveItem() async {
        guard isValid && hasChanges else { return }
        
        var updatedItem = item
        updatedItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.brand = brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.model = model.isEmpty ? nil : model.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.category = category
        updatedItem.condition = condition
        updatedItem.quantity = quantity
        updatedItem.value = currentValue
        updatedItem.purchasePrice = purchasePrice
        updatedItem.purchaseDate = purchaseDate
        updatedItem.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.barcode = barcode.isEmpty ? nil : barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.serialNumber = serialNumber.isEmpty ? nil : serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedItem.tags = tags
        updatedItem.locationId = selectedLocationId
        updatedItem.updatedAt = Date()
        
        do {
            try await itemRepository.save(updatedItem)
            await MainActor.run {
                completion(updatedItem)
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
            }
        }
    }
    
    // MARK: - Smart Category Methods
    
    private func updateCategorySuggestion() {
        guard !name.isEmpty else {
            showCategorySuggestion = false
            return
        }
        
        // Only suggest if user hasn't changed the category from the original
        guard category == originalCategory else {
            showCategorySuggestion = false
            return
        }
        
        let result = SmartCategoryService.shared.suggestCategory(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            model: model.isEmpty ? nil : model,
            description: notes.isEmpty ? nil : notes
        )
        
        // Only show suggestion if confidence is above threshold and different from current
        if result.confidence > 0.3 && result.category != category && result.category != .other {
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