//
//  CurrencyExchangeService.swift
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
//  Dependencies: Foundation, SwiftUI
//  Testing: CoreTests/CurrencyExchangeServiceTests.swift
//
//  Description: Service for managing currency exchange rates and conversions
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 15.0, *)
public final class CurrencyExchangeService: ObservableObject {
    public static let shared = CurrencyExchangeService()
    
    // MARK: - Published Properties
    
    @Published public var exchangeRates: [String: ExchangeRate] = [:]
    @Published public var lastUpdateDate: Date?
    @Published public var isUpdating = false
    @Published public var updateError: CurrencyError?
    @Published public var preferredCurrency: Currency = .USD
    @Published public var availableCurrencies: [Currency] = Currency.allCases
    @Published public var offlineRates: [String: ExchangeRate] = [:]
    @Published public var updateFrequency: UpdateFrequency = .daily
    @Published public var autoUpdate = true
    
    // MARK: - Types
    
    public struct ExchangeRate: Codable, Equatable {
        public let fromCurrency: String
        public let toCurrency: String
        public let rate: Decimal
        public let timestamp: Date
        public let source: RateSource
        
        public var isStale: Bool {
            Date().timeIntervalSince(timestamp) > 86400 // 24 hours
        }
        
        public init(
            fromCurrency: String,
            toCurrency: String,
            rate: Decimal,
            timestamp: Date = Date(),
            source: RateSource = .api
        ) {
            self.fromCurrency = fromCurrency
            self.toCurrency = toCurrency
            self.rate = rate
            self.timestamp = timestamp
            self.source = source
        }
    }
    
    public enum Currency: String, Codable, CaseIterable, Identifiable {
        case USD = "USD"
        case EUR = "EUR"
        case GBP = "GBP"
        case JPY = "JPY"
        case CAD = "CAD"
        case AUD = "AUD"
        case CHF = "CHF"
        case CNY = "CNY"
        case INR = "INR"
        case KRW = "KRW"
        case MXN = "MXN"
        case BRL = "BRL"
        case RUB = "RUB"
        case SGD = "SGD"
        case HKD = "HKD"
        case NZD = "NZD"
        case SEK = "SEK"
        case NOK = "NOK"
        case DKK = "DKK"
        case PLN = "PLN"
        
        public var id: String { rawValue }
        
        public var name: String {
            switch self {
            case .USD: return "US Dollar"
            case .EUR: return "Euro"
            case .GBP: return "British Pound"
            case .JPY: return "Japanese Yen"
            case .CAD: return "Canadian Dollar"
            case .AUD: return "Australian Dollar"
            case .CHF: return "Swiss Franc"
            case .CNY: return "Chinese Yuan"
            case .INR: return "Indian Rupee"
            case .KRW: return "South Korean Won"
            case .MXN: return "Mexican Peso"
            case .BRL: return "Brazilian Real"
            case .RUB: return "Russian Ruble"
            case .SGD: return "Singapore Dollar"
            case .HKD: return "Hong Kong Dollar"
            case .NZD: return "New Zealand Dollar"
            case .SEK: return "Swedish Krona"
            case .NOK: return "Norwegian Krone"
            case .DKK: return "Danish Krone"
            case .PLN: return "Polish Zloty"
            }
        }
        
        public var symbol: String {
            switch self {
            case .USD: return "$"
            case .EUR: return "€"
            case .GBP: return "£"
            case .JPY: return "¥"
            case .CAD: return "C$"
            case .AUD: return "A$"
            case .CHF: return "CHF"
            case .CNY: return "¥"
            case .INR: return "₹"
            case .KRW: return "₩"
            case .MXN: return "$"
            case .BRL: return "R$"
            case .RUB: return "₽"
            case .SGD: return "S$"
            case .HKD: return "HK$"
            case .NZD: return "NZ$"
            case .SEK: return "kr"
            case .NOK: return "kr"
            case .DKK: return "kr"
            case .PLN: return "zł"
            }
        }
        
