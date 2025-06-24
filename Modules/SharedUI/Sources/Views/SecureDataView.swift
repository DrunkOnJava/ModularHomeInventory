import SwiftUI
import Core

/// View wrapper that requires biometric authentication to display sensitive data
/// Swift 5.9 - No Swift 6 features
public struct SecureDataView<Content: View>: View {
    @StateObject private var biometricService = BiometricAuthService.shared
    @AppStorage("biometric_sensitive_data") private var protectSensitiveData = true
    @State private var isAuthenticated = false
    @State private var isAuthenticating = false
    
    let content: () -> Content
    let placeholder: String
    let reason: String
    
    public init(
        placeholder: String = "••••",
        reason: String = "Authenticate to view sensitive data",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.placeholder = placeholder
        self.reason = reason
        self.content = content
    }
    
    public var body: some View {
        Group {
            if !protectSensitiveData || isAuthenticated {
                content()
            } else {
                Button(action: authenticate) {
                    HStack(spacing: 4) {
                        Text(placeholder)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isAuthenticating)
            }
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        
        Task {
            let success = await biometricService.authenticate(reason: reason)
            
            await MainActor.run {
                isAuthenticating = false
                if success {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isAuthenticated = true
                    }
                    
                    // Auto-lock after 5 minutes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                        isAuthenticated = false
                    }
                }
            }
        }
    }
}

/// Modifier for securing text content
public struct SecureTextModifier: ViewModifier {
    @AppStorage("biometric_sensitive_data") private var protectSensitiveData = true
    @State private var isSecured = true
    let placeholder: String
    
    public init(placeholder: String = "••••") {
        self.placeholder = placeholder
    }
    
    public func body(content: Content) -> some View {
        if protectSensitiveData && isSecured {
            HStack(spacing: 4) {
                Text(placeholder)
                    .foregroundColor(.secondary)
                
                Button(action: { isSecured = false }) {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else {
            HStack(spacing: 4) {
                content
                
                if protectSensitiveData {
                    Button(action: { isSecured = true }) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

public extension View {
    /// Secure sensitive text content
    func secureText(placeholder: String = "••••") -> some View {
        modifier(SecureTextModifier(placeholder: placeholder))
    }
}

/// Currency formatter that respects security settings
public struct SecureCurrencyText: View {
    let amount: Decimal
    let currency: String
    let style: Font.TextStyle
    
    @AppStorage("biometric_sensitive_data") private var protectSensitiveData = true
    
    public init(
        _ amount: Decimal,
        currency: String = "USD",
        style: Font.TextStyle = .body
    ) {
        self.amount = amount
        self.currency = currency
        self.style = style
    }
    
    public var body: some View {
        SecureDataView(
            placeholder: "$••••",
            reason: "Authenticate to view financial data"
        ) {
            Text(formattedAmount)
                .font(.system(style))
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Secure statistics card
public struct SecureStatCard: View {
    let title: String
    let value: String
    let icon: String
    let isFinancial: Bool
    
    public init(
        title: String,
        value: String,
        icon: String,
        isFinancial: Bool = false
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.isFinancial = isFinancial
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(title)
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            if isFinancial {
                SecureDataView(
                    placeholder: "••••",
                    reason: "Authenticate to view \(title.lowercased())"
                ) {
                    Text(value)
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
            } else {
                Text(value)
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Preview

struct SecureDataView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Secure text
            Text("Item Value:")
            SecureCurrencyText(999.99)
            
            // Secure card
            SecureStatCard(
                title: "Total Value",
                value: "$12,345.67",
                icon: "dollarsign.circle",
                isFinancial: true
            )
            
            // Regular card
            SecureStatCard(
                title: "Item Count",
                value: "42",
                icon: "shippingbox",
                isFinancial: false
            )
        }
        .padding()
    }
}