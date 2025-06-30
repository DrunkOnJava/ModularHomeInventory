#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

# Create ExpandedTests directory
expanded_tests_dir = 'HomeInventoryModularTests/ExpandedTests'
FileUtils.mkdir_p(expanded_tests_dir)

# Define expanded test categories with more comprehensive scenarios
expanded_tests = {
  'EmptyStatesSnapshotTests' => {
    views: [
      { name: 'NoItems', icon: 'tray', color: 'gray' },
      { name: 'NoSearchResults', icon: 'magnifyingglass', color: 'gray' },
      { name: 'NoNotifications', icon: 'bell.slash', color: 'gray' },
      { name: 'NoBackups', icon: 'icloud.slash', color: 'gray' },
      { name: 'NoCollections', icon: 'folder', color: 'gray' }
    ]
  },
  'SuccessStatesSnapshotTests' => {
    views: [
      { name: 'ItemAdded', icon: 'checkmark.circle.fill', color: 'green' },
      { name: 'BackupComplete', icon: 'icloud.and.arrow.up', color: 'green' },
      { name: 'ExportSuccess', icon: 'square.and.arrow.up', color: 'green' },
      { name: 'SyncComplete', icon: 'arrow.triangle.2.circlepath', color: 'green' },
      { name: 'PaymentSuccess', icon: 'creditcard.fill', color: 'green' }
    ]
  },
  'FormValidationSnapshotTests' => {
    views: [
      { name: 'AddItemForm', icon: 'plus.square', color: 'blue' },
      { name: 'EditItemForm', icon: 'pencil', color: 'orange' },
      { name: 'LoginForm', icon: 'person.circle', color: 'blue' },
      { name: 'SettingsForm', icon: 'gearshape', color: 'gray' },
      { name: 'FeedbackForm', icon: 'bubble.left', color: 'purple' }
    ]
  },
  'ModalsAndSheetsSnapshotTests' => {
    views: [
      { name: 'ActionSheet', icon: 'ellipsis.circle', color: 'blue' },
      { name: 'ConfirmationDialog', icon: 'questionmark.circle', color: 'orange' },
      { name: 'DetailModal', icon: 'info.circle', color: 'blue' },
      { name: 'FilterSheet', icon: 'line.horizontal.3.decrease.circle', color: 'purple' },
      { name: 'SortOptions', icon: 'arrow.up.arrow.down', color: 'green' }
    ]
  },
  'OnboardingFlowSnapshotTests' => {
    views: [
      { name: 'Welcome', icon: 'hand.wave', color: 'blue' },
      { name: 'Features', icon: 'star', color: 'yellow' },
      { name: 'Permissions', icon: 'lock.shield', color: 'green' },
      { name: 'AccountSetup', icon: 'person.crop.circle.badge.plus', color: 'blue' },
      { name: 'Completion', icon: 'checkmark.seal', color: 'green' }
    ]
  },
  'SettingsVariationsSnapshotTests' => {
    views: [
      { name: 'GeneralSettings', icon: 'gearshape', color: 'gray' },
      { name: 'PrivacySettings', icon: 'hand.raised', color: 'blue' },
      { name: 'NotificationPrefs', icon: 'bell', color: 'red' },
      { name: 'DataAndStorage', icon: 'externaldrive', color: 'green' },
      { name: 'AboutScreen', icon: 'info.circle', color: 'blue' }
    ]
  },
  'InteractionStatesSnapshotTests' => {
    views: [
      { name: 'SwipeActions', icon: 'hand.draw', color: 'blue' },
      { name: 'LongPress', icon: 'hand.tap', color: 'purple' },
      { name: 'DragAndDrop', icon: 'arrow.up.and.down.and.arrow.left.and.right', color: 'green' },
      { name: 'PullToRefresh', icon: 'arrow.clockwise', color: 'blue' },
      { name: 'ContextMenu', icon: 'contextualmenu.and.cursorarrow', color: 'gray' }
    ]
  },
  'DataVisualizationSnapshotTests' => {
    views: [
      { name: 'Charts', icon: 'chart.bar', color: 'blue' },
      { name: 'Graphs', icon: 'chart.line.uptrend.xyaxis', color: 'green' },
      { name: 'Statistics', icon: 'percent', color: 'purple' },
      { name: 'Timeline', icon: 'calendar', color: 'red' },
      { name: 'Heatmap', icon: 'square.grid.3x3', color: 'orange' }
    ]
  }
}