        public var flag: String {
            switch self {
            case .USD: return "🇺🇸"
            case .EUR: return "🇪🇺"
            case .GBP: return "🇬🇧"
            case .JPY: return "🇯🇵"
            case .CAD: return "🇨🇦"
            case .AUD: return "🇦🇺"
            case .CHF: return "🇨🇭"
            case .CNY: return "🇨🇳"
            case .INR: return "🇮🇳"
            case .KRW: return "🇰🇷"
            case .MXN: return "🇲🇽"
            case .BRL: return "🇧🇷"
            case .RUB: return "🇷🇺"
            case .SGD: return "🇸🇬"
            case .HKD: return "🇭🇰"
            case .NZD: return "🇳🇿"
            case .SEK: return "🇸🇪"
            case .NOK: return "🇳🇴"
            case .DKK: return "🇩🇰"
            case .PLN: return "🇵🇱"
            }
        }
        
        public var locale: Locale {
            switch self {
            case .USD: return Locale(identifier: "en_US")
            case .EUR: return Locale(identifier: "fr_FR")
            case .GBP: return Locale(identifier: "en_GB")
            case .JPY: return Locale(identifier: "ja_JP")
            case .CAD: return Locale(identifier: "en_CA")
            case .AUD: return Locale(identifier: "en_AU")
            case .CHF: return Locale(identifier: "de_CH")
            case .CNY: return Locale(identifier: "zh_CN")
            case .INR: return Locale(identifier: "hi_IN")
            case .KRW: return Locale(identifier: "ko_KR")
            case .MXN: return Locale(identifier: "es_MX")
            case .BRL: return Locale(identifier: "pt_BR")
            case .RUB: return Locale(identifier: "ru_RU")
            case .SGD: return Locale(identifier: "en_SG")
            case .HKD: return Locale(identifier: "zh_HK")
            case .NZD: return Locale(identifier: "en_NZ")
            case .SEK: return Locale(identifier: "sv_SE")
            case .NOK: return Locale(identifier: "nb_NO")
            case .DKK: return Locale(identifier: "da_DK")
            case .PLN: return Locale(identifier: "pl_PL")
            }
        }
    }
    
    public enum RateSource: String, Codable {
        case api = "API"
        case manual = "Manual"
        case cached = "Cached"
        case offline = "Offline"
    }
    
    public enum UpdateFrequency: String, Codable, CaseIterable {
        case realtime = "Real-time"
        case hourly = "Hourly"
        case daily = "Daily"
        case weekly = "Weekly"
        case manual = "Manual"
        
        public var interval: TimeInterval? {
            switch self {
            case .realtime: return 60 // 1 minute
            case .hourly: return 3600 // 1 hour
            case .daily: return 86400 // 24 hours
            case .weekly: return 604800 // 7 days
            case .manual: return nil
            }
        }
    }
    
    public enum CurrencyError: LocalizedError {
        case networkError(String)
        case invalidResponse
        case rateLimitExceeded
        case apiKeyMissing
        case conversionError(String)
        case noRatesAvailable
        
        public var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from exchange rate service"
            case .rateLimitExceeded:
                return "Rate limit exceeded. Please try again later."
            case .apiKeyMissing:
                return "API key is missing. Please configure in settings."
            case .conversionError(let message):
                return "Conversion error: \(message)"
            case .noRatesAvailable:
                return "No exchange rates available"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "currency_exchange_rates"
    private let preferredCurrencyKey = "preferred_currency"
    private let updateFrequencyKey = "update_frequency"
    private let autoUpdateKey = "auto_update_rates"
    private var updateTimer: Timer?
    private let session = URLSession.shared
    
    // Mock API key - in production, this would be stored securely
    private let apiKey = "demo_api_key"
    private let baseURL = "https://api.exchangerate-api.com/v4/latest/"
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        loadCachedRates()
        setupOfflineRates()
        
        if autoUpdate {
            scheduleAutomaticUpdates()
        }
    }
    
    // MARK: - Public Methods
    
