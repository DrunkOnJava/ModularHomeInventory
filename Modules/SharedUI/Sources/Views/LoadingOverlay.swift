import SwiftUI

/// Loading overlay view for showing progress
/// Swift 5.9 - No Swift 6 features
public struct LoadingOverlay: View {
    let message: String
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.xl)
            .background(Color.black.opacity(0.8))
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}