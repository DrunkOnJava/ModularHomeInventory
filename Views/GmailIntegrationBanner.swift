import SwiftUI
import Gmail

/// Reusable banner for promoting Gmail integration
/// Swift 5.9 - No Swift 6 features
struct GmailIntegrationBanner: View {
    @StateObject private var gmailModule = GmailModule()
    @State private var showingGmailSetup = false
    
    private let icon: String
    private let title: String
    private let subtitle: String
    private let onCompletion: (() -> Void)?
    
    init(
        icon: String = "envelope.badge.fill",
        title: String = "Connect Gmail for Easy Receipt Import",
        subtitle: String = "Automatically import receipts and subscriptions from your email",
        onCompletion: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        if !gmailModule.isAuthenticated {
            Button(action: { showingGmailSetup = true }) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(GmailScaleButtonStyle())
            .sheet(isPresented: $showingGmailSetup) {
                gmailModule.makeReceiptImportView()
                    .onDisappear {
                        if gmailModule.isAuthenticated {
                            onCompletion?()
                        }
                    }
            }
        }
    }
}

/// Button style for subtle scale animation
private struct GmailScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}