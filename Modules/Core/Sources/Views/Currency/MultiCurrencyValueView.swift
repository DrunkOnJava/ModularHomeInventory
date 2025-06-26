//
//  MultiCurrencyValueView.swift
//  Core
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Core
//  Dependencies: SwiftUI
//  Testing: CoreTests/MultiCurrencyValueViewTests.swift
//
//  Description: View for displaying item values in multiple currencies with customizable currency selection
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct MultiCurrencyValueView: View {
    let baseAmount: Decimal
    let baseCurrency: CurrencyExchangeService.Currency
    
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @State private var showingAllCurrencies = false
    @State private var selectedCurrencies: Set<CurrencyExchangeService.Currency> = []
    
    private let defaultCurrencies: [CurrencyExchangeService.Currency] = [.USD, .EUR, .GBP, .JPY]
    
    private var currenciesToShow: [CurrencyExchangeService.Currency] {
        if selectedCurrencies.isEmpty {
            return defaultCurrencies.filter { $0 != baseCurrency }
        } else {
            return Array(selectedCurrencies).sorted { $0.rawValue < $1.rawValue }
        }
    }
    
    public init(amount: Decimal, currency: CurrencyExchangeService.Currency) {
        self.baseAmount = amount
        self.baseCurrency = currency
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Base currency
            HStack {
                Text(baseCurrency.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exchangeService.formatAmount(baseAmount, currency: baseCurrency))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(baseCurrency.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Label("Base", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            Divider()
            
            // Converted values
            ForEach(currenciesToShow, id: \.self) { currency in
                ConvertedValueRow(
                    amount: baseAmount,
                    fromCurrency: baseCurrency,
                    toCurrency: currency
                )
            }
            
            // Show more/less button
            Button(action: { showingAllCurrencies.toggle() }) {
                HStack {
                    Spacer()
                    Label(
                        showingAllCurrencies ? "Customize Currencies" : "Show More Currencies",
                        systemImage: showingAllCurrencies ? "gear" : "plus.circle"
                    )
                    .font(.callout)
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.blue)
            .padding(.top, 8)
            .sheet(isPresented: $showingAllCurrencies) {
                CurrencySelectionView(
                    selectedCurrencies: $selectedCurrencies,
                    baseCurrency: baseCurrency
                )
            }
            
            // Update indicator
            if exchangeService.ratesNeedUpdate {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Exchange rates may be outdated")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    
                    if exchangeService.isUpdating {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Button("Update") {
                            Task {
                                try? await exchangeService.updateRates()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Converted Value Row

struct ConvertedValueRow: View {
    let amount: Decimal
    let fromCurrency: CurrencyExchangeService.Currency
    let toCurrency: CurrencyExchangeService.Currency
    
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @State private var convertedAmount: Decimal?
    @State private var isLoading = true
    
    var body: some View {
        HStack {
            Text(toCurrency.flag)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                if let converted = convertedAmount {
                    Text(exchangeService.formatAmount(converted, currency: toCurrency))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else if isLoading {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(toCurrency.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let rate = exchangeService.getRate(from: fromCurrency, to: toCurrency) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("1:\(rate.rate.formatted(.number.precision(.fractionLength(4))))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if rate.isStale {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .onAppear {
            updateConversion()
        }
        .onChange(of: amount) { _ in
            updateConversion()
        }
    }
    
    private func updateConversion() {
        isLoading = true
        
        do {
            convertedAmount = try exchangeService.convert(
                amount: amount,
                from: fromCurrency,
                to: toCurrency
            )
        } catch {
            // Try offline rates
            do {
                convertedAmount = try exchangeService.convert(
                    amount: amount,
                    from: fromCurrency,
                    to: toCurrency,
                    useOfflineRates: true
                )
            } catch {
                convertedAmount = nil
            }
        }
        
        isLoading = false
    }
}

// MARK: - Currency Selection View

struct CurrencySelectionView: View {
    @Binding var selectedCurrencies: Set<CurrencyExchangeService.Currency>
    let baseCurrency: CurrencyExchangeService.Currency
    
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredCurrencies: [CurrencyExchangeService.Currency] {
        let currencies = exchangeService.availableCurrencies.filter { $0 != baseCurrency }
        
        if searchText.isEmpty {
            return currencies
        }
        
        return currencies.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains(searchText) ||
            currency.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(filteredCurrencies) { currency in
                        Button(action: { toggleCurrency(currency) }) {
                            HStack {
                                Text(currency.flag)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(currency.rawValue) (\(currency.symbol))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedCurrencies.contains(currency) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select currencies to display")
                } footer: {
                    if selectedCurrencies.isEmpty {
                        Text("Default currencies will be shown if none are selected")
                    } else {
                        Text("\(selectedCurrencies.count) currencies selected")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Select Currencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCurrencies.removeAll()
                    }
                    .disabled(selectedCurrencies.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleCurrency(_ currency: CurrencyExchangeService.Currency) {
        if selectedCurrencies.contains(currency) {
            selectedCurrencies.remove(currency)
        } else {
            selectedCurrencies.insert(currency)
        }
    }
}