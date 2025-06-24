import SwiftUI
import Core
import SharedUI

/// View for adding or editing a warranty
/// Swift 5.9 - No Swift 6 features
struct AddEditWarrantyView: View {
    @StateObject private var viewModel: AddEditWarrantyViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    init(viewModel: AddEditWarrantyViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    enum Field: Hashable {
        case provider, registration, phone, email, website, details, notes
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Item selection (only for new warranties)
                if viewModel.warranty == nil {
                    itemSection
                }
                
                // Warranty details
                warrantyDetailsSection
                
                // Coverage period
                coveragePeriodSection
                
                // Contact information
                contactSection
                
                // Additional details
                additionalDetailsSection
            }
            .navigationTitle(viewModel.warranty == nil ? "Add Warranty" : "Edit Warranty")
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
        }
    }
    
    // MARK: - Sections
    
    private var itemSection: some View {
        Section {
            Picker("Item", selection: $viewModel.selectedItemId) {
                Text("Select an item").tag(nil as UUID?)
                ForEach(viewModel.items) { item in
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundStyle(AppColors.primary)
                        Text(item.name)
                    }
                    .tag(item.id as UUID?)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Item")
        } footer: {
            Text("Select the item this warranty covers")
                .textStyle(.labelSmall)
        }
    }
    
    private var warrantyDetailsSection: some View {
        Section {
            // Provider
            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)
                
                TextField("Provider Name", text: $viewModel.provider)
                    .focused($focusedField, equals: .provider)
                    .textContentType(.organizationName)
            }
            
            // Common providers picker
            if !WarrantyProvider.commonProviders.isEmpty && viewModel.provider.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(WarrantyProvider.commonProviders, id: \.name) { provider in
                            Button(action: {
                                viewModel.selectProvider(provider)
                            }) {
                                Text(provider.name)
                                    .textStyle(.labelMedium)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AppColors.primary.opacity(0.1))
                                    .foregroundStyle(AppColors.primary)
                                    .cornerRadius(AppCornerRadius.small)
                            }
                        }
                    }
                }
            }
            
            // Type
            Picker("Type", selection: $viewModel.type) {
                ForEach(WarrantyType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            
            // Registration number
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)
                
                TextField("Registration Number (Optional)", text: $viewModel.registrationNumber)
                    .focused($focusedField, equals: .registration)
            }
        } header: {
            Text("Warranty Details")
        }
    }
    
    private var coveragePeriodSection: some View {
        Section {
            DatePicker(
                "Start Date",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )
            
            DatePicker(
                "End Date",
                selection: $viewModel.endDate,
                in: viewModel.startDate...,
                displayedComponents: .date
            )
            
            // Quick duration buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach([30, 90, 180, 365, 730], id: \.self) { days in
                        Button(action: {
                            viewModel.setDuration(days: days)
                        }) {
                            Text(durationText(for: days))
                                .textStyle(.labelMedium)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 4)
                                .background(AppColors.primary.opacity(0.1))
                                .foregroundStyle(AppColors.primary)
                                .cornerRadius(AppCornerRadius.small)
                        }
                    }
                }
            }
            
            // Extended warranty toggle
            Toggle(isOn: $viewModel.isExtended) {
                Label("Extended Warranty", systemImage: "calendar.badge.plus")
            }
            
            // Cost (if extended)
            if viewModel.isExtended {
                HStack {
                    Label("Cost", systemImage: "dollarsign.circle")
                    Spacer()
                    TextField("0.00", value: $viewModel.cost, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        } header: {
            Text("Coverage Period")
        } footer: {
            Text("Coverage ends on \(viewModel.endDate.formatted(date: .long, time: .omitted))")
                .textStyle(.labelSmall)
        }
    }
    
    private var contactSection: some View {
        Section {
            HStack {
                Image(systemName: "phone")
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)
                
                TextField("Phone Number (Optional)", text: $viewModel.phoneNumber)
                    .focused($focusedField, equals: .phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)
                
                TextField("Email (Optional)", text: $viewModel.email)
                    .focused($focusedField, equals: .email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)
                
                TextField("Website (Optional)", text: $viewModel.website)
                    .focused($focusedField, equals: .website)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
        } header: {
            Text("Contact Information")
        }
    }
    
    private var additionalDetailsSection: some View {
        Section {
            TextField("Coverage Details", text: $viewModel.coverageDetails, axis: .vertical)
                .focused($focusedField, equals: .details)
                .lineLimit(3...6)
            
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .focused($focusedField, equals: .notes)
                .lineLimit(2...4)
        } header: {
            Text("Additional Details")
        }
    }
    
    // MARK: - Helper Methods
    
    private func durationText(for days: Int) -> String {
        switch days {
        case 30: return "1 Month"
        case 90: return "3 Months"
        case 180: return "6 Months"
        case 365: return "1 Year"
        case 730: return "2 Years"
        default: return "\(days) Days"
        }
    }
}

