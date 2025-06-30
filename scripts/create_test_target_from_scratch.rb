#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Creating/fixing test target from scratch..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find existing test target
existing_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

if existing_test_target
  puts "⚠️  Removing existing test target..."
  project.targets.delete(existing_test_target)
end

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }

if app_target.nil?
  puts "❌ App target not found!"
  exit 1
end

puts "✅ Found app target: #{app_target.name}"

# Create new test target
test_target = project.new_target(:unit_test_bundle, 'HomeInventoryModularTests', :ios, '17.0')
test_target.add_dependency(app_target)

puts "✅ Created new test target"

# Configure build settings
test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['DEBUG=1', '$(inherited)']
  config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -D RECORD_SNAPSHOTS'
end

puts "✅ Configured build settings"

# Create test group if needed
main_group = project.main_group
test_group = main_group['HomeInventoryModularTests'] || main_group.new_group('HomeInventoryModularTests')
test_group.set_source_tree('<group>')

# Add all test files
test_files_added = 0
Dir.glob('HomeInventoryModularTests/**/*.swift').each do |file_path|
  path_components = file_path.split('/')
  current_group = test_group
  
  # Create group structure
  path_components[1..-2].each do |component|
    current_group = current_group[component] || current_group.new_group(component)
    current_group.set_source_tree('<group>')
  end
  
  # Add file
  file_ref = current_group.new_reference(path_components.last)
  file_ref.set_source_tree('<group>')
  test_target.add_file_references([file_ref])
  
  test_files_added += 1
end

puts "✅ Added #{test_files_added} test files"

# Add to scheme
scheme_path = Xcodeproj::XCScheme.shared_data_dir(PROJECT_PATH) + 'HomeInventoryModular.xcscheme'
scheme = Xcodeproj::XCScheme.new(scheme_path)

# Add test action
test_action = scheme.test_action
test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target))

scheme.save!

puts "✅ Updated scheme"

# Create Info.plist if it doesn't exist
info_plist_path = 'HomeInventoryModularTests/Info.plist'
unless File.exist?(info_plist_path)
  info_plist_content = <<-XML
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
  
  File.write(info_plist_path, info_plist_content)
  puts "✅ Created Info.plist"
end

# Save the project
project.save

puts "✅ Project saved successfully!"
puts ""
puts "📋 Summary:"
puts "   - Test target created: HomeInventoryModularTests"
puts "   - Test files added: #{test_files_added}"
puts "   - Build settings configured: ✓"
puts "   - Scheme updated: ✓"
puts ""
puts "🚀 Test target is now properly configured!"