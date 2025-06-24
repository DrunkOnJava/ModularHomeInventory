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