    /// Convert amount from one currency to another
    public func convert(
        amount: Decimal,
        from: Currency,
        to: Currency,
        useOfflineRates: Bool = false
    ) throws -> Decimal {
        guard from != to else { return amount }
        
        let rateKey = "\(from.rawValue)_\(to.rawValue)"
        let rates = useOfflineRates ? offlineRates : exchangeRates
        
        if let rate = rates[rateKey] {
            return amount * rate.rate
        }
        
        // Try reverse conversion
        let reverseKey = "\(to.rawValue)_\(from.rawValue)"
        if let reverseRate = rates[reverseKey] {
            return amount / reverseRate.rate
        }
        
        // Try conversion through USD
        if from != .USD && to != .USD {
            let fromUSDKey = "\(from.rawValue)_USD"
            let toUSDKey = "USD_\(to.rawValue)"
            
            if let fromRate = rates[fromUSDKey], let toRate = rates[toUSDKey] {
                let usdAmount = amount * fromRate.rate
                return usdAmount * toRate.rate
            }
        }
        
        throw CurrencyError.conversionError("No exchange rate available for \(from.rawValue) to \(to.rawValue)")
    }
    
    /// Update exchange rates from API
    public func updateRates(force: Bool = false) async throws {
        guard !isUpdating else { return }
        
        // Check if update is needed
        if !force, let lastUpdate = lastUpdateDate {
            if let interval = updateFrequency.interval {
                let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
                if timeSinceUpdate < interval {
                    return
                }
            }
        }
        
        isUpdating = true
        updateError = nil
        
        do {
            // Fetch rates for preferred currency
            try await fetchRates(for: preferredCurrency)
            
            // Fetch rates for commonly used currencies
            for currency in [Currency.USD, .EUR, .GBP].filter({ $0 != preferredCurrency }) {
                try await fetchRates(for: currency)
            }
            
            lastUpdateDate = Date()
            saveRates()
            isUpdating = false
            
        } catch {
            isUpdating = false
            updateError = error as? CurrencyError ?? .networkError(error.localizedDescription)
            throw error
        }
    }
    
    /// Set preferred currency
    public func setPreferredCurrency(_ currency: Currency) {
        preferredCurrency = currency
        userDefaults.set(currency.rawValue, forKey: preferredCurrencyKey)
        
        Task {
            try? await updateRates(force: true)
        }
    }
    
    /// Set update frequency
    public func setUpdateFrequency(_ frequency: UpdateFrequency) {
        updateFrequency = frequency
        userDefaults.set(frequency.rawValue, forKey: updateFrequencyKey)
        
        if autoUpdate {
            scheduleAutomaticUpdates()
        }
    }
    