# Helper method to generate test content
def generate_test_content(test_name, views)
  content = <<-SWIFT
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

  # Generate individual view tests
  views.each do |view|
    content += generate_view_tests(view[:name], view[:icon], view[:color])
  end
  
  # Generate combined view test
  content += <<-SWIFT
    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
SWIFT

  # Generate view creation methods
  views.each do |view|
    content += generate_view_creation(view[:name], view[:icon], view[:color])
  end
  
  # Generate combined view
  content += generate_combined_view(views)
  
  content += "}\n"
  
  # Add helper views at the end
  content += generate_helper_views(test_name)
  
  content
end

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

def generate_view_creation(name, icon, color)
  case name
  when 'NoItems', 'NoSearchResults', 'NoNotifications', 'NoBackups', 'NoCollections'
    generate_empty_state_view(name, icon, color)
  when 'ItemAdded', 'BackupComplete', 'ExportSuccess', 'SyncComplete', 'PaymentSuccess'
    generate_success_state_view(name, icon, color)
  when 'AddItemForm', 'EditItemForm', 'LoginForm', 'SettingsForm', 'FeedbackForm'
    generate_form_view(name, icon, color)
  when 'ActionSheet', 'ConfirmationDialog', 'DetailModal', 'FilterSheet', 'SortOptions'
    generate_modal_view(name, icon, color)
  when 'Welcome', 'Features', 'Permissions', 'AccountSetup', 'Completion'
    generate_onboarding_view(name, icon, color)
  when 'GeneralSettings', 'PrivacySettings', 'NotificationPrefs', 'DataAndStorage', 'AboutScreen'
    generate_settings_view(name, icon, color)
  when 'SwipeActions', 'LongPress', 'DragAndDrop', 'PullToRefresh', 'ContextMenu'
    generate_interaction_view(name, icon, color)
  when 'Charts', 'Graphs', 'Statistics', 'Timeline', 'Heatmap'
    generate_visualization_view(name, icon, color)
  else
    generate_generic_view(name, icon, color)
  end
end

