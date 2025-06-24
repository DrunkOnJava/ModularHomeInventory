import SwiftUI
import SharedUI

/// Sophisticated background gradient for settings
struct SettingsBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle pattern overlay
                PatternOverlay()
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                // Floating shapes
                FloatingShapes()
                    .opacity(0.05)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(white: 0.1),
                Color(white: 0.05)
            ]
        } else {
            return [
                Color(white: 0.98),
                Color(white: 0.94)
            ]
        }
    }
}

struct PatternOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size: CGFloat = 40
                let cols = Int(geometry.size.width / size) + 1
                let rows = Int(geometry.size.height / size) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * size
                        let y = CGFloat(row) * size
                        
                        // Create a subtle dot pattern
                        path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                    }
                }
            }
            .fill(Color.primary)
        }
    }
}

struct FloatingShapes: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circle 1
                Circle()
                    .fill(LinearGradient(
                        colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -100)
                    .blur(radius: 40)
                    .offset(y: isAnimating ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: 8)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Circle 2
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
                    .blur(radius: 40)
                    .offset(x: isAnimating ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: 10)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Circle 3
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .blur(radius: 30)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SettingsBackgroundView()
}