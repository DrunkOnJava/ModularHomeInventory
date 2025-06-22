import SwiftUI
import Core
import SharedUI
import Scanner

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
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(ItemCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
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
                
                // Add Photos Section
                Section {
                    Button(action: { viewModel.showPhotoOptions = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("Add Photos")
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
final class AddItemViewModel: ObservableObject {
    // Dependencies
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let itemTemplateRepository: any ItemTemplateRepository
    private let completion: (Item) -> Void
    weak var scannerModule: ScannerModuleAPI?
    
    // Form fields
    @Published var name = ""
    @Published var brand = ""
    @Published var model = ""
    @Published var category: ItemCategory = .other
    @Published var condition: ItemCondition = .good
    @Published var quantity = 1
    @Published var purchasePrice: Decimal?
    @Published var currentValue: Decimal?
    @Published var purchaseDate = Date()
    @Published var serialNumber = ""
    @Published var barcode = ""
    @Published var selectedLocationId: UUID?
    @Published var notes = ""
    @Published var tags: [String] = []
    @Published var photoCount = 0
    
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
        completion: @escaping (Item) -> Void
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.itemTemplateRepository = itemTemplateRepository
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
            imageIds: [],
            locationId: selectedLocationId,
            warrantyId: nil
        )
        
        do {
            try await itemRepository.createItem(newItem)
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
            }
        }
    }
}