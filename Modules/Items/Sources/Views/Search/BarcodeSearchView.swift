import SwiftUI
import Core
import SharedUI
import BarcodeScanner

/// Barcode search view that allows finding items by scanning their barcode
/// Swift 5.9 - No Swift 6 features
struct BarcodeSearchView: View {
    @StateObject private var viewModel: BarcodeSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingScanner = false
    @State private var selectedItem: Item?
    @State private var manualBarcodeEntry = ""
    @FocusState private var isManualEntryFocused: Bool
    
    init(itemRepository: any ItemRepository, scannerModule: (any ScannerModuleAPI)?, searchHistoryRepository: (any SearchHistoryRepository)? = nil) {
        self._viewModel = StateObject(wrappedValue: BarcodeSearchViewModel(
            itemRepository: itemRepository,
            scannerModule: scannerModule,
            searchHistoryRepository: searchHistoryRepository ?? DefaultSearchHistoryRepository()
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with instructions
                VStack(spacing: 16) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Find Items by Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Scan or enter a barcode to quickly find items in your inventory")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 32)
                
                // Manual entry field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or enter barcode manually:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        TextField("Enter barcode number", text: $manualBarcodeEntry)
                            .textFieldStyle(.plain)
                            .focused($isManualEntryFocused)
                            .keyboardType(.numberPad)
                            .onSubmit {
                                Task {
                                    await viewModel.searchByBarcode(manualBarcodeEntry)
                                }
                            }
                        
                        if !manualBarcodeEntry.isEmpty {
                            Button(action: {
                                manualBarcodeEntry = ""
                                viewModel.clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.searchByBarcode(manualBarcodeEntry)
                            }
                        }) {
                            Image(systemName: "arrow.forward.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(manualBarcodeEntry.isEmpty || viewModel.isSearching)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Scan button
                Button(action: {
                    showingScanner = true
                }) {
                    Label("Scan Barcode", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                // Results section
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let searchResult = viewModel.searchResult {
                    searchResultView(searchResult)
                } else if viewModel.hasSearched {
                    noResultsView
                }
                
                Spacer()
            }
            .navigationTitle("Barcode Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                if let scannerView = viewModel.makeScannerView() {
                    scannerView
                        .onDisappear {
                            showingScanner = false
                        }
                }
            }
            .sheet(item: $selectedItem) { item in
                // Item detail view
                NavigationView {
                    VStack {
                        Text(item.name)
                            .font(.largeTitle)
                            .padding()
                        
                        if let brand = item.brand {
                            Text(brand)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .navigationTitle("Item Detail")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedItem = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func searchResultView(_ result: BarcodeSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Item Found!")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
            
            if let item = result.item {
                Button(action: {
                    selectedItem = item
                }) {
                    ItemSearchResultRow(item: item)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
            
            // Show all items with this barcode if multiple
            if result.allItems.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(result.allItems.count) items with this barcode:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(result.allItems) { item in
                                Button(action: {
                                    selectedItem = item
                                }) {
                                    ItemSearchResultRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No items found")
                .font(.headline)
            
            Text("No items match this barcode")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let lastSearchedBarcode = viewModel.lastSearchedBarcode {
                Text("Barcode: \(lastSearchedBarcode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
        .padding()
    }
}

// MARK: - View Model
@MainActor
final class BarcodeSearchViewModel: ObservableObject {
    @Published var searchResult: BarcodeSearchResult?
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var lastSearchedBarcode: String?
    
    private let itemRepository: any ItemRepository
    private let scannerModule: (any ScannerModuleAPI)?
    private let searchHistoryRepository: any SearchHistoryRepository
    
    init(itemRepository: any ItemRepository, scannerModule: (any ScannerModuleAPI)?, searchHistoryRepository: any SearchHistoryRepository) {
        self.itemRepository = itemRepository
        self.scannerModule = scannerModule
        self.searchHistoryRepository = searchHistoryRepository
    }
    
    func searchByBarcode(_ barcode: String) async {
        guard !barcode.isEmpty else { return }
        
        isSearching = true
        hasSearched = true
        lastSearchedBarcode = barcode
        defer { isSearching = false }
        
        do {
            // Search for items with this barcode
            if let item = try await itemRepository.fetchByBarcode(barcode) {
                // Found exact match
                searchResult = BarcodeSearchResult(
                    barcode: barcode,
                    item: item,
                    allItems: [item]
                )
                
                // Save to search history
                let historyEntry = SearchHistoryEntry(
                    query: barcode,
                    searchType: .barcode,
                    resultCount: 1
                )
                try? await searchHistoryRepository.save(historyEntry)
            } else {
                // No items found
                searchResult = nil
                
                // Still save to history even if no results
                let historyEntry = SearchHistoryEntry(
                    query: barcode,
                    searchType: .barcode,
                    resultCount: 0
                )
                try? await searchHistoryRepository.save(historyEntry)
            }
        } catch {
            print("Barcode search error: \(error)")
            searchResult = nil
        }
    }
    
    func clearSearch() {
        searchResult = nil
        hasSearched = false
        lastSearchedBarcode = nil
    }
    
    func makeScannerView() -> AnyView? {
        guard let scannerModule = scannerModule else { return nil }
        
        return scannerModule.makeBarcodeScannerView { [weak self] barcode in
            Task { @MainActor in
                await self?.searchByBarcode(barcode)
            }
        }
    }
}

// MARK: - Data Models
struct BarcodeSearchResult {
    let barcode: String
    let item: Item?
    let allItems: [Item]
}