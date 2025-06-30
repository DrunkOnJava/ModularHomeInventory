#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

# Helper method - define before use
def createModuleContent(module_name, config)
  case module_name
  when 'Items'
    <<-CONTENT
VStack(spacing: 16) {
                // Sample item card
                HStack {
                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("MacBook Pro")
                            .font(.headline)
                        Text("Electronics • $2,499")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Another item
                HStack {
                    Image(systemName: "tv")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Smart TV")
                            .font(.headline)
                        Text("Electronics • $899")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
CONTENT
  when 'BarcodeScanner'
    <<-CONTENT
VStack {
                // Scanner preview area
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, lineWidth: 3)
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)
                            Text("Aim at barcode")
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding()
                
                // Recent scans
                VStack(alignment: .leading) {
                    Text("Recent Scans")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(0..<2) { _ in
                        HStack {
                            Image(systemName: "barcode")
                                .foregroundColor(.orange)
                            Text("1234567890123")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("Just now")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
CONTENT
  when 'Receipts'
    <<-CONTENT
VStack(spacing: 16) {
                // Receipt card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text("Apple Store")
                            .font(.headline)
                        Spacer()
                        Text("$2,499.00")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Label("Oct 15, 2024", systemImage: "calendar")
                        Spacer()
                        Label("Electronics", systemImage: "tag")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "paperclip")
                        Text("IMG_1234.jpg")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
CONTENT
  when 'AppSettings'
    <<-CONTENT
VStack(spacing: 0) {
                // Settings sections
                ForEach(["General", "Privacy", "Notifications", "Data & Storage"], id: \\.self) { section in
                    HStack {
                        Image(systemName: section == "General" ? "gearshape" : 
                                         section == "Privacy" ? "lock" :
                                         section == "Notifications" ? "bell" : "externaldrive")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        Text(section)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    if section != "Data & Storage" {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
                .cornerRadius(12)
                .padding()
            }
CONTENT
  when 'Premium'
    <<-CONTENT
VStack(spacing: 20) {
                // Premium badge
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Unlock Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Unlimited items")
                    FeatureRow(icon: "icloud", text: "Cloud backup")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics")
                    FeatureRow(icon: "sparkles", text: "AI-powered insights")
                }
                .padding()
                
                // Price
                VStack(spacing: 8) {
                    Text("$4.99/month")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Start 7-day free trial")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
CONTENT
  when 'Onboarding'
    <<-CONTENT
VStack(spacing: 30) {
                // Welcome image
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.teal)
                
                Text("Welcome to\\nHome Inventory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Track and manage all your\\nvaluable possessions")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Page indicators
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.teal)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                // Action button
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            .padding()
CONTENT
  end
end

puts "🔧 Configuring individual snapshot tests..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Get test group
test_group = project.main_group['HomeInventoryModularTests']

# Create individual test files for each module
modules = {
  'Items' => {
    icon: 'house.fill',
    color: 'blue',
    components: ['ItemsList', 'ItemDetail', 'AddItem']
  },
  'BarcodeScanner' => {
    icon: 'qrcode.viewfinder',
    color: 'orange',
    components: ['Scanner', 'History', 'BatchScan']
  },
  'Receipts' => {
    icon: 'doc.text',
    color: 'green',
    components: ['ReceiptsList', 'ReceiptDetail', 'ReceiptScanner']
  },
  'AppSettings' => {
    icon: 'gearshape',
    color: 'gray',
    components: ['GeneralSettings', 'PrivacySettings', 'DataSettings']
  },
  'Premium' => {
    icon: 'star.fill',
    color: 'purple',
    components: ['UpgradeView', 'Features', 'Subscription']
  },
  'Onboarding' => {
    icon: 'info.circle',
    color: 'teal',
    components: ['Welcome', 'Permissions', 'Setup']
  }
}

# Create a directory for individual tests
individual_tests_dir = 'HomeInventoryModularTests/IndividualTests'
FileUtils.mkdir_p(individual_tests_dir)

# Create test files for each module
modules.each do |module_name, config|
  test_content = <<-SWIFT
import XCTest
import SnapshotTesting
import SwiftUI

final class #{module_name}SnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func test#{module_name}MainView() {
        let view = create#{module_name}View()
        let hostingController = UIHostingController(rootView: view)
        
        // Take snapshots for different devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func test#{module_name}DarkMode() {
        let view = create#{module_name}View()
            .environment(\\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{module_name}Components() {
        // Test individual components
#{config[:components].map { |component| 
        "        let #{component.downcase}View = create#{component}View()
        assertSnapshot(
            of: UIHostingController(rootView: #{component.downcase}View), 
            as: .image(on: .iPhone13),
            named: \"#{component}\"
        )"
}.join("\n\n")}
    }
    
    // MARK: - View Creation Helpers
    
    private func create#{module_name}View() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "#{config[:icon]}")
                    .font(.largeTitle)
                    .foregroundColor(.#{config[:color]})
                Text("#{module_name}")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Module-specific content
            #{createModuleContent(module_name, config)}
            
            Spacer()
        }
        .frame(width: 390, height: 844)
        .background(Color(.systemBackground))
    }
    
#{config[:components].map { |component| 
    "    private func create#{component}View() -> some View {
        // Mock #{component} view
        VStack {
            Text(\"#{component}\")
                .font(.title2)
                .padding()
            
            // Add component-specific UI here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text(\"#{component} Content\")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
        .frame(width: 390, height: 400)
        .background(Color(.systemBackground))
    }"
}.join("\n\n")}
}
SWIFT

  # Write test file
  file_path = "#{individual_tests_dir}/#{module_name}SnapshotTests.swift"
  File.write(file_path, test_content)
  
  # Add to project if not already present
  relative_path = "IndividualTests/#{module_name}SnapshotTests.swift"
  unless test_group.children.any? { |f| f.path&.include?("#{module_name}SnapshotTests.swift") }
    # Create IndividualTests group if needed
    individual_group = test_group['IndividualTests'] || test_group.new_group('IndividualTests')
    
    file_ref = individual_group.new_reference("#{module_name}SnapshotTests.swift")
    test_target.add_file_references([file_ref])
    puts "✅ Added #{module_name}SnapshotTests.swift"
  end
end

# Save project
project.save

puts "\n✅ Created individual test files for all modules!"

# Create run scripts for each module
puts "\n📝 Creating individual test runners..."

# Create runners directory
FileUtils.mkdir_p('scripts/test-runners')

# Create a runner for each module
modules.keys.each do |module_name|
  runner_content = <<-BASH
#!/bin/bash

echo "📸 Running #{module_name} Snapshot Tests"
echo "===================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/#{module_name}
mkdir -p TestResults/#{module_name}

# Run the specific test
xcodebuild test \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -only-testing:HomeInventoryModularTests/#{module_name}SnapshotTests \\
  -resultBundlePath TestResults/#{module_name}/#{module_name}.xcresult \\
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \\
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*#{module_name}SnapshotTests*" | wc -l | xargs echo "Total snapshots for #{module_name}:"

# List snapshot files
echo ""
echo "📁 Generated files:"
find HomeInventoryModularTests -name "*.png" -path "*#{module_name}SnapshotTests*" -exec basename {} \\; | sort | uniq

echo ""
echo "✅ Done!"
echo ""
echo "💡 Tips:"
echo "   - To record new snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-#{module_name.downcase}.sh"
echo "   - To view results: open TestResults/#{module_name}/#{module_name}.xcresult"
echo "   - Snapshots location: HomeInventoryModularTests/__Snapshots__/#{module_name}SnapshotTests/"
BASH

  runner_path = "scripts/test-runners/test-#{module_name.downcase}.sh"
  File.write(runner_path, runner_content)
  FileUtils.chmod(0755, runner_path)
  puts "✅ Created #{runner_path}"
end

# Create a master runner
master_runner = <<-BASH
#!/bin/bash

echo "🎯 Home Inventory Snapshot Test Runner"
echo "======================================"
echo ""
echo "Select which tests to run:"
echo "1) All modules"
echo "2) Items"
echo "3) BarcodeScanner"
echo "4) Receipts"
echo "5) AppSettings"
echo "6) Premium"
echo "7) Onboarding"
echo "8) Run with recording ON (generate new snapshots)"
echo ""
read -p "Enter your choice (1-8): " choice

case $choice in
  1)
    echo "Running all module tests..."
    for script in scripts/test-runners/test-*.sh; do
      if [[ -f "$script" && "$script" != *"test-all.sh" ]]; then
        echo ""
        echo "---"
        $script
      fi
    done
    ;;
  2) ./scripts/test-runners/test-items.sh ;;
  3) ./scripts/test-runners/test-barcodescanner.sh ;;
  4) ./scripts/test-runners/test-receipts.sh ;;
  5) ./scripts/test-runners/test-appsettings.sh ;;
  6) ./scripts/test-runners/test-premium.sh ;;
  7) ./scripts/test-runners/test-onboarding.sh ;;
  8)
    echo "Which module to record? (2-7 or 1 for all): "
    read -p "Enter choice: " record_choice
    export RECORD_SNAPSHOTS=YES
    case $record_choice in
      1) $0 && choice=1 ;;  # Recursively call with choice 1
      2) ./scripts/test-runners/test-items.sh ;;
      3) ./scripts/test-runners/test-barcodescanner.sh ;;
      4) ./scripts/test-runners/test-receipts.sh ;;
      5) ./scripts/test-runners/test-appsettings.sh ;;
      6) ./scripts/test-runners/test-premium.sh ;;
      7) ./scripts/test-runners/test-onboarding.sh ;;
    esac
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac
BASH

File.write('scripts/run-snapshot-tests.sh', master_runner)
FileUtils.chmod(0755, 'scripts/run-snapshot-tests.sh')

puts "\n✅ Created master test runner!"
puts "\n📋 Usage:"
puts "   - Run all tests: ./scripts/run-snapshot-tests.sh"
puts "   - Run specific module: ./scripts/test-runners/test-[module].sh"
puts "   - Record new snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[module].sh"

# Create the FeatureRow view helper
feature_row_helper = <<-SWIFT

// Helper view for Premium features
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(text)
            Spacer()
        }
    }
}
SWIFT

# Append to Premium test file
premium_test_path = "#{individual_tests_dir}/PremiumSnapshotTests.swift"
if File.exist?(premium_test_path)
  content = File.read(premium_test_path)
  File.write(premium_test_path, content + feature_row_helper)
end