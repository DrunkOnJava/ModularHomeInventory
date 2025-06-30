import XCTest
import SnapshotTesting
import SwiftUI

final class NotificationsSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testNotificationSettingsView() {
        let view = createNotificationSettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testNotificationSettingsViewDarkMode() {
        let view = createNotificationSettingsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationSettingsViewCompact() {
        let view = createNotificationSettingsView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testNotificationSettingsViewAccessibility() {
        let view = createNotificationSettingsView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNotificationSettingsViewErrorState() {
        let view = createNotificationSettingsErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationSettingsViewNetworkError() {
        let view = createNotificationSettingsNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationSettingsViewPermissionDenied() {
        let view = createNotificationSettingsPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNotificationSettingsViewLoading() {
        let view = createNotificationSettingsLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationSettingsViewRefreshing() {
        let view = createNotificationSettingsRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNotificationHistoryView() {
        let view = createNotificationHistoryView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testNotificationHistoryViewDarkMode() {
        let view = createNotificationHistoryView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationHistoryViewCompact() {
        let view = createNotificationHistoryView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testNotificationHistoryViewAccessibility() {
        let view = createNotificationHistoryView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNotificationHistoryViewErrorState() {
        let view = createNotificationHistoryErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationHistoryViewNetworkError() {
        let view = createNotificationHistoryNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationHistoryViewPermissionDenied() {
        let view = createNotificationHistoryPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testNotificationHistoryViewLoading() {
        let view = createNotificationHistoryLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationHistoryViewRefreshing() {
        let view = createNotificationHistoryRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testAlertPreferencesView() {
        let view = createAlertPreferencesView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testAlertPreferencesViewDarkMode() {
        let view = createAlertPreferencesView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAlertPreferencesViewCompact() {
        let view = createAlertPreferencesView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testAlertPreferencesViewAccessibility() {
        let view = createAlertPreferencesView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testAlertPreferencesViewErrorState() {
        let view = createAlertPreferencesErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAlertPreferencesViewNetworkError() {
        let view = createAlertPreferencesNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAlertPreferencesViewPermissionDenied() {
        let view = createAlertPreferencesPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testAlertPreferencesViewLoading() {
        let view = createAlertPreferencesLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAlertPreferencesViewRefreshing() {
        let view = createAlertPreferencesRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testScheduledRemindersView() {
        let view = createScheduledRemindersView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testScheduledRemindersViewDarkMode() {
        let view = createScheduledRemindersView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testScheduledRemindersViewCompact() {
        let view = createScheduledRemindersView()
            .environment(\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func testScheduledRemindersViewAccessibility() {
        let view = createScheduledRemindersView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testScheduledRemindersViewErrorState() {
        let view = createScheduledRemindersErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testScheduledRemindersViewNetworkError() {
        let view = createScheduledRemindersNetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testScheduledRemindersViewPermissionDenied() {
        let view = createScheduledRemindersPermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testScheduledRemindersViewLoading() {
        let view = createScheduledRemindersLoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testScheduledRemindersViewRefreshing() {
        let view = createScheduledRemindersRefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
    private func createNotificationSettingsView() -> some View {
                NavigationView {
            Form {
                Section("Push Notifications") {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Warranty Expiration", isOn: .constant(true))
                    Toggle("Price Alerts", isOn: .constant(false))
                    Toggle("Backup Reminders", isOn: .constant(true))
                }
                
                Section("Notification Schedule") {
                    HStack {
                        Text("Quiet Hours")
                        Spacer()
                        Text("10:00 PM - 8:00 AM")
                            .foregroundColor(.secondary)
                    }
                    Toggle("Weekend Notifications", isOn: .constant(false))
                }
                
                Section("Alert Style") {
                    Picker("Banner Style", selection: .constant(1)) {
                        Text("Temporary").tag(0)
                        Text("Persistent").tag(1)
                    }
                    Toggle("Show Previews", isOn: .constant(true))
                    Toggle("Sound", isOn: .constant(true))
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {}
                }
            }
        }

    }
    
    private func createNotificationSettingsErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "bell",
            title: "NotificationSettings Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createNotificationSettingsNetworkErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createNotificationSettingsPermissionDeniedView() -> some View {
        NotificationsErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createNotificationSettingsLoadingView() -> some View {
        NotificationsLoadingStateView(
            message: "Loading NotificationSettings...",
            progress: 0.6
        )
    }
    
    private func createNotificationSettingsRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createNotificationSettingsView()
                .opacity(0.6)
        }
    }
    
    private func createNotificationHistoryView() -> some View {
                NavigationView {
            List {
                ForEach(0..<5) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: ["bell.badge", "exclamationmark.triangle", "checkmark.circle", "arrow.down.circle", "calendar.badge.exclamationmark"][i % 5])
                                .foregroundColor([.blue, .orange, .green, .purple, .red][i % 5])
                            Text(["New warranty added", "Item expiring soon", "Backup completed", "Update available", "Reminder"][i % 5])
                                .font(.headline)
                            Spacer()
                            Text(["2m ago", "1h ago", "3h ago", "1d ago", "2d ago"][i % 5])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Tap to view details about this notification")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Notification History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {}
                }
            }
        }

    }
    
    private func createNotificationHistoryErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "clock.arrow.circlepath",
            title: "NotificationHistory Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createNotificationHistoryNetworkErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createNotificationHistoryPermissionDeniedView() -> some View {
        NotificationsErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createNotificationHistoryLoadingView() -> some View {
        NotificationsLoadingStateView(
            message: "Loading NotificationHistory...",
            progress: 0.6
        )
    }
    
    private func createNotificationHistoryRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createNotificationHistoryView()
                .opacity(0.6)
        }
    }
    
    private func createAlertPreferencesView() -> some View {
                NavigationView {
            Form {
                Section("Critical Alerts") {
                    Toggle("Override Silent Mode", isOn: .constant(true))
                    Toggle("Emergency Notifications", isOn: .constant(true))
                }
                
                Section("Alert Types") {
                    ForEach(["Security", "System", "Updates", "Reminders"], id: \.self) { type in
                        HStack {
                            Text(type)
                            Spacer()
                            Picker("", selection: .constant(1)) {
                                Text("Off").tag(0)
                                Text("Banner").tag(1)
                                Text("Alert").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 180)
                        }
                    }
                }
                
                Section("Alert Behavior") {
                    Stepper("Repeat alerts: 2 times", value: .constant(2), in: 0...5)
                    Toggle("Group notifications", isOn: .constant(true))
                }
            }
            .navigationTitle("Alert Preferences")
        }

    }
    
    private func createAlertPreferencesErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "exclamationmark.triangle",
            title: "AlertPreferences Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createAlertPreferencesNetworkErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createAlertPreferencesPermissionDeniedView() -> some View {
        NotificationsErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createAlertPreferencesLoadingView() -> some View {
        NotificationsLoadingStateView(
            message: "Loading AlertPreferences...",
            progress: 0.6
        )
    }
    
    private func createAlertPreferencesRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createAlertPreferencesView()
                .opacity(0.6)
        }
    }
    
    private func createScheduledRemindersView() -> some View {
                NavigationView {
            List {
                Section("Active Reminders") {
                    ForEach(["Daily backup", "Weekly review", "Monthly report"], id: \.self) { reminder in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text(reminder)
                                    .font(.headline)
                                Text("Next: Tomorrow at 9:00 AM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                        }
                    }
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Reminder")
                        }
                    }
                }
            }
            .navigationTitle("Scheduled Reminders")
        }

    }
    
    private func createScheduledRemindersErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "calendar.badge.clock",
            title: "ScheduledReminders Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func createScheduledRemindersNetworkErrorView() -> some View {
        NotificationsErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func createScheduledRemindersPermissionDeniedView() -> some View {
        NotificationsErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
    private func createScheduledRemindersLoadingView() -> some View {
        NotificationsLoadingStateView(
            message: "Loading ScheduledReminders...",
            progress: 0.6
        )
    }
    
    private func createScheduledRemindersRefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            createScheduledRemindersView()
                .opacity(0.6)
        }
    }
    
    private func createCombinedView() -> some View {
        TabView {
            createNotificationSettingsView()
                .tabItem {
                    Label("NotificationSettings", systemImage: "bell")
                }
                .tag(0)
            
            createNotificationHistoryView()
                .tabItem {
                    Label("NotificationHistory", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            createAlertPreferencesView()
                .tabItem {
                    Label("AlertPreferences", systemImage: "exclamationmark.triangle")
                }
                .tag(2)
            
            createScheduledRemindersView()
                .tabItem {
                    Label("ScheduledReminders", systemImage: "calendar.badge.clock")
                }
                .tag(3)
            
        }
    }
}

// MARK: - Helper Views

struct NotificationsErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct NotificationsLoadingStateView: View {
    let message: String
    let progress: Double?
    
    var body: some View {
        VStack(spacing: 20) {
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
            
            Text(message)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct NotificationsSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
