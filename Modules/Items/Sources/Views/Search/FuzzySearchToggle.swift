import SwiftUI
import Core
import SharedUI

/// Toggle view for enabling fuzzy search
/// Swift 5.9 - No Swift 6 features
struct FuzzySearchToggle: View {
    @Binding var isEnabled: Bool
    @Binding var threshold: Double
    @State private var showingInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle
            HStack {
                Label("Fuzzy Search", systemImage: "textformat.abc.dottedunderline")
                    .font(.system(size: 15, weight: .medium))
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                
                Button(action: {
                    showingInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Threshold slider (only shown when enabled)
            if isEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tolerance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int((1 - threshold) * 100))% typos allowed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Slider(value: $threshold, in: 0.4...0.9, step: 0.1)
                            .tint(AppColors.primary)
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .sheet(isPresented: $showingInfo) {
            FuzzySearchInfoView()
        }
    }
}

// MARK: - Info View
struct FuzzySearchInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "textformat.abc.dottedunderline")
                            .font(.system(size: 60))
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Fuzzy Search")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Find items even with typos")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // How it works
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How it works", systemImage: "lightbulb")
                            .font(.headline)
                        
                        Text("Fuzzy search helps you find items even when you make spelling mistakes. It uses smart algorithms to match similar words.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Examples
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Examples", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        
                        ExampleRow(query: "iphon", matches: "iPhone")
                        ExampleRow(query: "samung", matches: "Samsung")
                        ExampleRow(query: "keybord", matches: "Keyboard")
                        ExampleRow(query: "moniter", matches: "Monitor")
                        ExampleRow(query: "vaccum", matches: "Vacuum")
                    }
                    
                    // Tolerance settings
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tolerance Settings", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        
                        ToleranceExample(threshold: 0.9, description: "Very strict - Minor typos only")
                        ToleranceExample(threshold: 0.7, description: "Balanced - Most typos")
                        ToleranceExample(threshold: 0.5, description: "Lenient - Major typos allowed")
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tips", systemImage: "lightbulb.fill")
                            .font(.headline)
                        
                        TipRow(text: "Use higher tolerance for longer words")
                        TipRow(text: "Combine with filters for better results")
                        TipRow(text: "Exact matches are always shown first")
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct ExampleRow: View {
    let query: String
    let matches: String
    
    var body: some View {
        HStack {
            Text(query)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.red)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(matches)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.green)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ToleranceExample: View {
    let threshold: Double
    let description: String
    
    var body: some View {
        HStack {
            CircularProgressView(progress: threshold)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(threshold * 100))%")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.3)
                .foregroundStyle(.secondary)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(colorForProgress)
                .rotationEffect(Angle(degrees: -90))
        }
    }
    
    var colorForProgress: Color {
        if progress >= 0.8 {
            return .green
        } else if progress >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}