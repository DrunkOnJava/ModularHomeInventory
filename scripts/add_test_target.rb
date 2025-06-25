#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "📱 Adding Unit Test Target to #{project_path}"
puts "=" * 50

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
unless app_target
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

# Check if test target already exists
existing_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
if existing_test_target
  puts "✅ Test target 'HomeInventoryModularTests' already exists"
  exit 0
end

# Create the unit test target
test_target = project.new_target(:unit_test_bundle, 'HomeInventoryModularTests', :ios, '17.0')

# Configure the test target
test_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = app_target.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
  
  # Add Swift concurrency suppression
  config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'minimal'
  config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
  config.build_settings['OTHER_SWIFT_FLAGS'] = '-suppress-warnings'
end

# Add dependency on the main app
test_target.add_dependency(app_target)

# Create test group if it doesn't exist
test_group = project.main_group.find_subpath('HomeInventoryModularTests', true)
test_group.set_source_tree('SOURCE_ROOT')
test_group.set_path('HomeInventoryModularTests')

# Add test files to the group
test_files = ['ViewScreenshotTests.swift', 'UITestHelpers.swift']
test_files.each do |file_name|
  file_path = "HomeInventoryModularTests/#{file_name}"
  if File.exist?(file_path)
    file_ref = test_group.new_file(file_path)
    test_target.add_file_references([file_ref])
    puts "  ✅ Added #{file_name} to test target"
  else
    puts "  ⚠️  #{file_name} not found at #{file_path}"
  end
end

# Add the test target to the main scheme
scheme_path = Xcodeproj::XCScheme.shared_data_dir(project_path) + 'HomeInventoryModular.xcscheme'
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  
  # Add test action
  test_action = scheme.test_action
  if test_action
    testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
    test_action.add_testable(testable) unless test_action.testables.any? { |t| t.buildable_references.any? { |r| r.target_name == 'HomeInventoryModularTests' } }
    scheme.save!
    puts "✅ Added test target to scheme"
  end
else
  puts "⚠️  Scheme file not found, skipping scheme update"
end

# Save the project
project.save
puts "\n✅ Successfully added HomeInventoryModularTests target!"
puts "🎯 The project now has a unit test target for component screenshots"

# Create Info.plist for the test target
info_plist_content = <<-PLIST
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
PLIST

File.write('HomeInventoryModularTests/Info.plist', info_plist_content)
puts "✅ Created Info.plist for test target"