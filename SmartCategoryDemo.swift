import SwiftUI
import Foundation

// Demo view showing how Smart Category integration would work
struct SmartCategoryDemoView: View {
    @State private var itemName = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var description = ""
    @State private var selectedCategory: ItemCategory = .other
    @State private var suggestedCategory: ItemCategory?
    @State private var suggestionConfidence: Double = 0
    @State private var showSuggestion = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Item Name", text: $itemName)
                        .onChange(of: itemName) { _ in
                            updateCategorySuggestion()
                        }
                    
                    TextField("Brand", text: $brand)
                        .onChange(of: brand) { _ in
                            updateCategorySuggestion()
                        }
                    
                    TextField("Model", text: $model)
                        .onChange(of: model) { _ in
                            updateCategorySuggestion()
                        }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                        .onChange(of: description) { _ in
                            updateCategorySuggestion()
                        }
                } header: {
                    Text("Item Details")
                }
                
                Section {
                    // Category Picker with suggestion
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(ItemCategory.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        // Smart suggestion
                        if showSuggestion, let suggested = suggestedCategory {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Suggested: \(suggested.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("(\(Int(suggestionConfidence * 100))% confidence)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Button("Use") {
                                    withAnimation {
                                        selectedCategory = suggested
                                        // Learn from acceptance
                                        SmartCategoryService.shared.learnFromCorrection(
                                            name: itemName,
                                            brand: brand,
                                            correctCategory: suggested
                                        )
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                // Multiple suggestions section
                if !itemName.isEmpty {
                    Section {
                        let suggestions = SmartCategoryService.shared.suggestCategories(
                            name: itemName,
                            brand: brand,
                            model: model,
                            description: description,
                            limit: 3
                        )
                        
                        ForEach(suggestions, id: \.category) { suggestion in
                            Button(action: {
                                selectedCategory = suggestion.category
                                SmartCategoryService.shared.learnFromCorrection(
                                    name: itemName,
                                    brand: brand,
                                    correctCategory: suggestion.category
                                )
                            }) {
                                HStack {
                                    Image(systemName: suggestion.category.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    Text(suggestion.category.displayName)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(suggestion.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } header: {
                        Label("AI Suggestions", systemImage: "brain")
                    } footer: {
                        Text("Tap a suggestion to apply it. The AI learns from your choices to improve future suggestions.")
                            .font(.caption)
                    }
                }
                
                // Demo explanation
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How Smart Categories Work", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• AI analyzes item name, brand, model, and description")
                        Text("• Keywords and brand names help identify categories")
                        Text("• Confidence scores show suggestion reliability")
                        Text("• The system learns from your corrections")
                        Text("• Works offline using on-device processing")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Smart Category Demo")
        }
    }
    
    private func updateCategorySuggestion() {
        guard !itemName.isEmpty else {
            showSuggestion = false
            return
        }
        
        let result = SmartCategoryService.shared.suggestCategory(
            name: itemName,
            brand: brand.isEmpty ? nil : brand,
            model: model.isEmpty ? nil : model,
            description: description.isEmpty ? nil : description
        )
        
        if result.confidence > 0.3 && result.category != .other {
            suggestedCategory = result.category
            suggestionConfidence = result.confidence
            showSuggestion = true
        } else {
            showSuggestion = false
        }
    }
}

// Example integration in AddItemView
extension View {
    func withSmartCategorySuggestion(
        itemName: String,
        brand: String?,
        model: String?,
        description: String?,
        selectedCategory: Binding<ItemCategory>
    ) -> some View {
        self.onChange(of: itemName) { _ in
            // Auto-suggest category when name changes
            if !itemName.isEmpty {
                let suggestion = SmartCategoryService.shared.suggestCategory(
                    name: itemName,
                    brand: brand,
                    model: model,
                    description: description
                )
                
                // Only auto-apply if high confidence and user hasn't manually selected
                if suggestion.confidence > 0.7 && selectedCategory.wrappedValue == .other {
                    withAnimation {
                        selectedCategory.wrappedValue = suggestion.category
                    }
                }
            }
        }
    }
}

// Usage example in a real AddItemView
struct SmartCategoryExampleUsage: View {
    @State private var name = ""
    @State private var brand = ""
    @State private var category: ItemCategory = .other
    @State private var showingSuggestion = false
    @State private var suggestedCategory: ItemCategory?
    
    var body: some View {
        Form {
            TextField("Item Name", text: $name)
                .withSmartCategorySuggestion(
                    itemName: name,
                    brand: brand,
                    model: nil,
                    description: nil,
                    selectedCategory: $category
                )
            
            // Category picker with inline suggestion
            HStack {
                Picker("Category", selection: $category) {
                    ForEach(ItemCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                
                if let suggested = suggestedCategory, suggested != category {
                    Button(action: {
                        category = suggested
                        SmartCategoryService.shared.learnFromCorrection(
                            name: name,
                            brand: brand,
                            correctCategory: suggested
                        )
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("Try: \(suggested.displayName)")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .onAppear {
            // Set up suggestion monitoring
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                updateSuggestion()
            }
        }
    }
    
    private func updateSuggestion() {
        guard !name.isEmpty else {
            suggestedCategory = nil
            return
        }
        
        let result = SmartCategoryService.shared.suggestCategory(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            model: nil,
            description: nil
        )
        
        if result.confidence > 0.4 && result.category != category && result.category != .other {
            suggestedCategory = result.category
        } else {
            suggestedCategory = nil
        }
    }
}

// Preview
struct SmartCategoryDemo_Previews: PreviewProvider {
    static var previews: some View {
        SmartCategoryDemoView()
    }
}