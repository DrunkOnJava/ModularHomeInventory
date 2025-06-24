import SwiftUI
import Core

/// Secure currency text that requires biometric authentication to view
/// Swift 5.9 - No Swift 6 features
public struct SecureCurrencyText: View {
    let value: Decimal
    let currency: String
    let style: Font.TextStyle
    
    public init(_ value: Decimal, currency: String, style: Font.TextStyle = .body) {
        self.value = value
        self.currency = currency
        self.style = style
    }
    
    public var body: some View {
        SecureDataView(
            placeholder: "••••",
            reason: "Authenticate to view financial data"
        ) {
            Text(value, format: .currency(code: currency))
                .font(.system(style))
        }
    }
}

/// Secure stat card for financial data
public struct SecureStatCard: View {
    let title: String
    let value: String
    let icon: String
    let isFinancial: Bool
    
    public init(title: String, value: String, icon: String, isFinancial: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.isFinancial = isFinancial
    }
    
    public var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
            
            if isFinancial {
                SecureDataView(
                    placeholder: "••••",
                    reason: "Authenticate to view \(title.lowercased())"
                ) {
                    Text(value)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                }
            } else {
                Text(value)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Text(title)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}