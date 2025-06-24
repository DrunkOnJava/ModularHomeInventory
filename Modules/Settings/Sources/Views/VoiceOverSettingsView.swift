import SwiftUI
import Core
import SharedUI

/// Settings view for VoiceOver preferences
struct VoiceOverSettingsView: View {
    @ObservedObject var settingsStorage: any SettingsStorageProtocol
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var showingGuide = false
    
    var body: some View {
        List {
            statusSection
            preferencesSection
            announcementsSection
            gesturesSection
            resourcesSection
        }
        .navigationTitle("VoiceOver")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingGuide) {
            NavigationView {
                VoiceOverGuideView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingGuide = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: voiceOverEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(voiceOverEnabled ? AppColors.success : AppColors.textSecondary)
                    .font(.title2)
                    .accessibleImage(voiceOverEnabled ? "VoiceOver is enabled" : "VoiceOver is disabled")
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(voiceOverEnabled ? "VoiceOver is ON" : "VoiceOver is OFF")
                        .dynamicTextStyle(.bodyMedium)
                    
                    Text(voiceOverEnabled ? 
                         "The app is optimized for VoiceOver" : 
                         "Enable in Settings > Accessibility > VoiceOver")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .voiceOverCombine()
            .appPadding(.vertical, AppSpacing.sm)
        } header: {
            Text("Status")
        }
    }
    