    /// Toggle automatic updates
    public func setAutoUpdate(_ enabled: Bool) {
        autoUpdate = enabled
        userDefaults.set(enabled, forKey: autoUpdateKey)
        
        if enabled {
            scheduleAutomaticUpdates()
        } else {
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    /// Get formatted currency amount
    public func formatAmount(_ amount: Decimal, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currency.locale
        formatter.currencyCode = currency.rawValue
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    /// Check if rates need updating
    public var ratesNeedUpdate: Bool {
        guard let lastUpdate = lastUpdateDate else { return true }
        
        if let interval = updateFrequency.interval {
            return Date().timeIntervalSince(lastUpdate) > interval
        }
        
        return false
    }
    
    /// Get exchange rate between two currencies
    public func getRate(from: Currency, to: Currency) -> ExchangeRate? {
        let key = "\(from.rawValue)_\(to.rawValue)"
        return exchangeRates[key]
    }
    
    /// Add manual exchange rate
    public func addManualRate(from: Currency, to: Currency, rate: Decimal) {
        let exchangeRate = ExchangeRate(
            fromCurrency: from.rawValue,
            toCurrency: to.rawValue,
            rate: rate,
            source: .manual
        )
        
        let key = "\(from.rawValue)_\(to.rawValue)"
        exchangeRates[key] = exchangeRate
        
        // Add reverse rate
        let reverseRate = ExchangeRate(
            fromCurrency: to.rawValue,
            toCurrency: from.rawValue,
            rate: 1 / rate,
            source: .manual
        )
        let reverseKey = "\(to.rawValue)_\(from.rawValue)"
        exchangeRates[reverseKey] = reverseRate
        
        saveRates()
    }
    
    // MARK: - Private Methods
    
    private func fetchRates(for baseCurrency: Currency) async throws {
        // In production, this would make real API calls
        // For demo, using mock data
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock exchange rates
        let mockRates: [Currency: Decimal] = {
            switch baseCurrency {
            case .USD:
                return [
                    .EUR: 0.85,
                    .GBP: 0.73,
                    .JPY: 110.0,
                    .CAD: 1.25,
                    .AUD: 1.35,
                    .CHF: 0.92,
                    .CNY: 6.45,
                    .INR: 74.5,
                    .KRW: 1180.0
                ]
            case .EUR:
                return [
                    .USD: 1.18,
                    .GBP: 0.86,
                    .JPY: 129.0,
                    .CAD: 1.47,
                    .AUD: 1.59,
                    .CHF: 1.08,
                    .CNY: 7.58,
                    .INR: 87.5,
                    .KRW: 1385.0
                ]
            case .GBP:
                return [
                    .USD: 1.37,
                    .EUR: 1.16,
                    .JPY: 150.0,
                    .CAD: 1.71,
                    .AUD: 1.85,
                    .CHF: 1.26,
                    .CNY: 8.83,
                    .INR: 102.0,
                    .KRW: 1615.0
                ]
            default:
                return [:]
            }
        }()
        
        // Update exchange rates
        for (currency, rate) in mockRates {
            let exchangeRate = ExchangeRate(
                fromCurrency: baseCurrency.rawValue,
                toCurrency: currency.rawValue,
                rate: rate,
                source: .api
            )
            
            let key = "\(baseCurrency.rawValue)_\(currency.rawValue)"
            exchangeRates[key] = exchangeRate
        }
    }
    
    private func setupOfflineRates() {
        // Common offline rates for fallback
        offlineRates = [
            "USD_EUR": ExchangeRate(fromCurrency: "USD", toCurrency: "EUR", rate: 0.85, source: .offline),
            "EUR_USD": ExchangeRate(fromCurrency: "EUR", toCurrency: "USD", rate: 1.18, source: .offline),
            "USD_GBP": ExchangeRate(fromCurrency: "USD", toCurrency: "GBP", rate: 0.73, source: .offline),
            "GBP_USD": ExchangeRate(fromCurrency: "GBP", toCurrency: "USD", rate: 1.37, source: .offline),
            "USD_JPY": ExchangeRate(fromCurrency: "USD", toCurrency: "JPY", rate: 110.0, source: .offline),
            "JPY_USD": ExchangeRate(fromCurrency: "JPY", toCurrency: "USD", rate: 0.0091, source: .offline),
            "USD_CAD": ExchangeRate(fromCurrency: "USD", toCurrency: "CAD", rate: 1.25, source: .offline),
            "CAD_USD": ExchangeRate(fromCurrency: "CAD", toCurrency: "USD", rate: 0.80, source: .offline),
            "USD_AUD": ExchangeRate(fromCurrency: "USD", toCurrency: "AUD", rate: 1.35, source: .offline),
            "AUD_USD": ExchangeRate(fromCurrency: "AUD", toCurrency: "USD", rate: 0.74, source: .offline)
        ]
    }
    
    private func scheduleAutomaticUpdates() {
        updateTimer?.invalidate()
        
        guard let interval = updateFrequency.interval else { return }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task {
                try? await self.updateRates()
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveRates() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(exchangeRates)
            userDefaults.set(data, forKey: storageKey)
            
            if let lastUpdate = lastUpdateDate {
                userDefaults.set(lastUpdate, forKey: "last_rate_update")
            }
        } catch {
            print("Failed to save exchange rates: \(error)")
        }
    }
    
    private func loadCachedRates() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            exchangeRates = try decoder.decode([String: ExchangeRate].self, from: data)
            lastUpdateDate = userDefaults.object(forKey: "last_rate_update") as? Date
        } catch {
            print("Failed to load cached rates: \(error)")
        }
    }
    
    private func loadSettings() {
        if let currencyString = userDefaults.string(forKey: preferredCurrencyKey),
           let currency = Currency(rawValue: currencyString) {
            preferredCurrency = currency
        }
        
        if let frequencyString = userDefaults.string(forKey: updateFrequencyKey),
           let frequency = UpdateFrequency(rawValue: frequencyString) {
            updateFrequency = frequency
        }
        
        autoUpdate = userDefaults.object(forKey: autoUpdateKey) as? Bool ?? true
    }
}

// MARK: - Currency Extensions

public extension Decimal {
    /// Convert to formatted currency string
    func asCurrency(_ currency: CurrencyExchangeService.Currency) -> String {
        CurrencyExchangeService.shared.formatAmount(self, currency: currency)
    }
}