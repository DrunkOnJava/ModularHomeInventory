import SwiftUI
import Core
import SharedUI
import Gmail

/// Receipt import view with Gmail integration
/// Swift 5.9 - No Swift 6 features
struct ReceiptImportView: View {
    @StateObject private var viewModel: ReceiptImportViewModel
    @StateObject private var gmailModule = GmailModule()
    @State private var selectedImportMethod: ImportMethod?
    @State private var showingGmailImport = false
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var importedCount = 0
    
    enum ImportMethod: String, CaseIterable {
        case gmail = "Gmail"
        case camera = "Camera"
        case files = "Files"
        
        var icon: String {
            switch self {
            case .gmail: return "envelope.fill"
            case .camera: return "camera.fill"
            case .files: return "folder.fill"
            }
        }
        
        var description: String {
            switch self {
            case .gmail: return "Import receipts from Gmail"
            case .camera: return "Scan receipt with camera"
            case .files: return "Import from files"
            }
        }
    }
    
    init(viewModel: ReceiptImportViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(ImportMethod.allCases, id: \.self) { method in
                        Button(action: {
                            handleImportMethod(method)
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: method.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(method.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if method == .gmail && !gmailModule.isAuthenticated {
                                    Text("Not Connected")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Import Methods")
                }
                
                if importedCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(importedCount) receipts imported successfully")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Import Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingGmailImport) {
                gmailModule.makeReceiptImportView()
                    .presentationDetents([.large])
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") {
                    importError = nil
                }
            } message: {
                if let error = importError {
                    Text(error.localizedDescription)
                }
            }
            .overlay {
                if isImporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Importing receipts...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(32)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                        }
                }
            }
        }
    }
    
    private func handleImportMethod(_ method: ImportMethod) {
        switch method {
        case .gmail:
            if gmailModule.isAuthenticated {
                importFromGmail()
            } else {
                showingGmailImport = true
            }
        case .camera:
            selectedImportMethod = method
        case .files:
            selectedImportMethod = method
        }
    }
    
    private func importFromGmail() {
        isImporting = true
        importError = nil
        
        Task {
            do {
                let receipts = try await gmailModule.fetchReceipts()
                
                await MainActor.run {
                    // Save receipts to repository
                    for receipt in receipts {
                        viewModel.saveReceipt(receipt)
                    }
                    
                    importedCount = receipts.count
                    isImporting = false
                    
                    // Show success message
                    if receipts.isEmpty {
                        importError = NSError(
                            domain: "ReceiptImport",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "No receipts found in Gmail"]
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    importError = error
                    isImporting = false
                }
            }
        }
    }
}
