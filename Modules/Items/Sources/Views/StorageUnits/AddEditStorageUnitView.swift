import SwiftUI
import Core
import SharedUI

/// View for adding or editing a storage unit
/// Swift 5.9 - No Swift 6 features
struct AddEditStorageUnitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedType: StorageUnitType
    @State private var selectedLocationId: UUID?
    @State private var description: String
    @State private var position: String
    @State private var hasCapacity: Bool
    @State private var capacity: String
    @State private var width: String
    @State private var height: String
    @State private var depth: String
    @State private var selectedUnit: MeasurementUnit
    @State private var notes: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var locations: [Location] = []
    
    let unit: StorageUnit?
    let storageUnitRepository: any StorageUnitRepository
    let locationRepository: any LocationRepository
    let onComplete: (StorageUnit) -> Void
    
    private let isEditing: Bool
    
    init(
        unit: StorageUnit? = nil,
        storageUnitRepository: any StorageUnitRepository,
        locationRepository: any LocationRepository,
        selectedLocationId: UUID? = nil,
        onComplete: @escaping (StorageUnit) -> Void
    ) {
        self.unit = unit
        self.storageUnitRepository = storageUnitRepository
        self.locationRepository = locationRepository
        self.onComplete = onComplete
        self.isEditing = unit != nil
        
        // Initialize state
        _name = State(initialValue: unit?.name ?? "")
        _selectedType = State(initialValue: unit?.type ?? .shelf)
        _selectedLocationId = State(initialValue: unit?.locationId ?? selectedLocationId)
        _description = State(initialValue: unit?.description ?? "")
        _position = State(initialValue: unit?.position ?? "")
        _hasCapacity = State(initialValue: unit?.capacity != nil)
        _capacity = State(initialValue: unit?.capacity.map { String($0) } ?? "")
        _notes = State(initialValue: unit?.notes ?? "")
        
        // Dimensions
        _width = State(initialValue: unit?.dimensions != nil ? String(unit!.dimensions!.width) : "")
        _height = State(initialValue: unit?.dimensions != nil ? String(unit!.dimensions!.height) : "")
        _depth = State(initialValue: unit?.dimensions != nil ? String(unit!.dimensions!.depth) : "")
        _selectedUnit = State(initialValue: unit?.dimensions?.unit ?? .inches)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section {
                    TextField("Storage Unit Name", text: $name)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                    
                    // Type Selection
                    Menu {
                        ForEach(StorageUnitType.allCases, id: \.self) { type in
                            Button(action: { selectedType = type }) {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundStyle(AppColors.primary)
                            Text(selectedType.rawValue)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                    }
                    
                    // Location Selection
                    if !locations.isEmpty {
                        Menu {
                            ForEach(locations) { location in
                                Button(action: { selectedLocationId = location.id }) {
                                    Label(location.name, systemImage: location.icon)
                                }
                            }
                        } label: {
                            HStack {
                                if let location = locations.first(where: { $0.id == selectedLocationId }) {
                                    Image(systemName: location.icon)
                                        .foregroundStyle(AppColors.primary)
                                    Text(location.name)
                                        .foregroundStyle(AppColors.textPrimary)
                                } else {
                                    Text("Select Location")
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            .padding(AppSpacing.sm)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppCornerRadius.small)
                        }
                    }
                } header: {
                    Text("Basic Information")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Details
                Section {
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                        .lineLimit(2...4)
                    
                    TextField("Position (e.g., Top shelf)", text: $position)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                } header: {
                    Text("Details")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Capacity
                Section {
                    Toggle(isOn: $hasCapacity) {
                        Text("Set Capacity Limit")
                            .textStyle(.bodyMedium)
                    }
                    
                    if hasCapacity {
                        HStack {
                            TextField("Maximum items", text: $capacity)
                                .keyboardType(.numberPad)
                                .padding(AppSpacing.sm)
                                .background(Color(.systemGray6))
                                .cornerRadius(AppCornerRadius.small)
                            
                            Text("items")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                } header: {
                    Text("Capacity")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Dimensions
                Section {
                    HStack(spacing: AppSpacing.sm) {
                        TextField("W", text: $width)
                            .keyboardType(.decimalPad)
                            .padding(AppSpacing.sm)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppCornerRadius.small)
                        
                        Text("×")
                            .foregroundStyle(AppColors.textSecondary)
                        
                        TextField("H", text: $height)
                            .keyboardType(.decimalPad)
                            .padding(AppSpacing.sm)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppCornerRadius.small)
                        
                        Text("×")
                            .foregroundStyle(AppColors.textSecondary)
                        
                        TextField("D", text: $depth)
                            .keyboardType(.decimalPad)
                            .padding(AppSpacing.sm)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppCornerRadius.small)
                    }
                    
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Dimensions (Optional)")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Notes
                Section {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle(isEditing ? "Edit Storage Unit" : "New Storage Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStorageUnit()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? AppColors.primary : AppColors.textTertiary)
                    .disabled(!canSave || isLoading)
                }
            }
            .disabled(isLoading)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadLocations()
            }
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && selectedLocationId != nil
    }
    
    private func loadLocations() async {
        do {
            locations = try await locationRepository.fetchAll()
        } catch {
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
        }
    }
    
    private func saveStorageUnit() {
        Task {
            isLoading = true
            do {
                let dimensions: Dimensions? = if !width.isEmpty && !height.isEmpty && !depth.isEmpty,
                   let w = Double(width), let h = Double(height), let d = Double(depth) {
                    Dimensions(width: w, height: h, depth: d, unit: selectedUnit)
                } else {
                    nil
                }
                
                let capacityValue = hasCapacity ? Int(capacity) : nil
                
                let newUnit: StorageUnit
                
                if let existingUnit = unit {
                    // Update existing unit
                    newUnit = StorageUnit(
                        id: existingUnit.id,
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        type: selectedType,
                        locationId: selectedLocationId!,
                        description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                        dimensions: dimensions,
                        position: position.isEmpty ? nil : position.trimmingCharacters(in: .whitespacesAndNewlines),
                        capacity: capacityValue,
                        currentItemCount: existingUnit.currentItemCount,
                        photoId: existingUnit.photoId,
                        notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                        createdAt: existingUnit.createdAt,
                        updatedAt: Date()
                    )
                } else {
                    // Create new unit
                    newUnit = StorageUnit(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        type: selectedType,
                        locationId: selectedLocationId!,
                        description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                        dimensions: dimensions,
                        position: position.isEmpty ? nil : position.trimmingCharacters(in: .whitespacesAndNewlines),
                        capacity: capacityValue,
                        notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                
                try await storageUnitRepository.save(newUnit)
                onComplete(newUnit)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}