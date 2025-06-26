//
//  CurrencyQuickConvertWidget.swift
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
//  Testing: CoreTests/CurrencyQuickConvertWidgetTests.swift
//
//  Description: Quick currency conversion widget for item views with inline conversion and multi-currency display
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CurrencyQuickConvertWidget: View {
    let amount: Decimal
    let currency: CurrencyExchangeService.Currency
    
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @State private var showingConverter = false
    @State private var showingMultiCurrency = false
    @State private var targetCurrency: CurrencyExchangeService.Currency = .USD
    @State private var convertedAmount: Decimal?
    
    public init(amount: Decimal, currency: CurrencyExchangeService.Currency) {
        self.amount = amount
        self.currency = currency
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Current value
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(exchangeService.formatAmount(amount, currency: currency))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { showingConverter = true }) {
                        Label("Currency Converter", systemImage: "arrow.left.arrow.right")
                    }
                    
                    Button(action: { showingMultiCurrency = true }) {
                        Label("Show in Multiple Currencies", systemImage: "globe")
                    }
                    
                    Divider()
                    
                    Menu("Quick Convert to...") {
                        ForEach(quickConvertCurrencies, id: \.self) { targetCur in
                            Button(action: { quickConvert(to: targetCur) }) {
                                Label("\(targetCur.flag) \(targetCur.name)", systemImage: "arrow.right")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            
            // Quick conversion result
            if let converted = convertedAmount {
                HStack {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(targetCurrency.flag) \(exchangeService.formatAmount(converted, currency: targetCurrency))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { convertedAmount = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingConverter) {
            CurrencyConverterView()
        }
        .sheet(isPresented: $showingMultiCurrency) {
            NavigationView {
                MultiCurrencyValueView(amount: amount, currency: currency)
                    .navigationTitle("Multi-Currency View")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingMultiCurrency = false
                            }
                        }
                    }
            }
        }
    }
    
    private var quickConvertCurrencies: [CurrencyExchangeService.Currency] {
        [.USD, .EUR, .GBP, .JPY, .CAD].filter { $0 != currency }
    }
    
    private func quickConvert(to targetCur: CurrencyExchangeService.Currency) {
        withAnimation {
            targetCurrency = targetCur
            
            do {
                convertedAmount = try exchangeService.convert(
                    amount: amount,
                    from: currency,
                    to: targetCur
                )
            } catch {
                // Try offline rates
                do {
                    convertedAmount = try exchangeService.convert(
                        amount: amount,
                        from: currency,
                        to: targetCur,
                        useOfflineRates: true
                    )
                } catch {
                    convertedAmount = nil
                }
            }
        }
    }
}

// MARK: - Inline Currency Display

@available(iOS 15.0, *)
public struct InlineCurrencyDisplay: View {
    let amount: Decimal
    let currency: CurrencyExchangeService.Currency
    let showSymbol: Bool
    let showCode: Bool
    
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    
    public init(
        amount: Decimal,
        currency: CurrencyExchangeService.Currency,
        showSymbol: Bool = true,
        showCode: Bool = false
    ) {
        self.amount = amount
        self.currency = currency
        self.showSymbol = showSymbol
        self.showCode = showCode
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if showSymbol {
                Text(currency.symbol)
                    .foregroundColor(.secondary)
            }
            
            Text(formatAmount())
                .fontWeight(.medium)
            
            if showCode {
                Text(currency.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatAmount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}