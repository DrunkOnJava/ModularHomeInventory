//
//  Decimal+Currency.swift
//  HomeInventoryModular
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
//  Module: SharedUI
//  Dependencies: Foundation, SwiftUI
//  Testing: Modules/SharedUI/Tests/SharedUITests/DecimalExtensionsTests.swift
//
//  Description: Decimal extension for currency formatting with localization support
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI

public extension Decimal {
    /// Formats the decimal as currency with exactly 2 decimal places
    /// - Parameter currencyCode: The ISO currency code (defaults to USD)
    /// - Returns: A formatted currency string
    func asCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSNumber) ?? "$0.00"
    }
    
    /// Returns a currency format specifier for SwiftUI Text views
    /// - Parameter currencyCode: The ISO currency code (defaults to USD)
    /// - Returns: A FloatingPointFormatStyle for use in Text views
    static func currencyFormat(code: String = "USD") -> Decimal.FormatStyle.Currency {
        .currency(code: code).precision(.fractionLength(2))
    }
}

public extension Double {
    /// Formats the double as currency with exactly 2 decimal places
    /// - Parameter currencyCode: The ISO currency code (defaults to USD)
    /// - Returns: A formatted currency string
    func asCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSNumber) ?? "$0.00"
    }
}

public extension Optional where Wrapped == Decimal {
    /// Formats an optional decimal as currency with exactly 2 decimal places
    /// - Parameter currencyCode: The ISO currency code (defaults to USD)
    /// - Returns: A formatted currency string or default value
    func asCurrency(code: String = "USD", default defaultValue: String = "$0.00") -> String {
        switch self {
        case .some(let value):
            return value.asCurrency(code: code)
        case .none:
            return defaultValue
        }
    }
}

/// View modifier for currency text formatting
public struct CurrencyText: ViewModifier {
    let value: Decimal
    let code: String
    
    public init(value: Decimal, code: String = "USD") {
        self.value = value
        self.code = code
    }
    
    public func body(content: Content) -> some View {
        Text(value, format: .currency(code: code).precision(.fractionLength(2)))
    }
}

public extension View {
    /// Applies currency formatting to a view
    func currencyFormatted(_ value: Decimal, code: String = "USD") -> some View {
        modifier(CurrencyText(value: value, code: code))
    }
}