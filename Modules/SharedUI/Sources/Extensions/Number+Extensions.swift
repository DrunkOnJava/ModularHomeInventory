import Foundation

public extension Numeric {
    /// Formats the number as a currency string using the current locale.
    func asCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(for: self) ?? ""
    }
}