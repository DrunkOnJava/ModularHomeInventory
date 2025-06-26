//
//  CurrencySettingsView.swift
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
//  Testing: CoreTests/CurrencySettingsViewTests.swift
//
//  Description: Settings for currency exchange preferences
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CurrencySettingsView: View {
    public init() {}
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddManualRate = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public var body: some View {
        NavigationView {
            Form {
                // Preferred currency
                Section {
                    CurrencyPicker(
                        title: "Preferred Currency",
                        selection: Binding(
                            get: { exchangeService.preferredCurrency },
                            set: { exchangeService.setPreferredCurrency($0) }
                        ),
                        currencies: exchangeService.availableCurrencies
                    )
                } header: {
                    Text("Default Currency")
                } footer: {
                    Text("This currency will be used as the default for all item values")
                }
                
                // Update settings
                Section {
                    Picker("Update Frequency", selection: Binding(
                        get: { exchangeService.updateFrequency },
                        set: { exchangeService.setUpdateFrequency($0) }
                    )) {
                        ForEach(CurrencyExchangeService.UpdateFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    Toggle("Automatic Updates", isOn: Binding(
                        get: { exchangeService.autoUpdate },
                        set: { exchangeService.setAutoUpdate($0) }
                    ))
                    
                    if let lastUpdate = exchangeService.lastUpdateDate {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: updateRates) {
                        HStack {
                            Text("Update Now")
                            
                            if exchangeService.isUpdating {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(exchangeService.isUpdating)
                } header: {
                    Text("Exchange Rate Updates")
                }
                
                // Manual rates
                Section {
                    Button(action: { showingAddManualRate = true }) {
                        Label("Add Manual Rate", systemImage: "plus.circle")
                    }
                    
                    let manualRates = exchangeService.exchangeRates.values
                        .filter { $0.source == .manual }
                        .sorted { $0.timestamp > $1.timestamp }
                    
                    if !manualRates.isEmpty {
                        ForEach(manualRates, id: \.fromCurrency) { rate in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(rate.fromCurrency) → \(rate.toCurrency)")
                                        .font(.headline)
                                    Text("1 \(rate.fromCurrency) = \(rate.rate.formatted(.number.precision(.fractionLength(4)))) \(rate.toCurrency)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(rate.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Manual Exchange Rates")
                } footer: {
                    Text("Add custom exchange rates for currencies not available through automatic updates")
                }
                
                // Statistics
                Section {
                    HStack {
                        Label("Available Rates", systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                        Text("\(exchangeService.exchangeRates.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Offline Rates", systemImage: "wifi.slash")
                        Spacer()
                        Text("\(exchangeService.offlineRates.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    let staleCount = exchangeService.exchangeRates.values.filter { $0.isStale }.count
                    if staleCount > 0 {
                        HStack {
                            Label("Outdated Rates", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Spacer()
                            Text("\(staleCount)")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Currency Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddManualRate) {
                AddManualRateView()
            }
            .alert("Update Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateRates() {
        Task {
            do {
                try await exchangeService.updateRates(force: true)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Add Manual Rate View

struct AddManualRateView: View {
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var fromCurrency: CurrencyExchangeService.Currency = .USD
    @State private var toCurrency: CurrencyExchangeService.Currency = .EUR
    @State private var rate: Decimal?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        fromCurrency != toCurrency && rate != nil && rate! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    CurrencyPicker(
                        title: "From",
                        selection: $fromCurrency,
                        currencies: exchangeService.availableCurrencies
                    )
                    
                    CurrencyPicker(
                        title: "To",
                        selection: $toCurrency,
                        currencies: exchangeService.availableCurrencies
                    )
                } header: {
                    Text("Currencies")
                }
                
                Section {
                    HStack {
                        Text("Exchange Rate")
                        Spacer()
                        TextField("Rate", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                    }
                    
                    if let rate = rate, rate > 0 {
                        Text("1 \(fromCurrency.rawValue) = \(rate.formatted(.number.precision(.fractionLength(4)))) \(toCurrency.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Rate")
                } footer: {
                    Text("Enter the amount of \(toCurrency.rawValue) equal to 1 \(fromCurrency.rawValue)")
                }
            }
            .navigationTitle("Add Manual Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addRate()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addRate() {
        guard let rate = rate else { return }
        
        exchangeService.addManualRate(
            from: fromCurrency,
            to: toCurrency,
            rate: rate
        )
        
        dismiss()
    }
}