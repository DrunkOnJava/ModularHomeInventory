import SwiftUI

/// A guide view that demonstrates VoiceOver best practices
public struct VoiceOverGuideView: View {
    @State private var exampleText = ""
    @State private var sliderValue = 50.0
    @State private var isToggled = false
    @State private var selectedOption = 0
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                headerSection
                
                // VoiceOver Status
                statusSection
                
                // Basic Labels
                labelsSection
                
                // Interactive Elements
                interactiveSection
                
                // Custom Actions
                customActionsSection
                
                // Lists and Navigation
                listsSection
                
                // Best Practices
                bestPracticesSection
            }
            .appPadding()
        }
        .navigationTitle("VoiceOver Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("VoiceOver Guide")
                .dynamicTextStyle(.displayLarge)
                .voiceOverHeader()
            
            Text("This guide demonstrates how VoiceOver works with different UI elements.")
                .dynamicTextStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("VoiceOver Status")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            HStack {
                Image(systemName: voiceOverEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(voiceOverEnabled ? AppColors.success : AppColors.textSecondary)
                    .accessibleImage(voiceOverEnabled ? "VoiceOver is enabled" : "VoiceOver is disabled")
                
                Text(voiceOverEnabled ? "VoiceOver is ON" : "VoiceOver is OFF")
                    .dynamicTextStyle(.bodyMedium)
            }
            .voiceOverCombine()
            
            if !voiceOverEnabled {
                Text("Enable VoiceOver in Settings > Accessibility > VoiceOver")
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Labels and Descriptions")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            // Simple label
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(AppColors.primary)
                Text("Documents")
                    .dynamicTextStyle(.bodyMedium)
                Spacer()
                Text("24 items")
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .voiceOverCombine()
            .voiceOverLabel("Documents folder, contains 24 items")
            .appPadding()
            .background(AppColors.surface)
            .appCornerRadius(.small)
            
            // Image with description
            HStack {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.primary)
                    .accessibleImage("Product photo")
                
                VStack(alignment: .leading) {
                    Text("Product Image")
                        .dynamicTextStyle(.bodyMedium)
                    Text("High resolution")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .voiceOverCombine()
            .voiceOverLabel("Product photo, high resolution image")
            .appPadding()
            .background(AppColors.surface)
            .appCornerRadius(.small)
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var interactiveSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Interactive Elements")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            // Text Field
            TextField("Enter item name", text: $exampleText)
                .textFieldStyle(.roundedBorder)
                .voiceOverTextField(
                    label: "Item name",
                    hint: "Enter the name of your item"
                )
            
            // Toggle
            Toggle(isOn: $isToggled) {
                Label("Enable notifications", systemImage: "bell")
            }
            .voiceOverLabel("Notifications")
            .voiceOverValue(isToggled ? "Enabled" : "Disabled")
            .voiceOverHint("Double tap to toggle")
            
            // Slider
            VStack(alignment: .leading) {
                Text("Quantity: \(Int(sliderValue))")
                    .dynamicTextStyle(.bodyMedium)
                
                Slider(value: $sliderValue, in: 0...100, step: 1)
                    .voiceOverLabel("Quantity selector")
                    .voiceOverValue("\(Int(sliderValue)) items")
                    .voiceOverHint("Swipe up or down to adjust")
            }
            
            // Picker
            Picker("Category", selection: $selectedOption) {
                Text("Electronics").tag(0)
                Text("Furniture").tag(1)
                Text("Clothing").tag(2)
            }
            .pickerStyle(.segmented)
            .voiceOverLabel("Category selector")
            .voiceOverHint("Swipe up or down to change selection")
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var customActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Custom Actions")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            // Item with custom actions
            HStack {
                Image(systemName: "shippingbox")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading) {
                    Text("MacBook Pro")
                        .dynamicTextStyle(.bodyMedium)
                    Text("Electronics • $2,499")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .appPadding()
            .background(AppColors.surface)
            .appCornerRadius(.small)
            .voiceOverCombine()
            .voiceOverLabel("MacBook Pro, Electronics category, valued at $2,499")
            .voiceOverHint("Actions available")
            .voiceOverActions([
                VoiceOverAction(name: "Edit") {
                    VoiceOverAnnouncement.announce("Edit action selected")
                },
                VoiceOverAction(name: "Share") {
                    VoiceOverAnnouncement.announce("Share action selected")
                },
                VoiceOverAction(name: "Delete") {
                    VoiceOverAnnouncement.announce("Delete action selected")
                }
            ])
            
            Text("Use the rotor to access custom actions")
                .dynamicTextStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var listsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Lists and Navigation")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            ForEach(1...3, id: \.self) { index in
                NavigationLink(destination: Text("Detail View \(index)")) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(AppColors.primary)
                        
                        VStack(alignment: .leading) {
                            Text("Location \(index)")
                                .dynamicTextStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(index * 12) items")
                                .dynamicTextStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .appPadding()
                    .background(AppColors.surface)
                    .appCornerRadius(.small)
                }
                .voiceOverNavigationLink(
                    label: "Location \(index), contains \(index * 12) items",
                    hint: "Double tap to view items"
                )
                .voiceOverListItem(position: index, total: 3)
            }
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var bestPracticesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Best Practices")
                .dynamicTextStyle(.headlineMedium)
                .voiceOverHeader()
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                bestPracticeItem(
                    icon: "text.bubble",
                    title: "Clear Labels",
                    description: "Provide descriptive labels for all interactive elements"
                )
                
                bestPracticeItem(
                    icon: "hand.tap",
                    title: "Helpful Hints",
                    description: "Add hints to explain how to interact with complex elements"
                )
                
                bestPracticeItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Group Related Content",
                    description: "Combine related elements to reduce navigation complexity"
                )
                
                bestPracticeItem(
                    icon: "speaker.wave.3",
                    title: "Announce Changes",
                    description: "Use announcements for important state changes"
                )
                
                bestPracticeItem(
                    icon: "checkmark.circle",
                    title: "Test Regularly",
                    description: "Always test your app with VoiceOver enabled"
                )
            }
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private func bestPracticeItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 30)
                .voiceOverIgnore()
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .dynamicTextStyle(.bodyMedium)
                Text(description)
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .voiceOverCombine()
        .voiceOverLabel("\(title). \(description)")
    }
}

// MARK: - Preview

#if DEBUG
struct VoiceOverGuideView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VoiceOverGuideView()
        }
    }
}
#endif