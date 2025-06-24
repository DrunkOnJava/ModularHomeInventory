import SwiftUI
import Core
import SharedUI

struct AddServiceRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddServiceRecordViewModel
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case provider, technician, description, notes, cost
    }
    
    init(
        item: Item,
        serviceRepository: ServiceRecordRepository,
        onSave: @escaping (ServiceRecord) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: AddServiceRecordViewModel(
            item: item,
            serviceRepository: serviceRepository,
            onSave: onSave
        ))
    }
    
    var body: some View {
        Form {
            // Service Type
            Section("Service Type") {
                Picker("Type", selection: $viewModel.type) {
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Date
            Section("Date") {
                DatePicker(
                    "Service Date",
                    selection: $viewModel.date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                
                Toggle("Schedule Next Service", isOn: $viewModel.hasNextService)
                
                if viewModel.hasNextService {
                    DatePicker(
                        "Next Service Date",
                        selection: $viewModel.nextServiceDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                }
            }
            
            // Provider Information
            Section("Provider") {
                TextField("Provider Name", text: $viewModel.provider)
                    .focused($focusedField, equals: .provider)
                    .autocorrectionDisabled()
                
                TextField("Technician (Optional)", text: $viewModel.technician)
                    .focused($focusedField, equals: .technician)
                    .autocorrectionDisabled()
            }
            
            // Service Details
            Section("Details") {
                TextField("Description", text: $viewModel.description, axis: .vertical)
                    .focused($focusedField, equals: .description)
                    .lineLimit(2...4)
                
                TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                    .focused($focusedField, equals: .notes)
                    .lineLimit(3...6)
            }
            
            // Cost
            Section("Cost") {
                Toggle("Under Warranty", isOn: $viewModel.wasUnderWarranty)
                
                if !viewModel.wasUnderWarranty {
                    HStack {
                        Text("$")
                        TextField("0.00", value: $viewModel.cost, format: .number.precision(.fractionLength(2)))
                            .focused($focusedField, equals: .cost)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            
            // Vehicle/Equipment specific
            if viewModel.item.category == .automotive || viewModel.item.category == .tools {
                Section("Additional Info") {
                    if viewModel.item.category == .automotive {
                        TextField("Mileage", value: $viewModel.mileage, format: .number)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("Hours Used", value: $viewModel.hoursUsed, format: .number)
                        .keyboardType(.numberPad)
                }
            }
        }
        .navigationTitle("Add Service Record")
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
                        await viewModel.save()
                        dismiss()
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
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - View Model

@MainActor
final class AddServiceRecordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var type: ServiceType = .maintenance
    @Published var date = Date()
    @Published var provider = ""
    @Published var technician = ""
    @Published var description = ""
    @Published var notes = ""
    @Published var cost: Decimal?
    @Published var wasUnderWarranty = false
    @Published var hasNextService = false
    @Published var nextServiceDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
    @Published var mileage: Int?
    @Published var hoursUsed: Int?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Properties
    let item: Item
    private let serviceRepository: ServiceRecordRepository
    private let onSave: (ServiceRecord) -> Void
    
    // MARK: - Computed Properties
    var isValid: Bool {
        !provider.isEmpty && !description.isEmpty
    }
    
    // MARK: - Initialization
    init(
        item: Item,
        serviceRepository: ServiceRecordRepository,
        onSave: @escaping (ServiceRecord) -> Void
    ) {
        self.item = item
        self.serviceRepository = serviceRepository
        self.onSave = onSave
        
        // Set default description based on type
        setDefaultDescription()
    }
    
    // MARK: - Methods
    private func setDefaultDescription() {
        switch type {
        case .maintenance:
            description = "Routine maintenance"
        case .inspection:
            description = "Annual inspection"
        case .cleaning:
            description = "Professional cleaning"
        default:
            description = ""
        }
    }
    
    func save() async {
        guard isValid else { return }
        
        let record = ServiceRecord(
            itemId: item.id,
            type: type,
            date: date,
            provider: provider,
            technician: technician.isEmpty ? nil : technician,
            description: description,
            notes: notes.isEmpty ? nil : notes,
            cost: wasUnderWarranty ? 0 : cost,
            wasUnderWarranty: wasUnderWarranty,
            nextServiceDate: hasNextService ? nextServiceDate : nil,
            mileage: mileage,
            hoursUsed: hoursUsed
        )
        
        do {
            try await serviceRepository.save(record)
            onSave(record)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}