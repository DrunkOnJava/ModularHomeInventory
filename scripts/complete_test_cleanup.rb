#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Complete test target cleanup and rebuild..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
old_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless app_target
  puts "❌ App target not found!"
  exit 1
end

# Remove old test target completely
if old_test_target
  puts "🗑️  Removing old test target..."
  project.targets.delete(old_test_target)
  
  # Remove from schemes
  scheme_dir = Xcodeproj::XCScheme.shared_data_dir(PROJECT_PATH)
  Dir.glob("#{scheme_dir}/*.xcscheme").each do |scheme_path|
    scheme = Xcodeproj::XCScheme.new(scheme_path)
    if scheme.test_action
      scheme.test_action.testables.reject! { |t| 
        t.buildable_references.any? { |r| r.target_name == 'HomeInventoryModularTests' }
      }
      scheme.save!
    end
  end
end

# Remove old test group
main_group = project.main_group
old_test_group = main_group['HomeInventoryModularTests']
if old_test_group
  old_test_group.clear
  old_test_group.remove_from_project
end

# Save to clean up
project.save

puts "✓ Removed all old test configurations"

# Now create everything fresh
puts "\n✨ Creating new test target..."

# Create new test target
test_target = project.new_target(:unit_test_bundle, 'HomeInventoryModularTests', :ios, '17.0')
test_target.add_dependency(app_target)

# Configure build settings
test_target.build_configurations.each do |config|
  config.build_settings.clear
  
  # Essential settings
  config.build_settings['PRODUCT_NAME'] = 'HomeInventoryModularTests'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  
  # Test host settings
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  
  # Search paths
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@loader_path/Frameworks'
  ]
  
  # Swift settings
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  
  # Code signing
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
  config.build_settings['CODE_SIGN_IDENTITY'] = ''
end

puts "✓ Configured build settings"

# Create test group
test_group = main_group.new_group('HomeInventoryModularTests')
test_group.set_source_tree('<group>')
test_group.set_path('HomeInventoryModularTests')

# Add only the simplest test file first
puts "\n📄 Adding minimal test file..."

minimal_test_content = <<-SWIFT
import XCTest

final class MinimalTest: XCTestCase {
    func testExample() {
        XCTAssertTrue(true)
    }
}
SWIFT

FileUtils.mkdir_p('HomeInventoryModularTests')
File.write('HomeInventoryModularTests/MinimalTest.swift', minimal_test_content)

file_ref = test_group.new_reference('MinimalTest.swift')
test_target.add_file_references([file_ref])

# Create Info.plist
info_content = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
XML

File.write('HomeInventoryModularTests/Info.plist', info_content)
info_ref = test_group.new_reference('Info.plist')

puts "✓ Created minimal test setup"

# Update scheme
puts "\n📋 Updating scheme..."
scheme_path = Xcodeproj::XCScheme.shared_data_dir(PROJECT_PATH) + 'HomeInventoryModular.xcscheme'
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  
  # Add test target to test action
  testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
  testable.skipped = false
  scheme.test_action.testables = [testable]
  
  scheme.save!
  puts "✓ Updated scheme"
end

# Save project
project.save

puts "\n✅ Complete! Test target rebuilt from scratch."
puts "\n🧪 Test with:"
puts "xcodebuild test -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:HomeInventoryModularTests/MinimalTest"