def generate_empty_state_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  message = case name
  when 'NoItems' then "Start by adding your first item"
  when 'NoSearchResults' then "Try adjusting your search criteria"
  when 'NoNotifications' then "You're all caught up!"
  when 'NoBackups' then "Enable automatic backups in settings"
  when 'NoCollections' then "Create a collection to organize items"
  else "No data available"
  end
  
  <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "#{icon}")
                .font(.system(size: 80))
                .foregroundColor(.#{color}.opacity(0.5))
            
            Text("#{title}")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("#{message}")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {}) {
                Label("Get Started", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
VIEW
end

def generate_success_state_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  message = case name
  when 'ItemAdded' then "Your item has been successfully added"
  when 'BackupComplete' then "All data backed up successfully"
  when 'ExportSuccess' then "Export completed successfully"
  when 'SyncComplete' then "All changes synced"
  when 'PaymentSuccess' then "Payment processed successfully"
  else "Operation completed successfully"
  end
  
  <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.#{color}.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "#{icon}")
                    .font(.system(size: 60))
                    .foregroundColor(.#{color})
            }
            
            Text("#{title}")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("#{message}")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Done")
                        .frame(minWidth: 100)
                        .padding()
                        .background(Color.#{color})
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("View Details")
                        .foregroundColor(.#{color})
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
VIEW
end

def generate_form_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  <<-VIEW
    private func create#{name}View() -> some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: .constant(""))
                    TextField("Description", text: .constant(""), axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Additional Details") {
                    Picker("Category", selection: .constant(0)) {
                        Text("Electronics").tag(0)
                        Text("Furniture").tag(1)
                        Text("Clothing").tag(2)
                    }
                    
                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("$0.00", text: .constant(""))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Options") {
                    Toggle("Enable notifications", isOn: .constant(true))
                    Toggle("Share with family", isOn: .constant(false))
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Label("Save", systemImage: "#{icon}")
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.#{color})
                }
            }
            .navigationTitle("#{title}")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {}
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {}
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
VIEW
end

def generate_modal_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  case name
  when 'ActionSheet'
    <<-VIEW
    private func create#{name}View() -> some View {
        ZStack {
            // Background content
            VStack {
                Text("Background Content")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            
            // Action sheet overlay
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Button(action: {}) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        Divider()
                        Button(action: {}) {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        Divider()
                        Button(action: {}) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.red)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Button(action: {}) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
    }
    
VIEW
  when 'ConfirmationDialog'
    <<-VIEW
    private func create#{name}View() -> some View {
        ZStack {
            // Background content
            Color(.systemGray6)
                .ignoresSafeArea()
            
            // Dialog
            VStack(spacing: 20) {
                Image(systemName: "#{icon}")
                    .font(.system(size: 50))
                    .foregroundColor(.#{color})
                
                Text("Are you sure?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This action cannot be undone. All associated data will be permanently deleted.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding()
        }
    }
    
VIEW
  else
    <<-VIEW
    private func create#{name}View() -> some View {
        VStack {
            HStack {
                Text("#{title}")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<5) { i in
                        HStack {
                            Image(systemName: "#{icon}")
                                .foregroundColor(.#{color})
                            Text("Option \\(i + 1)")
                            Spacer()
                            if i == 2 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: {}) {
                Text("Apply")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.#{color})
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 20)
    }
    
VIEW
  end
end

def generate_onboarding_view(name, icon, color)
  case name
  when 'Welcome'
    <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "#{icon}")
                .font(.system(size: 80))
                .foregroundColor(.#{color})
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                Text("Home Inventory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Text("Keep track of everything you own in one secure place")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.#{color})
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("I already have an account")
                        .foregroundColor(.#{color})
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
VIEW
  when 'Features'
    <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 30) {
            Text("Key Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 24) {
                FeatureRow(icon: "camera.fill", title: "Quick Capture", description: "Add items instantly with your camera", color: .blue)
                FeatureRow(icon: "doc.text.fill", title: "Smart Organization", description: "Automatically categorize your belongings", color: .green)
                FeatureRow(icon: "lock.fill", title: "Secure & Private", description: "Your data is encrypted and protected", color: .purple)
                FeatureRow(icon: "icloud.fill", title: "Cloud Sync", description: "Access your inventory anywhere", color: .orange)
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i == 1 ? Color.#{color} : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Button(action: {}) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.#{color})
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
VIEW
  else
    generate_generic_view(name, icon, color)
  end
end

def generate_settings_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  <<-VIEW
    private func create#{name}View() -> some View {
        NavigationView {
            List {
                Section {
                    SettingRow(icon: "#{icon}", title: "Option 1", value: "Enabled", color: .#{color})
                    SettingRow(icon: "bell", title: "Notifications", value: "On", color: .red)
                    SettingRow(icon: "lock", title: "Privacy", value: "High", color: .green)
                }
                
                Section("Advanced") {
                    SettingRow(icon: "gearshape.2", title: "Advanced Settings", value: nil, color: .gray)
                    SettingRow(icon: "questionmark.circle", title: "Help & Support", value: nil, color: .blue)
                    SettingRow(icon: "info.circle", title: "About", value: "v1.0.0", color: .gray)
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("#{title}")
        }
    }
    
VIEW
end

def generate_interaction_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 20) {
            Text("#{title}")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<5) { i in
                        InteractionRow(
                            title: "Item \\(i + 1)",
                            subtitle: "Swipe or tap to interact",
                            icon: "#{icon}",
                            color: .#{color}
                        )
                    }
                }
                .padding()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "#{icon}")
                        .foregroundColor(.#{color})
                    Text("#{title} enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("Try interacting with the items above")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
VIEW
end

def generate_visualization_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  <<-VIEW
    private func create#{name}View() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header stats
                    HStack(spacing: 16) {
                        StatCard(title: "Total", value: "156", trend: "+12%", color: .#{color})
                        StatCard(title: "Value", value: "$8.4K", trend: "+5%", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Main visualization
                    VStack(alignment: .leading) {
                        Text("#{title}")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                            
                            Image(systemName: "#{icon}")
                                .font(.system(size: 60))
                                .foregroundColor(.#{color}.opacity(0.3))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Legend
                    HStack(spacing: 20) {
                        LegendItem(color: .#{color}, label: "Category A")
                        LegendItem(color: .green, label: "Category B")
                        LegendItem(color: .orange, label: "Category C")
                    }
                    .padding()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        ForEach(0..<3) { i in
                            HStack {
                                Circle()
                                    .fill(i == 0 ? Color.#{color} : i == 1 ? Color.green : Color.orange)
                                    .frame(width: 12, height: 12)
                                Text("Data point \\(i + 1)")
                                Spacer()
                                Text("\\(Int.random(in: 20...100))%")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
VIEW
end

def generate_generic_view(name, icon, color)
  title = name.gsub(/([A-Z])/, ' \\1').strip
  
  <<-VIEW
    private func create#{name}View() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "#{icon}")
                .font(.system(size: 60))
                .foregroundColor(.#{color})
            
            Text("#{title}")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("This is a placeholder for #{title}")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
VIEW
end

def generate_combined_view(views)
  <<-COMBINED
    private func createCombinedView() -> some View {
        TabView {
COMBINED
  
  views.each_with_index do |view, index|
    content = <<-TAB
            create#{view[:name]}View()
                .tabItem {
                    Label("#{view[:name]}", systemImage: "#{view[:icon]}")
                }
                .tag(#{index})
            
TAB
    result = content
  end
  
  result = <<-COMBINED
        }
    }
COMBINED
end

def generate_helper_views(test_name)
  prefix = test_name.gsub('SnapshotTests', '')
  
  <<-HELPERS

// MARK: - Helper Views

struct #{prefix}FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct #{prefix}SettingRow: View {
    let icon: String
    let title: String
    let value: String?
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(title)
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct #{prefix}InteractionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct #{prefix}StatCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 4) {
                Image(systemName: trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(trend)
                    .font(.caption2)
            }
            .foregroundColor(trend.hasPrefix("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct #{prefix}LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
HELPERS
end

# Create test groups and generate files
total_files = 0
expanded_tests.each do |test_name, config|
  puts "Creating #{test_name}..."
  
  file_path = File.join(expanded_tests_dir, "#{test_name}.swift")
  content = generate_test_content(test_name, config[:views])
  
  File.write(file_path, content)
  total_files += 1
  
  # Add to test target
  file_ref = project.main_group.new_reference(file_path)
  test_target.add_file_references([file_ref])
end

# Create test runner scripts
test_runners_dir = 'scripts/test-runners'
FileUtils.mkdir_p(test_runners_dir)

expanded_tests.each do |test_name, _|
  script_name = test_name.gsub(/([A-Z])/, '-\\1').downcase.gsub(/^-/, '').gsub('snapshottests', '').gsub('--', '-')
  script_path = File.join(test_runners_dir, "test-#{script_name}.sh")
  
  script_content = <<-SCRIPT
#!/bin/bash

# Test runner for #{test_name}

echo "📸 Running #{test_name}"
echo "====================================="

# Set test environment
export SNAPSHOT_TEST_MODE=${RECORD_SNAPSHOTS:-"verify"}

# Remove existing result bundle if it exists
RESULT_BUNDLE_PATH="TestResults/Expanded/#{test_name}/#{test_name}.xcresult"
if [ -d "$RESULT_BUNDLE_PATH" ]; then
  rm -rf "$RESULT_BUNDLE_PATH"
fi

# Run tests
xcodebuild test \\
    -project HomeInventoryModular.xcodeproj \\
    -scheme HomeInventoryModular \\
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=latest' \\
    -only-testing:HomeInventoryModularTests/#{test_name} \\
    -resultBundlePath "$RESULT_BUNDLE_PATH" \\
    | xcbeautify

# Get exit code
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    echo "⚠️  Some tests may have failed (expected in record mode)"
fi

# Count snapshots
SNAPSHOT_COUNT=$(find HomeInventoryModularTests/ExpandedTests/__Snapshots__/#{test_name}/ -name "*.png" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "📊 Snapshot Summary:"
echo "Total snapshots: $SNAPSHOT_COUNT"
echo ""
echo "✅ Done!"
SCRIPT
  
  File.write(script_path, script_content)
  File.chmod(0755, script_path)
end

# Save project
project.save

puts "\n✅ Created #{total_files} expanded test files!"
puts "\nTest files created in: #{expanded_tests_dir}"
puts "Test runners created in: #{test_runners_dir}"
puts "\nTo run tests:"
puts "  RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[group].sh"
puts "\nNew test groups:"
expanded_tests.keys.each do |test|
  script_name = test.gsub(/([A-Z])/, '-\\1').downcase.gsub(/^-/, '').gsub('snapshottests', '').gsub('--', '-')
  puts "  - #{test} (./scripts/test-runners/test-#{script_name}.sh)"
end