    private var preferencesSection: some View {
        Section {
            Toggle(isOn: bindingForBool(key: .voiceOverVerboseLabels, defaultValue: false)) {
                Label("Verbose Labels", systemImage: "text.bubble")
            }
            .voiceOverLabel("Verbose labels")
            .voiceOverHint("When enabled, provides more detailed descriptions")
            
            Toggle(isOn: bindingForBool(key: .voiceOverReadPrices, defaultValue: true)) {
                Label("Announce Prices", systemImage: "dollarsign.circle")
            }
            .voiceOverLabel("Announce prices")
            .voiceOverHint("When enabled, item values are announced")
            
            Toggle(isOn: bindingForBool(key: .voiceOverGroupRelatedItems, defaultValue: true)) {
                Label("Group Related Items", systemImage: "rectangle.3.group")
            }
            .voiceOverLabel("Group related items")
            .voiceOverHint("Combines related information for easier navigation")
            
            Toggle(isOn: bindingForBool(key: .voiceOverAnnouncePositions, defaultValue: true)) {
                Label("Announce List Positions", systemImage: "list.number")
            }
            .voiceOverLabel("Announce list positions")
            .voiceOverHint("Announces item position in lists, such as 3 of 10")
        } header: {
            Text("Preferences")
        } footer: {
            Text("These settings customize how VoiceOver works with the app")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var announcementsSection: some View {
        Section {
            Toggle(isOn: bindingForBool(key: .voiceOverAnnounceChanges, defaultValue: true)) {
                Label("Announce Changes", systemImage: "speaker.wave.2")
            }
            .voiceOverLabel("Announce changes")
            .voiceOverHint("Announces when items are added, updated, or deleted")
            
            Toggle(isOn: bindingForBool(key: .voiceOverAnnounceSyncStatus, defaultValue: true)) {
                Label("Announce Sync Status", systemImage: "arrow.triangle.2.circlepath")
            }
            .voiceOverLabel("Announce sync status")
            .voiceOverHint("Announces when data is syncing or sync completes")
            
            Stepper(
                value: bindingForInt(key: .voiceOverAnnouncementDelay, defaultValue: 1),
                in: 0...5
            ) {
                HStack {
                    Label("Announcement Delay", systemImage: "timer")
                    Spacer()
                    Text("\(settingsStorage.integer(forKey: .voiceOverAnnouncementDelay) ?? 1)s")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .voiceOverLabel("Announcement delay")
            .voiceOverValue("\(settingsStorage.integer(forKey: .voiceOverAnnouncementDelay) ?? 1) seconds")
            .voiceOverHint("Adjust the delay before announcements")
        } header: {
            Text("Announcements")
        } footer: {
            Text("Control when and how the app announces information")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var gesturesSection: some View {
        Section {
            NavigationLink(destination: VoiceOverGesturesView()) {
                Label("Learn Gestures", systemImage: "hand.draw")
                    .voiceOverNavigationLink(
                        label: "Learn VoiceOver gestures",
                        hint: "Double tap to view gesture guide"
                    )
            }
            
            Toggle(isOn: bindingForBool(key: .voiceOverCustomActions, defaultValue: true)) {
                Label("Enable Custom Actions", systemImage: "hand.tap")
            }
            .voiceOverLabel("Enable custom actions")
            .voiceOverHint("Use rotor to access additional actions on items")
            
            Toggle(isOn: bindingForBool(key: .voiceOverMagicTap, defaultValue: true)) {
                Label("Magic Tap Support", systemImage: "wand.and.stars")
            }
            .voiceOverLabel("Magic tap support")
            .voiceOverHint("Two-finger double tap performs primary action")
        } header: {
            Text("Gestures & Actions")
        }
    }
    
    private var resourcesSection: some View {
        Section {
            Button(action: { showingGuide = true }) {
                Label("VoiceOver Guide", systemImage: "book")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .voiceOverLabel("VoiceOver guide")
            .voiceOverHint("Double tap to view the VoiceOver guide")
            
            Link(destination: URL(string: "https://support.apple.com/guide/iphone/turn-on-and-practice-voiceover-iph3e2e415f/ios")!) {
                Label("Apple VoiceOver Help", systemImage: "questionmark.circle")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .voiceOverLabel("Apple VoiceOver help")
            .voiceOverHint("Double tap to open Apple's VoiceOver guide in Safari")
            
            Button(action: testVoiceOver) {
                Label("Test VoiceOver", systemImage: "play.circle")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .voiceOverLabel("Test VoiceOver")
            .voiceOverHint("Double tap to hear a test announcement")
        } header: {
            Text("Resources")
        }
    }
    
    // MARK: - Helper Methods
    
    private func bindingForBool(key: SettingsKey, defaultValue: Bool) -> Binding<Bool> {
        Binding(
            get: { settingsStorage.bool(forKey: key) ?? defaultValue },
            set: { settingsStorage.set($0, forKey: key) }
        )
    }
    
    private func bindingForInt(key: SettingsKey, defaultValue: Int) -> Binding<Int> {
        Binding(
            get: { settingsStorage.integer(forKey: key) ?? defaultValue },
            set: { settingsStorage.set($0, forKey: key) }
        )
    }
    
    private func testVoiceOver() {
        VoiceOverAnnouncement.announce("VoiceOver is working correctly. This is a test announcement.")
    }
}

// MARK: - VoiceOver Gestures View

struct VoiceOverGesturesView: View {
    var body: some View {
        List {
            Section {
                gestureRow(
                    gesture: "Single tap",
                    action: "Select item",
                    description: "Selects the item under your finger"
                )
                
                gestureRow(
                    gesture: "Double tap",
                    action: "Activate",
                    description: "Activates the selected item"
                )
                
                gestureRow(
                    gesture: "Swipe right",
                    action: "Next item",
                    description: "Moves to the next item"
                )
                
                gestureRow(
                    gesture: "Swipe left",
                    action: "Previous item",
                    description: "Moves to the previous item"
                )
            } header: {
                Text("Basic Navigation")
                    .voiceOverHeader()
            }
            
            Section {
                gestureRow(
                    gesture: "Two-finger swipe up",
                    action: "Read all",
                    description: "Reads all content from current position"
                )
                
                gestureRow(
                    gesture: "Two-finger swipe down",
                    action: "Read from top",
                    description: "Reads all content from the beginning"
                )
                
                gestureRow(
                    gesture: "Three-finger swipe",
                    action: "Scroll",
                    description: "Scrolls the page in swipe direction"
                )
            } header: {
                Text("Reading & Scrolling")
                    .voiceOverHeader()
            }
            
            Section {
                gestureRow(
                    gesture: "Two-finger rotate",
                    action: "Rotor",
                    description: "Opens the rotor for additional options"
                )
                
                gestureRow(
                    gesture: "Swipe up/down",
                    action: "Rotor action",
                    description: "Performs action selected in rotor"
                )
                
                gestureRow(
                    gesture: "Two-finger double tap",
                    action: "Magic tap",
                    description: "Performs the primary action"
                )
            } header: {
                Text("Advanced Gestures")
                    .voiceOverHeader()
            }
        }
        .navigationTitle("VoiceOver Gestures")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func gestureRow(gesture: String, action: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(gesture)
                    .dynamicTextStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Text(action)
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.primary)
            }
            
            Text(description)
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
        }
        .appPadding(.vertical, AppSpacing.xs)
        .voiceOverCombine()
        .voiceOverLabel("\(gesture): \(action). \(description)")
    }
}

// MARK: - Settings Keys Extension

extension SettingsKey {
    // VoiceOver preferences
    static let voiceOverVerboseLabels = SettingsKey("voiceover_verbose_labels")
    static let voiceOverReadPrices = SettingsKey("voiceover_read_prices")
    static let voiceOverGroupRelatedItems = SettingsKey("voiceover_group_related")
    static let voiceOverAnnouncePositions = SettingsKey("voiceover_announce_positions")
    
    // VoiceOver announcements
    static let voiceOverAnnounceChanges = SettingsKey("voiceover_announce_changes")
    static let voiceOverAnnounceSyncStatus = SettingsKey("voiceover_announce_sync")
    static let voiceOverAnnouncementDelay = SettingsKey("voiceover_announcement_delay")
    
    // VoiceOver gestures
    static let voiceOverCustomActions = SettingsKey("voiceover_custom_actions")
    static let voiceOverMagicTap = SettingsKey("voiceover_magic_tap")
}