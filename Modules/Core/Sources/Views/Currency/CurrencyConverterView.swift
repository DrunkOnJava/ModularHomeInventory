//
//  CurrencyConverterView.swift
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
//  Testing: CoreTests/CurrencyConverterViewTests.swift
//
//  Description: Currency converter interface for converting item values between different currencies with real-time rates
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CurrencyConverterView: View {
    public init() {}
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: Decimal = 0
    @State private var fromCurrency: CurrencyExchangeService.Currency = .USD
    @State private var toCurrency: CurrencyExchangeService.Currency = .EUR
    @State private var convertedAmount: Decimal?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isConverting = false
    
    @FocusState private var amountFocused: Bool
    
    private var conversionRate: Decimal? {
        guard let rate = exchangeService.getRate(from: fromCurrency, to: toCurrency) else {
            return nil
        }
        return rate.rate
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Amount input
                Section {
                    HStack {
                        Text(fromCurrency.symbol)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.title)
                            .focused($amountFocused)
                            .onChange(of: amount) { _ in
                                performConversion()
                            }
                    }
                } header: {
                    Text("Amount to Convert")
                }
                
                // Currency selection
                Section {
                    CurrencyPicker(
                        title: "From",
                        selection: $fromCurrency,
                        currencies: exchangeService.availableCurrencies
                    )
                    .onChange(of: fromCurrency) { _ in
                        performConversion()
                    }
                    
                    Button(action: swapCurrencies) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.title3)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    CurrencyPicker(
                        title: "To",
                        selection: $toCurrency,
                        currencies: exchangeService.availableCurrencies
                    )
                    .onChange(of: toCurrency) { _ in
                        performConversion()
                    }
                } header: {
                    Text("Currencies")
                }
                
                // Result
                if let converted = convertedAmount {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Converted Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if isConverting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            Text(exchangeService.formatAmount(converted, currency: toCurrency))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let rate = conversionRate {
                                HStack {
                                    Text("1 \(fromCurrency.rawValue) = \(rate.formatted(.number.precision(.fractionLength(4)))) \(toCurrency.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if let rateInfo = exchangeService.getRate(from: fromCurrency, to: toCurrency) {
                                        if rateInfo.isStale {
                                            Label("Outdated", systemImage: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        } else {
                                            Label(rateInfo.source.rawValue, systemImage: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Result")
                    }
                }
                
                // Exchange rate info
                Section {
                    if let lastUpdate = exchangeService.lastUpdateDate {
                        HStack {
                            Label("Last Updated", systemImage: "clock")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: updateRates) {
                        HStack {
                            Label("Update Rates", systemImage: "arrow.clockwise")
                            
                            if exchangeService.isUpdating {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(exchangeService.isUpdating)
                } header: {
                    Text("Exchange Rates")
                }
                
                // Quick amounts
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([100, 500, 1000, 5000, 10000], id: \.self) { quickAmount in
                                Button(action: {
                                    amount = Decimal(quickAmount)
                                    amountFocused = false
                                }) {
                                    Text("\(fromCurrency.symbol)\(quickAmount)")
                                        .font(.callout)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Quick Amounts")
                }
            }
            .navigationTitle("Currency Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            amountFocused = false
                        }
                    }
                }
            }
            .alert("Conversion Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            if exchangeService.ratesNeedUpdate {
                Task {
                    try? await exchangeService.updateRates()
                }
            }
        }
    }
    
    private func performConversion() {
        guard amount > 0 else {
            convertedAmount = nil
            return
        }
        
        isConverting = true
        
        do {
            convertedAmount = try exchangeService.convert(
                amount: amount,
                from: fromCurrency,
                to: toCurrency
            )
            isConverting = false
        } catch {
            // Try offline rates
            do {
                convertedAmount = try exchangeService.convert(
                    amount: amount,
                    from: fromCurrency,
                    to: toCurrency,
                    useOfflineRates: true
                )
                isConverting = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isConverting = false
            }
        }
    }
    
    private func swapCurrencies() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
        performConversion()
    }
    
    private func updateRates() {
        Task {
            do {
                try await exchangeService.updateRates(force: true)
                performConversion()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Currency Picker

struct CurrencyPicker: View {
    let title: String
    @Binding var selection: CurrencyExchangeService.Currency
    let currencies: [CurrencyExchangeService.Currency]
    
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(selection.flag)
                        .font(.title2)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selection.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(selection.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            CurrencyPickerSheet(
                selection: $selection,
                currencies: currencies,
                isPresented: $showingPicker
            )
        }
    }
}

struct CurrencyPickerSheet: View {
    @Binding var selection: CurrencyExchangeService.Currency
    let currencies: [CurrencyExchangeService.Currency]
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    
    private var filteredCurrencies: [CurrencyExchangeService.Currency] {
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
                ForEach(filteredCurrencies) { currency in
                    Button(action: {
                        selection = currency
                        isPresented = false
                    }) {
                        HStack {
                            Text(currency.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(currency.rawValue) - \(currency.name)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(currency.symbol)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selection == currency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}