#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

# Helper method definitions - MUST BE DEFINED FIRST
def generate_view_tests(name, icon, color)
  <<-TESTS
    func test#{name}View() {
        let view = create#{name}View()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func test#{name}ViewDarkMode() {
        let view = create#{name}View()
            .environment(\\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{name}ViewCompact() {
        let view = create#{name}View()
            .environment(\\.horizontalSizeClass, .compact)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
    }
    
    func test#{name}ViewAccessibility() {
        let view = create#{name}View()
            .environment(\\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
TESTS
end

def generate_error_state_tests(name)
  <<-TESTS
    func test#{name}ViewErrorState() {
        let view = create#{name}ErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{name}ViewNetworkError() {
        let view = create#{name}NetworkErrorView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{name}ViewPermissionDenied() {
        let view = create#{name}PermissionDeniedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
TESTS
end

def generate_loading_state_tests(name)
  <<-TESTS
    func test#{name}ViewLoading() {
        let view = create#{name}LoadingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{name}ViewRefreshing() {
        let view = create#{name}RefreshingView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
TESTS
end

# View content generators
def notifications_settings_view
  <<-VIEW
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
VIEW
end

def notification_history_view
  <<-VIEW
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
VIEW
end

def alert_preferences_view
  <<-VIEW
        NavigationView {
            Form {
                Section("Critical Alerts") {
                    Toggle("Override Silent Mode", isOn: .constant(true))
                    Toggle("Emergency Notifications", isOn: .constant(true))
                }
                
                Section("Alert Types") {
                    ForEach(["Security", "System", "Updates", "Reminders"], id: \\.self) { type in
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
VIEW
end

def scheduled_reminders_view
  <<-VIEW
        NavigationView {
            List {
                Section("Active Reminders") {
                    ForEach(["Daily backup", "Weekly review", "Monthly report"], id: \\.self) { reminder in
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
VIEW
end

def share_sheet_view
  <<-VIEW
        VStack(spacing: 0) {
            // Preview
            VStack {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Inventory Report.pdf")
                    .font(.headline)
                Text("2.4 MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Share options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(["Messages", "Mail", "AirDrop", "Notes"], id: \\.self) { app in
                        VStack {
                            Image(systemName: ["message.fill", "envelope.fill", "wifi", "note.text"][["Messages", "Mail", "AirDrop", "Notes"].firstIndex(of: app)!])
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                            Text(app)
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 0) {
                ForEach(["Copy", "Save to Files", "Print"], id: \\.self) { action in
                    Button(action: {}) {
                        HStack {
                            Image(systemName: ["doc.on.doc", "folder", "printer"][["Copy", "Save to Files", "Print"].firstIndex(of: action)!])
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text(action)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                    }
                    if action != "Print" {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
VIEW
end

def export_options_view
  <<-VIEW
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: .constant(0)) {
                        Label("CSV", systemImage: "tablecells").tag(0)
                        Label("PDF", systemImage: "doc.richtext").tag(1)
                        Label("Excel", systemImage: "tablecells.fill").tag(2)
                        Label("JSON", systemImage: "curlybraces").tag(3)
                    }
                }
                
                Section("Include") {
                    Toggle("Photos", isOn: .constant(true))
                    Toggle("Receipts", isOn: .constant(true))
                    Toggle("Warranties", isOn: .constant(false))
                    Toggle("Purchase History", isOn: .constant(true))
                }
                
                Section("Date Range") {
                    Picker("Period", selection: .constant(1)) {
                        Text("Last 30 days").tag(0)
                        Text("Last 90 days").tag(1)
                        Text("Last year").tag(2)
                        Text("All time").tag(3)
                        Text("Custom").tag(4)
                    }
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Label("Export", systemImage: "arrow.down.doc")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Options")
        }
VIEW
end

def pdf_export_view
  <<-VIEW
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // PDF Preview
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                        .overlay(
                            VStack {
                                Image(systemName: "doc.richtext.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                Text("PDF Preview")
                                    .font(.headline)
                                Text("Page 1 of 12")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                    
                    // Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PDF Options")
                            .font(.headline)
                        
                        Toggle("Include cover page", isOn: .constant(true))
                        Toggle("Add page numbers", isOn: .constant(true))
                        Toggle("Include table of contents", isOn: .constant(false))
                        
                        HStack {
                            Text("Paper size")
                            Spacer()
                            Picker("", selection: .constant(0)) {
                                Text("Letter").tag(0)
                                Text("A4").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: {}) {
                        Label("Generate PDF", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("PDF Export")
        }
VIEW
end

def cloud_backup_view
  <<-VIEW
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status card
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Cloud Backup Active")
                            .font(.headline)
                        Text("Last backup: 2 hours ago")
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: 0.75)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("750 MB of 1 GB used")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("75%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Backup settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Backup Settings")
                            .font(.headline)
                        
                        Toggle("Automatic backup", isOn: .constant(true))
                        Toggle("Backup over cellular", isOn: .constant(false))
                        Toggle("Include photos", isOn: .constant(true))
                        
                        HStack {
                            Text("Backup frequency")
                            Spacer()
                            Menu("Daily") {
                                Button("Hourly") {}
                                Button("Daily") {}
                                Button("Weekly") {}
                                Button("Manual") {}
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Backup Now", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {}) {
                            Label("Restore", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cloud Backup")
        }
VIEW
end

def network_error_view
  <<-VIEW
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please check your network settings and try again")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Work Offline")
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
VIEW
end

def server_error_view
  <<-VIEW
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Server Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We're having trouble connecting to our servers. Please try again later.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Error Code: 503")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
            
            Button(action: {}) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(width: 200)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
VIEW
end

def validation_error_view
  <<-VIEW
        NavigationView {
            Form {
                Section {
                    HStack {
                        TextField("Email", text: .constant("invalid-email"))
                            .foregroundColor(.red)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    HStack {
                        SecureField("Password", text: .constant("123"))
                            .foregroundColor(.red)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Section("Requirements") {
                    Label("Valid email format", systemImage: "xmark")
                        .foregroundColor(.red)
                    Label("Minimum 8 characters", systemImage: "xmark")
                        .foregroundColor(.red)
                    Label("One uppercase letter", systemImage: "checkmark")
                        .foregroundColor(.green)
                    Label("One number", systemImage: "xmark")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Validation Errors")
        }
VIEW
end

def permission_error_view
  <<-VIEW
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 12) {
                Text("Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This feature requires camera access to scan barcodes")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Grant Permission", systemImage: "camera")
                        .frame(width: 250)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("Open Settings")
                        .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Text("Skip for Now")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
VIEW
end

def full_screen_loading_view
  <<-VIEW
        VStack(spacing: 30) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
            
            Text("Loading your inventory...")
                .font(.headline)
                .padding(.top)
            
            Text("This may take a few moments")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
VIEW
end

def inline_loading_view
  <<-VIEW
        VStack {
            // Header
            HStack {
                Text("Recent Items")
                    .font(.headline)
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
            }
            .padding()
            
            // Content with loading overlay
            List {
                ForEach(0..<3) { i in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading) {
                            Text("Loading item...")
                                .foregroundColor(.secondary)
                            Text("Please wait")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .disabled(true)
            .opacity(0.6)
            
            // Loading indicator at bottom
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
VIEW
end

def skeleton_loading_view
  <<-VIEW
        VStack(spacing: 16) {
            // Skeleton header
            HStack {
                SkeletonView()
                    .frame(width: 120, height: 20)
                Spacer()
                SkeletonView()
                    .frame(width: 60, height: 20)
            }
            .padding()
            
            // Skeleton cards
            ForEach(0..<4) { _ in
                HStack(spacing: 12) {
                    SkeletonView()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView()
                            .frame(width: 150, height: 16)
                        SkeletonView()
                            .frame(width: 100, height: 14)
                        SkeletonView()
                            .frame(width: 80, height: 14)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
VIEW
end

def progress_indicator_view
  <<-VIEW
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Circular progress
                    VStack {
                        Text("Upload Progress")
                            .font(.headline)
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: 0.75)
                                .stroke(Color.green, lineWidth: 20)
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("75%")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("3 of 4 files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Linear progress bars
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Processing Items")
                            .font(.headline)
                        
                        ForEach(["Photos", "Documents", "Metadata", "Optimization"], id: \\.self) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(task)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(task == "Photos" ? "Complete" : task == "Documents" ? "85%" : task == "Metadata" ? "45%" : "Waiting")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: task == "Photos" ? 1.0 : task == "Documents" ? 0.85 : task == "Metadata" ? 0.45 : 0.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: task == "Photos" ? .green : .blue))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Progress Indicators")
        }
VIEW
end

def voiceover_optimized_view
  <<-VIEW
        NavigationView {
            VStack(spacing: 20) {
                Text("VoiceOver Optimized")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityLabel("VoiceOver Optimized View")
                    .accessibilityAddTraits(.isHeader)
                
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .accessibilityHidden(true)
                            Text("Play Audio Description")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .accessibilityLabel("Play audio description of current screen")
                    .accessibilityHint("Double tap to play")
                    
                    ForEach(["Navigation", "Content", "Actions"], id: \\.self) { section in
                        VStack(alignment: .leading) {
                            Text(section)
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            Text("Optimized for screen readers with descriptive labels")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("\\(section) section is optimized for screen readers with descriptive labels")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
        }
VIEW
end

def large_text_support_view
  <<-VIEW
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Large Text Support")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    Text("This view automatically adjusts to your preferred text size")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Automatic scaling", systemImage: "textformat.size")
                            .font(.headline)
                        Label("Readable layouts", systemImage: "text.alignleft")
                            .font(.headline)
                        Label("Flexible spacing", systemImage: "arrow.up.and.down")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("Sample Content")
                        .font(.headline)
                    
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Button("Cancel") {}
                            .font(.body)
                        Spacer()
                        Button("Confirm") {}
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Text Size")
        }
VIEW
end

def high_contrast_view
  <<-VIEW
        VStack(spacing: 0) {
            // High contrast header
            HStack {
                Text("High Contrast Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black)
            
            // Content with high contrast
            VStack(spacing: 16) {
                ForEach(["Primary Action", "Secondary Action", "Disabled Action"], id: \\.self) { action in
                    Button(action: {}) {
                        Text(action)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(action == "Disabled Action" ? Color.gray : action == "Primary Action" ? Color.black : Color.white)
                            .foregroundColor(action == "Secondary Action" ? .black : .white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: action == "Secondary Action" ? 2 : 0)
                            )
                            .cornerRadius(8)
                    }
                    .disabled(action == "Disabled Action")
                }
                
                // High contrast cards
                VStack(alignment: .leading, spacing: 8) {
                    Text("Important Information")
                        .font(.headline)
                    Text("High contrast improves readability for users with visual impairments")
                        .font(.body)
                }
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )
                
                // Status indicators
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Success")
                            .font(.caption)
                    }
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Warning")
                            .font(.caption)
                    }
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                        Text("Error")
                            .font(.caption)
                    }
                }
                .padding()
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGray6))
VIEW
end

def reduced_motion_view
  <<-VIEW
        NavigationView {
            VStack(spacing: 20) {
                Text("Reduced Motion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    // No animations indicator
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .font(.title)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Animations Disabled")
                                .font(.headline)
                            Text("Smooth transitions without motion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Static transitions
                    Text("All transitions use fade effects instead of sliding or scaling animations")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // Example buttons
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Text("Instant Feedback")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {}) {
                            Text("No Spring Effects")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Motion")
            .navigationBarTitleDisplayMode(.inline)
        }
VIEW
end

def split_view_layout
  <<-VIEW
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Master/Sidebar
                VStack(alignment: .leading) {
                    Text("Categories")
                        .font(.headline)
                        .padding()
                    
                    List {
                        ForEach(["All Items", "Electronics", "Furniture", "Books", "Clothing"], id: \\.self) { category in
                            HStack {
                                Image(systemName: category == "All Items" ? "square.grid.2x2" : "folder")
                                    .foregroundColor(.blue)
                                Text(category)
                                Spacer()
                                if category == "Electronics" {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(category == "Electronics" ? Color(.systemGray5) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .frame(width: geometry.size.width * 0.35)
                .background(Color(.systemGray6))
                
                Divider()
                
                // Detail
                VStack {
                    HStack {
                        Text("Electronics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "plus")
                        }
                    }
                    .padding()
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                        ForEach(0..<6) { i in
                            VStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 150)
                                    .overlay(
                                        Image(systemName: "tv")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                                Text("Item \\(i + 1)")
                                    .font(.headline)
                                Text("$\\(100 * (i + 1))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
VIEW
end

def master_detail_layout
  <<-VIEW
        NavigationView {
            // Master list
            List {
                ForEach(0..<10) { i in
                    NavigationLink(destination: detailView(for: i)) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("\\(i + 1)")
                                        .font(.headline)
                                )
                            VStack(alignment: .leading) {
                                Text("Item \\(i + 1)")
                                    .font(.headline)
                                Text("Category • $\\(100 * (i + 1))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Inventory")
            
            // Default detail view
            VStack {
                Image(systemName: "arrow.left")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("Select an item")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        
        func detailView(for index: Int) -> some View {
            ScrollView {
                VStack(spacing: 20) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 300)
                        .overlay(
                            Text("\\(index + 1)")
                                .font(.system(size: 60))
                        )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Item \\(index + 1)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("$\\(100 * (index + 1))")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("Added 3 days ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
VIEW
end

def multi_column_layout
  <<-VIEW
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Multi-Column Layout")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Three column layout
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(["Recent", "Categories", "Statistics"], id: \\.self) { column in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(column)
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                if column == "Recent" {
                                    ForEach(0..<4) { i in
                                        HStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(.systemGray5))
                                                .frame(width: 40, height: 40)
                                            VStack(alignment: .leading) {
                                                Text("Item \\(i + 1)")
                                                    .font(.subheadline)
                                                Text("2 hrs ago")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                } else if column == "Categories" {
                                    ForEach(["Electronics", "Home", "Books", "Other"], id: \\.self) { cat in
                                        HStack {
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(.blue)
                                            Text(cat)
                                            Spacer()
                                            Text("\\(Int.random(in: 5...20))")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                } else {
                                    VStack(spacing: 16) {
                                        StatCard(title: "Total Items", value: "156", color: .blue)
                                        StatCard(title: "Total Value", value: "$8,435", color: .green)
                                        StatCard(title: "Categories", value: "12", color: .purple)
                                    }
                                }
                            }
                            .frame(width: (geometry.size.width - 48) / 3)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        
        struct StatCard: View {
            let title: String
            let value: String
            let color: Color
            
            var body: some View {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
VIEW
end

def compact_adaptive_layout
  <<-VIEW
        VStack(spacing: 0) {
            // Adaptive header
            HStack {
                Button(action: {}) {
                    Image(systemName: "line.horizontal.3")
                }
                Spacer()
                Text("Adaptive Layout")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "square.grid.2x2")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            GeometryReader { geometry in
                if geometry.size.width < 400 {
                    // Compact layout (single column)
                    List {
                        ForEach(0..<8) { i in
                            CompactItemRow(index: i)
                        }
                    }
                } else {
                    // Regular layout (grid)
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                            ForEach(0..<8) { i in
                                ItemCard(index: i)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        
        struct CompactItemRow: View {
            let index: Int
            
            var body: some View {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 50)
                        .overlay(Text("\\(index + 1)"))
                    VStack(alignment: .leading) {
                        Text("Item \\(index + 1)")
                            .font(.headline)
                        Text("Compact layout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$\\(50 * (index + 1))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
        }
        
        struct ItemCard: View {
            let index: Int
            
            var body: some View {
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(Text("\\(index + 1)").font(.largeTitle))
                    Text("Item \\(index + 1)")
                        .font(.headline)
                    Text("$\\(50 * (index + 1))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
VIEW
end

def generic_view(name, icon, color)
  <<-VIEW
        VStack(spacing: 20) {
            Image(systemName: "#{icon}")
                .font(.largeTitle)
                .foregroundColor(.#{color})
            Text("#{name} View")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Generic view for #{name}")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
VIEW
end

# Helper to get view content
def get_view_content(name, icon, color)
  case name
  when 'NotificationSettings'
    notifications_settings_view
  when 'NotificationHistory'
    notification_history_view
  when 'AlertPreferences'
    alert_preferences_view
  when 'ScheduledReminders'
    scheduled_reminders_view
  when 'ShareSheet'
    share_sheet_view
  when 'ExportOptions'
    export_options_view
  when 'PDFExport'
    pdf_export_view
  when 'CloudBackup'
    cloud_backup_view
  when 'NetworkError'
    network_error_view
  when 'ServerError'
    server_error_view
  when 'ValidationError'
    validation_error_view
  when 'PermissionError'
    permission_error_view
  when 'FullScreenLoading'
    full_screen_loading_view
  when 'InlineLoading'
    inline_loading_view
  when 'SkeletonLoading'
    skeleton_loading_view
  when 'ProgressIndicator'
    progress_indicator_view
  when 'VoiceOverOptimized'
    voiceover_optimized_view
  when 'LargeTextSupport'
    large_text_support_view
  when 'HighContrastMode'
    high_contrast_view
  when 'ReducedMotion'
    reduced_motion_view
  when 'SplitView'
    split_view_layout
  when 'MasterDetail'
    master_detail_layout
  when 'MultiColumn'
    multi_column_layout
  when 'CompactAdaptive'
    compact_adaptive_layout
  else
    generic_view(name, icon, color)
  end
end

# Additional test configurations
additional_tests = {
  'NotificationsSnapshotTests' => {
    views: [
      { name: 'NotificationSettings', icon: 'bell', color: 'blue' },
      { name: 'NotificationHistory', icon: 'clock.arrow.circlepath', color: 'gray' },
      { name: 'AlertPreferences', icon: 'exclamationmark.triangle', color: 'orange' },
      { name: 'ScheduledReminders', icon: 'calendar.badge.clock', color: 'purple' }
    ]
  },
  'SharingExportSnapshotTests' => {
    views: [
      { name: 'ShareSheet', icon: 'square.and.arrow.up', color: 'blue' },
      { name: 'ExportOptions', icon: 'arrow.down.doc', color: 'green' },
      { name: 'PDFExport', icon: 'doc.richtext', color: 'red' },
      { name: 'CloudBackup', icon: 'icloud.and.arrow.up', color: 'blue' }
    ]
  },
  'ErrorStatesSnapshotTests' => {
    views: [
      { name: 'NetworkError', icon: 'wifi.slash', color: 'red' },
      { name: 'ServerError', icon: 'exclamationmark.icloud', color: 'orange' },
      { name: 'ValidationError', icon: 'xmark.circle', color: 'red' },
      { name: 'PermissionError', icon: 'lock.shield', color: 'yellow' }
    ]
  },
  'LoadingStatesSnapshotTests' => {
    views: [
      { name: 'FullScreenLoading', icon: 'hourglass', color: 'gray' },
      { name: 'InlineLoading', icon: 'arrow.clockwise', color: 'blue' },
      { name: 'SkeletonLoading', icon: 'rectangle.3.group', color: 'gray' },
      { name: 'ProgressIndicator', icon: 'percent', color: 'green' }
    ]
  },
  'AccessibilitySnapshotTests' => {
    views: [
      { name: 'VoiceOverOptimized', icon: 'speaker.wave.3', color: 'blue' },
      { name: 'LargeTextSupport', icon: 'textformat.size', color: 'purple' },
      { name: 'HighContrastMode', icon: 'circle.lefthalf.filled', color: 'black' },
      { name: 'ReducedMotion', icon: 'figure.walk.motion', color: 'orange' }
    ]
  },
  'TabletLayoutSnapshotTests' => {
    views: [
      { name: 'SplitView', icon: 'rectangle.split.2x1', color: 'blue' },
      { name: 'MasterDetail', icon: 'sidebar.left', color: 'gray' },
      { name: 'MultiColumn', icon: 'rectangle.split.3x1', color: 'green' },
      { name: 'CompactAdaptive', icon: 'rectangle.portrait.split.2x1', color: 'purple' }
    ]
  }
}

# Create test directories
additional_tests.each do |test_name, config|
  dir_path = "HomeInventoryModularTests/AdditionalTests"
  FileUtils.mkdir_p(dir_path)
  
  # Generate test file
  test_content = <<-SWIFT
import XCTest
import SnapshotTesting
import SwiftUI

final class #{test_name}: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
SWIFT

  # Add tests for each view
  config[:views].each do |view|
    test_content += generate_view_tests(view[:name], view[:icon], view[:color])
    test_content += "\n"
    
    # Add error states for relevant tests
    if test_name != 'AccessibilitySnapshotTests' && test_name != 'TabletLayoutSnapshotTests'
      test_content += generate_error_state_tests(view[:name])
      test_content += "\n"
    end
    
    # Add loading states for relevant tests
    if test_name != 'ErrorStatesSnapshotTests' && test_name != 'AccessibilitySnapshotTests'
      test_content += generate_loading_state_tests(view[:name])
      test_content += "\n"
    end
  end
  
  # Add combined view test
  test_content += <<-SWIFT
    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
SWIFT

  # Add view creators
  config[:views].each do |view|
    # Normal view
    test_content += <<-SWIFT
    private func create#{view[:name]}View() -> some View {
        #{get_view_content(view[:name], view[:icon], view[:color])}
    }
    
SWIFT

    # Error views
    if test_name != 'AccessibilitySnapshotTests' && test_name != 'TabletLayoutSnapshotTests'
      test_content += <<-SWIFT
    private func create#{view[:name]}ErrorView() -> some View {
        ErrorStateView(
            icon: "#{view[:icon]}",
            title: "#{view[:name]} Error",
            message: "Something went wrong",
            retryAction: {}
        )
    }
    
    private func create#{view[:name]}NetworkErrorView() -> some View {
        ErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection",
            retryAction: {}
        )
    }
    
    private func create#{view[:name]}PermissionDeniedView() -> some View {
        ErrorStateView(
            icon: "lock.shield",
            title: "Permission Required",
            message: "Grant access to continue",
            retryAction: {}
        )
    }
    
SWIFT
    end
    
    # Loading views
    if test_name != 'ErrorStatesSnapshotTests' && test_name != 'AccessibilitySnapshotTests'
      test_content += <<-SWIFT
    private func create#{view[:name]}LoadingView() -> some View {
        LoadingStateView(
            message: "Loading #{view[:name]}...",
            progress: 0.6
        )
    }
    
    private func create#{view[:name]}RefreshingView() -> some View {
        VStack {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Refreshing...")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            create#{view[:name]}View()
                .opacity(0.6)
        }
    }
    
SWIFT
    end
  end
  
  # Add combined view
  test_content += <<-SWIFT
    private func createCombinedView() -> some View {
        TabView {
SWIFT

  config[:views].each_with_index do |view, index|
    test_content += <<-SWIFT
            create#{view[:name]}View()
                .tabItem {
                    Label("#{view[:name]}", systemImage: "#{view[:icon]}")
                }
                .tag(#{index})
            
SWIFT
  end
  
  test_content += <<-SWIFT
        }
    }
}

// MARK: - Helper Views

struct ErrorStateView: View {
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

struct LoadingStateView: View {
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

struct SkeletonView: View {
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
SWIFT

  # Write test file
  File.write("#{dir_path}/#{test_name}.swift", test_content)
  puts "✅ Created #{test_name}.swift"
end

# Create test runner scripts
puts "\n🏃 Creating test runner scripts..."

additional_tests.each do |test_name, _|
  runner_name = test_name.gsub('SnapshotTests', '').downcase
  script_content = <<-BASH
#!/bin/bash

# Test runner for #{test_name}

echo "📸 Running #{test_name}"
echo "====================================="

# Set test environment
export SNAPSHOT_TEST_MODE=${RECORD_SNAPSHOTS:-"verify"}

# Run tests
xcodebuild test \\
    -project HomeInventoryModular.xcodeproj \\
    -scheme HomeInventoryModular \\
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=latest' \\
    -only-testing:HomeInventoryModularTests/#{test_name} \\
    -resultBundlePath TestResults/Additional/#{test_name}/#{test_name}.xcresult \\
    | xcbeautify

# Get exit code
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    echo "⚠️  Some tests may have failed (expected in record mode)"
fi

# Count snapshots
SNAPSHOT_COUNT=$(find HomeInventoryModularTests/AdditionalTests/__Snapshots__/#{test_name}/ -name "*.png" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "📊 Snapshot Summary:"
echo "Total snapshots: $SNAPSHOT_COUNT"
echo ""
echo "✅ Done!"
BASH

  script_path = "scripts/test-runners/test-#{runner_name}.sh"
  File.write(script_path, script_content)
  FileUtils.chmod(0755, script_path)
  puts "  ✓ Created #{script_path}"
end

# Update project to include new test files
puts "\n📱 Updating Xcode project..."

project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Find or create test groups
test_group = project.main_group['HomeInventoryModularTests']
additional_group = test_group['AdditionalTests'] || test_group.new_group('AdditionalTests')

# Add test files to project
additional_tests.each do |test_name, _|
  file_path = "AdditionalTests/#{test_name}.swift"
  
  unless additional_group.find_file_by_path(file_path)
    file_ref = additional_group.new_reference(file_path)
    test_target.source_build_phase.add_file_reference(file_ref)
    puts "  ✓ Added #{test_name}.swift to project"
  end
end

# Save project
project.save

puts "\n✅ Successfully created additional snapshot tests!"
puts "\nNew test groups:"
additional_tests.each do |test_name, config|
  puts "  • #{test_name} (#{config[:views].length} views)"
end

puts "\nTo run the new tests:"
puts "  RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[group].sh"
puts "\nExample:"
puts "  RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-notifications.sh"