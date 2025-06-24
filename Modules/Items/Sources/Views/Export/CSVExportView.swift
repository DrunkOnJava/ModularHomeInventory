import SwiftUI
import Core
import SharedUI

/// CSV export view for exporting inventory data
/// Swift 5.9 - No Swift 6 features
struct CSVExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CSVExportViewModel
    @State private var selectedTemplate = Core.CSVExportTemplate.basic
    @State private var showingFieldSelector = false
    @State private var showingShareSheet = false
    
    init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        items: [Item]? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: CSVExportViewModel(
            exportService: Core.CSVExportService(
                itemRepository: itemRepository,
                locationRepository: locationRepository
            ),
            items: items
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                exportScopeSection
                templateSection
                configurationSection
                previewSection
            }
            .navigationTitle("Export to CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        Task {
                            await viewModel.exportCSV()
                            showingShareSheet = true
                        }
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            .sheet(isPresented: $showingFieldSelector) {
                FieldSelectorView(configuration: $viewModel.configuration)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let result = viewModel.exportResult {
                    ShareSheet(items: [CSVFileDocument(result: result)])
                }
            }
            .alert("Export Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.configuration = selectedTemplate.configuration
                Task {
                    await viewModel.generatePreview()
                }
            }
            .onChange(of: viewModel.configuration) { _ in
                Task {
                    await viewModel.generatePreview()
                }
            }
        }
    }
    
    private var exportScopeSection: some View {
        Section("Export Scope") {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(AppColors.primary)
                        
                        Text(viewModel.exportScopeText)
                            .font(.system(size: 15))
                        
                        Spacer()
                        
                        if viewModel.items != nil {
                            Text("\(viewModel.items!.count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
        }
    }
    
    private var templateSection: some View {
        Section("Template") {
                    ForEach(Core.CSVExportTemplate.allTemplates) { template in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 15))
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedTemplate.id == template.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTemplate = template
                            viewModel.configuration = template.configuration
                        }
                    }
        }
    }
    
    private var configurationSection: some View {
        Section("Configuration") {
                    // Delimiter
                    Picker("Delimiter", selection: Binding(
                        get: { viewModel.configuration.delimiter },
                        set: { viewModel.updateDelimiter($0) }
                    )) {
                        Text("Comma (,)").tag(",")
                        Text("Semicolon (;)").tag(";")
                        Text("Tab").tag("\t")
                        Text("Pipe (|)").tag("|")
                    }
                    
                    // Include headers
                    Toggle("Include Headers", isOn: Binding(
                        get: { viewModel.configuration.includeHeaders },
                        set: { viewModel.updateIncludeHeaders($0) }
                    ))
                    
                    // Date format
                    Picker("Date Format", selection: Binding(
                        get: { viewModel.configuration.dateFormat },
                        set: { viewModel.updateDateFormat($0) }
                    )) {
                        Text("YYYY-MM-DD").tag("yyyy-MM-dd")
                        Text("MM/DD/YYYY").tag("MM/dd/yyyy")
                        Text("DD/MM/YYYY").tag("dd/MM/yyyy")
                        Text("MMM DD, YYYY").tag("MMM dd, yyyy")
                    }
                    
                    // Fields selection
                    HStack {
                        Text("Fields")
                        
                        Spacer()
                        
                        Button(action: { showingFieldSelector = true }) {
                            HStack(spacing: 4) {
                                if viewModel.configuration.includeAllFields {
                                    Text("All Fields")
                                } else {
                                    Text("\(viewModel.configuration.selectedFields.count) Selected")
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Sort options
                    Picker("Sort By", selection: Binding(
                        get: { viewModel.configuration.sortBy },
                        set: { viewModel.updateSortBy($0) }
                    )) {
                        ForEach(Core.CSVExportSortField.allCases, id: \.self) { field in
                            Text(field.displayName).tag(field)
                        }
                    }
                    
                    Toggle("Ascending", isOn: Binding(
                        get: { viewModel.configuration.sortAscending },
                        set: { viewModel.updateSortAscending($0) }
                    ))
        }
    }
    
    private var previewSection: some View {
        Section("Preview") {
                    if viewModel.isGeneratingPreview {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating preview...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(viewModel.previewText)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
            }
        }
    }
}

// MARK: - Field Selector View

struct FieldSelectorView: View {
    @Binding var configuration: Core.CSVExportConfiguration
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFields: Set<Core.CSVExportField>
    @State private var includeAll: Bool
    
    init(configuration: Binding<Core.CSVExportConfiguration>) {
        self._configuration = configuration
        self._selectedFields = State(initialValue: configuration.wrappedValue.selectedFields)
        self._includeAll = State(initialValue: configuration.wrappedValue.includeAllFields)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Include All Fields", isOn: $includeAll)
                        .onChange(of: includeAll) { newValue in
                            if newValue {
                                selectedFields = Set(Core.CSVExportField.allCases)
                            }
                        }
                }
                
                Section("Available Fields") {
                    ForEach(Core.CSVExportField.allCases, id: \.self) { field in
                        HStack {
                            Text(field.displayName)
                                .foregroundStyle(includeAll ? .secondary : .primary)
                            
                            Spacer()
                            
                            if includeAll || selectedFields.contains(field) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !includeAll {
                                if selectedFields.contains(field) {
                                    selectedFields.remove(field)
                                } else {
                                    selectedFields.insert(field)
                                }
                            }
                        }
                        .disabled(includeAll)
                    }
                }
            }
            .navigationTitle("Select Fields")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Update configuration by creating a new instance
                        let newConfig = Core.CSVExportConfiguration(
                            delimiter: configuration.delimiter,
                            includeHeaders: configuration.includeHeaders,
                            encoding: configuration.encoding,
                            dateFormat: configuration.dateFormat,
                            currencySymbol: configuration.currencySymbol,
                            includeAllFields: includeAll,
                            selectedFields: selectedFields,
                            sortBy: configuration.sortBy,
                            sortAscending: configuration.sortAscending
                        )
                        // Update parent's configuration
                        dismiss()
                    }
                    .disabled(!includeAll && selectedFields.isEmpty)
                }
            }
        }
    }
}

