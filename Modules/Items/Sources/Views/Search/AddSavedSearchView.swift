import SwiftUI
import Core
import SharedUI

/// View for adding a new saved search
/// Swift 5.9 - No Swift 6 features
struct AddSavedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var query: String
    @State private var searchType: SearchHistoryEntry.SearchType
    @State private var selectedColor = SavedSearchColor.all.first!
    @State private var selectedIcon = SavedSearchIcon.all.first!
    @State private var isPinned = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    let savedSearchRepository: any SavedSearchRepository
    let onSave: (SavedSearch) -> Void
    
    init(
        savedSearchRepository: any SavedSearchRepository,
        initialQuery: String = "",
        initialSearchType: SearchHistoryEntry.SearchType = .natural,
        onSave: @escaping (SavedSearch) -> Void
    ) {
        self.savedSearchRepository = savedSearchRepository
        self.onSave = onSave
        self._query = State(initialValue: initialQuery)
        self._searchType = State(initialValue: initialSearchType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                    
                    TextField("Search Query", text: $query)
                        .textFieldStyle(.plain)
                    
                    Picker("Search Type", selection: $searchType) {
                        ForEach([SearchHistoryEntry.SearchType.natural, .barcode, .advanced], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Appearance") {
                    // Icon picker
                    Button(action: {
                        showingIconPicker = true
                    }) {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: selectedIcon)
                                .foregroundStyle(Color(hex: selectedColor))
                                .frame(width: 30, height: 30)
                                .background(Color(hex: selectedColor).opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Color picker
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        HStack {
                            Text("Color")
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                
                Section {
                    Toggle("Pin to Top", isOn: $isPinned)
                }
            }
            .navigationTitle("New Saved Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSearch()
                    }
                    .disabled(name.isEmpty || query.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
        }
    }
    
    private func saveSearch() {
        let savedSearch = SavedSearch(
            name: name,
            query: query,
            searchType: searchType,
            color: selectedColor,
            icon: selectedIcon,
            isPinned: isPinned
        )
        
        Task {
            do {
                try await savedSearchRepository.save(savedSearch)
                onSave(savedSearch)
                dismiss()
            } catch {
                print("Failed to save search: \(error)")
            }
        }
    }
}

// MARK: - Edit Saved Search View
struct EditSavedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var query: String
    @State private var searchType: SearchHistoryEntry.SearchType
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var isPinned: Bool
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    let search: SavedSearch
    let savedSearchRepository: any SavedSearchRepository
    let onSave: (SavedSearch) -> Void
    
    init(
        search: SavedSearch,
        savedSearchRepository: any SavedSearchRepository,
        onSave: @escaping (SavedSearch) -> Void
    ) {
        self.search = search
        self.savedSearchRepository = savedSearchRepository
        self.onSave = onSave
        
        self._name = State(initialValue: search.name)
        self._query = State(initialValue: search.query)
        self._searchType = State(initialValue: search.searchType)
        self._selectedColor = State(initialValue: search.color)
        self._selectedIcon = State(initialValue: search.icon)
        self._isPinned = State(initialValue: search.isPinned)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                    
                    TextField("Search Query", text: $query)
                        .textFieldStyle(.plain)
                    
                    Picker("Search Type", selection: $searchType) {
                        ForEach([SearchHistoryEntry.SearchType.natural, .barcode, .advanced], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Appearance") {
                    // Icon picker
                    Button(action: {
                        showingIconPicker = true
                    }) {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: selectedIcon)
                                .foregroundStyle(Color(hex: selectedColor))
                                .frame(width: 30, height: 30)
                                .background(Color(hex: selectedColor).opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Color picker
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        HStack {
                            Text("Color")
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                
                Section {
                    Toggle("Pin to Top", isOn: $isPinned)
                }
                
                Section {
                    HStack {
                        Text("Created")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text(search.createdAt.formatted())
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    HStack {
                        Text("Last Used")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text(search.lastUsedAt.formatted())
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    HStack {
                        Text("Use Count")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(search.useCount)")
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .navigationTitle("Edit Saved Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateSearch()
                    }
                    .disabled(name.isEmpty || query.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
        }
    }
    
    private func updateSearch() {
        let updatedSearch = SavedSearch(
            id: search.id,
            name: name,
            query: query,
            searchType: searchType,
            criteria: search.criteria,
            color: selectedColor,
            icon: selectedIcon,
            createdAt: search.createdAt,
            lastUsedAt: search.lastUsedAt,
            useCount: search.useCount,
            isPinned: isPinned
        )
        
        Task {
            do {
                try await savedSearchRepository.update(updatedSearch)
                onSave(updatedSearch)
                dismiss()
            } catch {
                print("Failed to update search: \(error)")
            }
        }
    }
}

// MARK: - Icon Picker
struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SavedSearchIcon.all, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 60, height: 60)
                                .background(selectedIcon == icon ? AppColors.primary.opacity(0.2) : Color(.systemGray6))
                                .foregroundStyle(selectedIcon == icon ? AppColors.primary : AppColors.textPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Color Picker
struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SavedSearchColor.all, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    selectedColor == color ?
                                    Circle()
                                        .stroke(AppColors.textPrimary, lineWidth: 3)
                                        .padding(2)
                                    : nil
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}