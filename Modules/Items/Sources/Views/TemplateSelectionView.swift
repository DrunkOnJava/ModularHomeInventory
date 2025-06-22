import SwiftUI
import Core
import SharedUI

struct TemplateSelectionView: View {
    let templates: [ItemTemplate]
    let onSelect: (ItemTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredTemplates: [ItemTemplate] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.templateName.localizedCaseInsensitiveContains(searchText) ||
            (template.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTemplates) { template in
                    TemplateRowView(template: template)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(template)
                            dismiss()
                        }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplateRowView: View {
    let template: ItemTemplate
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: template.category.icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 44, height: 44)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(template.templateName)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack {
                    if let brand = template.brand {
                        Text(brand)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if let model = template.model {
                        Text("• \(model)")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .appPadding(.vertical, AppSpacing.xs)
    }
}