// MARK: - View Model

@MainActor
final class AddEditWarrantyViewModel: ObservableObject {
    // Dependencies
    private let warrantyRepository: any WarrantyRepository
    private let itemRepository: any ItemRepository
    private let completion: (Warranty) -> Void
    
    // Editing state
    let warranty: Warranty?
    
    // Form fields
    @Published var selectedItemId: UUID?
    @Published var provider = ""
    @Published var type: WarrantyType = .manufacturer
    @Published var startDate = Date()
    @Published var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @Published var coverageDetails = ""
    @Published var registrationNumber = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    @Published var website = ""
    @Published var notes = ""
    @Published var isExtended = false
    @Published var cost: Decimal?
    
    // UI State
    @Published var items: [Item] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    var isValid: Bool {
        !provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (warranty != nil || selectedItemId != nil) &&
        endDate > startDate
    }
    
    init(
        warranty: Warranty? = nil,
        itemId: UUID? = nil,
        warrantyRepository: any WarrantyRepository,
        itemRepository: any ItemRepository,
        completion: @escaping (Warranty) -> Void
    ) {
        self.warranty = warranty
        self.warrantyRepository = warrantyRepository
        self.itemRepository = itemRepository
        self.completion = completion
        
        // If editing, populate fields
        if let warranty = warranty {
            self.selectedItemId = warranty.itemId
            self.provider = warranty.provider
            self.type = warranty.type
            self.startDate = warranty.startDate
            self.endDate = warranty.endDate
            self.coverageDetails = warranty.coverageDetails ?? ""
            self.registrationNumber = warranty.registrationNumber ?? ""
            self.phoneNumber = warranty.phoneNumber ?? ""
            self.email = warranty.email ?? ""
            self.website = warranty.website ?? ""
            self.notes = warranty.notes ?? ""
            self.isExtended = warranty.isExtended
            self.cost = warranty.cost
        } else if let itemId = itemId {
            self.selectedItemId = itemId
        }
        
        loadItems()
    }
    
    private func loadItems() {
        Task {
            do {
                items = try await itemRepository.fetchAll()
            } catch {
                print("Failed to load items: \(error)")
            }
        }
    }
    
    func selectProvider(_ provider: WarrantyProvider) {
        self.provider = provider.name
        self.phoneNumber = provider.phoneNumber ?? ""
        self.email = provider.email ?? ""
        self.website = provider.website ?? ""
    }
    
    func setDuration(days: Int) {
        endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? endDate
    }
    
    func save() async {
        guard isValid else { return }
        
        let warranty = Warranty(
            id: self.warranty?.id ?? UUID(),
            itemId: self.warranty?.itemId ?? selectedItemId!,
            type: type,
            provider: provider.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: endDate,
            coverageDetails: coverageDetails.isEmpty ? nil : coverageDetails.trimmingCharacters(in: .whitespacesAndNewlines),
            registrationNumber: registrationNumber.isEmpty ? nil : registrationNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            website: website.isEmpty ? nil : website.trimmingCharacters(in: .whitespacesAndNewlines),
            documentIds: self.warranty?.documentIds ?? [],
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isExtended: isExtended,
            cost: isExtended ? cost : nil,
            createdAt: self.warranty?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        do {
            try await warrantyRepository.save(warranty)
            await MainActor.run {
                completion(warranty)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}