// MARK: - CSV File Document

struct CSVFileDocument: Transferable {
    let result: Core.CSVExportResult
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            document.result.data
        }
        .suggestedFileName { document in
            document.result.fileName
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Model

@MainActor
final class CSVExportViewModel: ObservableObject {
    @Published var configuration = Core.CSVExportConfiguration()
    @Published var isExporting = false
    @Published var isGeneratingPreview = false
    @Published var exportResult: Core.CSVExportResult?
    @Published var previewText = ""
    @Published var showingError = false
    @Published var errorMessage = ""
    
    let exportService: Core.CSVExportService
    let items: [Item]?
    
    var exportScopeText: String {
        if let items = items {
            return "Selected Items (\(items.count))"
        } else {
            return "All Items"
        }
    }
    
    init(exportService: Core.CSVExportService, items: [Item]? = nil) {
        self.exportService = exportService
        self.items = items
    }
    
    func exportCSV() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            exportResult = try await exportService.exportItems(
                items: items,
                configuration: configuration
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func generatePreview() async {
        isGeneratingPreview = true
        defer { isGeneratingPreview = false }
        
        do {
            // Export with limited items for preview
            let previewConfig = configuration
            let previewResult = try await exportService.exportItems(
                items: items?.prefix(5).map { $0 },
                configuration: previewConfig
            )
            
            if let previewString = String(data: previewResult.data, encoding: .utf8) {
                let lines = previewString.components(separatedBy: .newlines)
                let previewLines = lines.prefix(10).joined(separator: "\n")
                previewText = previewLines
                
                if lines.count > 10 {
                    previewText += "\n..."
                }
            }
        } catch {
            previewText = "Preview generation failed"
        }
    }
    
    // MARK: - Configuration Updates
    
    func updateDelimiter(_ delimiter: String) {
        configuration = Core.CSVExportConfiguration(
            delimiter: delimiter,
            includeHeaders: configuration.includeHeaders,
            encoding: configuration.encoding,
            dateFormat: configuration.dateFormat,
            currencySymbol: configuration.currencySymbol,
            includeAllFields: configuration.includeAllFields,
            selectedFields: configuration.selectedFields,
            sortBy: configuration.sortBy,
            sortAscending: configuration.sortAscending
        )
        Task { await generatePreview() }
    }
    
    func updateIncludeHeaders(_ includeHeaders: Bool) {
        configuration = Core.CSVExportConfiguration(
            delimiter: configuration.delimiter,
            includeHeaders: includeHeaders,
            encoding: configuration.encoding,
            dateFormat: configuration.dateFormat,
            currencySymbol: configuration.currencySymbol,
            includeAllFields: configuration.includeAllFields,
            selectedFields: configuration.selectedFields,
            sortBy: configuration.sortBy,
            sortAscending: configuration.sortAscending
        )
        Task { await generatePreview() }
    }
    
    func updateDateFormat(_ dateFormat: String) {
        configuration = Core.CSVExportConfiguration(
            delimiter: configuration.delimiter,
            includeHeaders: configuration.includeHeaders,
            encoding: configuration.encoding,
            dateFormat: dateFormat,
            currencySymbol: configuration.currencySymbol,
            includeAllFields: configuration.includeAllFields,
            selectedFields: configuration.selectedFields,
            sortBy: configuration.sortBy,
            sortAscending: configuration.sortAscending
        )
        Task { await generatePreview() }
    }
    
    func updateSortBy(_ sortBy: Core.CSVExportSortField) {
        configuration = Core.CSVExportConfiguration(
            delimiter: configuration.delimiter,
            includeHeaders: configuration.includeHeaders,
            encoding: configuration.encoding,
            dateFormat: configuration.dateFormat,
            currencySymbol: configuration.currencySymbol,
            includeAllFields: configuration.includeAllFields,
            selectedFields: configuration.selectedFields,
            sortBy: sortBy,
            sortAscending: configuration.sortAscending
        )
        Task { await generatePreview() }
    }
    
    func updateSortAscending(_ sortAscending: Bool) {
        configuration = Core.CSVExportConfiguration(
            delimiter: configuration.delimiter,
            includeHeaders: configuration.includeHeaders,
            encoding: configuration.encoding,
            dateFormat: configuration.dateFormat,
            currencySymbol: configuration.currencySymbol,
            includeAllFields: configuration.includeAllFields,
            selectedFields: configuration.selectedFields,
            sortBy: configuration.sortBy,
            sortAscending: sortAscending
        )
        Task { await generatePreview() }
    }
}