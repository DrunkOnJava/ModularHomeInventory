import SwiftUI
import Core
import SharedUI

// MARK: - AddEditItemView Accessibility Extension

extension AddEditItemView {
    /// Apply comprehensive VoiceOver support
    func applyAccessibility() -> some View {
        self
            .onAppear {
                // Announce the mode when view appears
                let announcement = viewModel.mode == .add ? 
                    "Add new item form opened" : 
                    "Edit \(viewModel.name) form opened"
                VoiceOverAnnouncement.announce(announcement)
            }
    }
}

// MARK: - Form Section Accessibility

extension AddEditItemView {
    /// Make basic info section accessible
    func accessibleBasicInfoSection() -> some View {
        Section {
            // Name field
            TextField("Item Name", text: $viewModel.name)
                .voiceOverTextField(
                    label: "Item name",
                    hint: "Required. Enter the name of your item",
                    errorMessage: viewModel.nameError
                )
            
            // Brand field
            TextField("Brand (optional)", text: $viewModel.brand)
                .voiceOverTextField(
                    label: "Brand",
                    hint: "Optional. Enter the manufacturer or brand"
                )
            
            // Model field
            TextField("Model (optional)", text: $viewModel.model)
                .voiceOverTextField(
                    label: "Model",
                    hint: "Optional. Enter the model number or name"
                )
            
            // Category picker
            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }
            .voiceOverLabel("Category")
            .voiceOverValue(viewModel.selectedCategory.displayName)
            .voiceOverHint("Double tap to select a category")
        } header: {
            Text("BASIC INFORMATION")
                .voiceOverHeader()
        }
    }
    
    /// Make details section accessible
    func accessibleDetailsSection() -> some View {
        Section {
            // Quantity stepper
            Stepper(value: $viewModel.quantity, in: 1...999) {
                HStack {
                    Text("Quantity")
                    Spacer()
                    Text("\(viewModel.quantity)")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .voiceOverLabel("Quantity")
            .voiceOverValue("\(viewModel.quantity) items")
            .voiceOverHint("Use swipe up or down to adjust quantity")
            
            // Condition picker
            Picker("Condition", selection: $viewModel.selectedCondition) {
                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .voiceOverLabel("Condition")
            .voiceOverValue(viewModel.selectedCondition.displayName)
            .voiceOverHint("Double tap to select condition")
            
            // Location picker
            if !viewModel.availableLocations.isEmpty {
                Picker("Location", selection: $viewModel.selectedLocationId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(viewModel.availableLocations) { location in
                        Text(location.name).tag(location.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .voiceOverLabel("Location")
                .voiceOverValue(viewModel.selectedLocationName ?? "None selected")
                .voiceOverHint("Double tap to select storage location")
            }
        } header: {
            Text("DETAILS")
                .voiceOverHeader()
        }
    }
    
    /// Make purchase info section accessible
    func accessiblePurchaseInfoSection() -> some View {
        Section {
            // Purchase price
            HStack {
                Text("Purchase Price")
                Spacer()
                TextField("0.00", value: $viewModel.purchasePrice, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .voiceOverTextField(
                        label: "Purchase price",
                        hint: "Enter the amount you paid for this item"
                    )
            }
            
            // Current value
            HStack {
                Text("Current Value")
                Spacer()
                TextField("0.00", value: $viewModel.currentValue, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .voiceOverTextField(
                        label: "Current value",
                        hint: "Enter the current market value"
                    )
            }
            
            // Purchase date
            DatePicker(
                "Purchase Date",
                selection: Binding(
                    get: { viewModel.purchaseDate ?? Date() },
                    set: { viewModel.purchaseDate = $0 }
                ),
                displayedComponents: .date
            )
            .voiceOverLabel("Purchase date")
            .voiceOverValue(viewModel.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
            .voiceOverHint("Double tap to select date")
        } header: {
            Text("PURCHASE INFORMATION")
                .voiceOverHeader()
        } footer: {
            Text("Optional. Track purchase details for insurance and value tracking.")
                .voiceOverLabel("Purchase information is optional. Use for insurance and value tracking.")
        }
    }
    
    /// Make notes section accessible
    func accessibleNotesSection() -> some View {
        Section {
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 100)
                .voiceOverLabel("Notes")
                .voiceOverHint("Optional. Add any additional information about this item")
                .onChange(of: viewModel.notes) { newValue in
                    // Limit notes length for performance
                    if newValue.count > 500 {
                        viewModel.notes = String(newValue.prefix(500))
                    }
                }
        } header: {
            Text("NOTES")
                .voiceOverHeader()
        } footer: {
            Text("\(viewModel.notes.count)/500 characters")
                .voiceOverLabel("\(viewModel.notes.count) of 500 characters used")
        }
    }
}

// MARK: - Action Buttons Accessibility

extension AddEditItemView {
    /// Make save button accessible
    func accessibleSaveButton() -> some View {
        Button(action: viewModel.save) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .voiceOverLabel("Saving")
                } else {
                    Text(viewModel.mode == .add ? "Add Item" : "Save Changes")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isValid || viewModel.isSaving)
        .voiceOverLabel(viewModel.mode == .add ? "Add item" : "Save changes")
        .voiceOverHint(viewModel.isValid ? 
            "Double tap to save" : 
            "Item name is required before saving")
    }
    
    /// Make cancel button accessible
    func accessibleCancelButton() -> some View {
        Button("Cancel", role: .cancel, action: viewModel.cancel)
            .voiceOverLabel("Cancel")
            .voiceOverHint("Double tap to discard changes and close")
    }
}

// MARK: - Photo Section Accessibility

extension AddEditItemView {
    /// Make photo section accessible
    func accessiblePhotoSection() -> some View {
        Section {
            if viewModel.photos.isEmpty {
                Button(action: { viewModel.showingPhotoPicker = true }) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                        Text("Add Photos")
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                    }
                }
                .voiceOverLabel("Add photos")
                .voiceOverHint("Double tap to add photos from camera or library")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                            photoThumbnail(photo: photo, index: index)
                        }
                        
                        addPhotoButton()
                    }
                }
                .voiceOverLabel("Photos")
                .voiceOverValue("\(viewModel.photos.count) photos added")
                .voiceOverHint("Swipe to browse photos")
            }
        } header: {
            Text("PHOTOS")
                .voiceOverHeader()
        }
    }
    
    private func photoThumbnail(photo: Photo, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(AppCornerRadius.small)
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(AppColors.surface)
                    .frame(width: 80, height: 80)
                    .overlay {
                        ProgressView()
                    }
            }
            
            // Delete button
            Button(action: { viewModel.removePhoto(at: index) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white, AppColors.error)
            }
            .offset(x: 4, y: -4)
        }
        .voiceOverCombine()
        .voiceOverLabel("Photo \(index + 1) of \(viewModel.photos.count)")
        .voiceOverHint("Double tap to view options")
        .voiceOverActions([
            VoiceOverAction(name: "Delete") {
                viewModel.removePhoto(at: index)
                VoiceOverAnnouncement.announce("Photo deleted")
            }
        ])
    }
    
    private func addPhotoButton() -> some View {
        Button(action: { viewModel.showingPhotoPicker = true }) {
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(AppColors.surface)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
        }
        .voiceOverLabel("Add more photos")
        .voiceOverHint("Double tap to add additional photos")
    }
}

// MARK: - Scanner Integration Accessibility

extension AddEditItemView {
    /// Make scanner button accessible
    func accessibleScannerButton() -> some View {
        Button(action: { viewModel.showingScanner = true }) {
            Label("Scan Barcode", systemImage: "barcode.viewfinder")
        }
        .voiceOverLabel("Scan barcode")
        .voiceOverHint("Double tap to scan item barcode for automatic details")
    }
}