#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Rebuilding test target from scratch..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
unless app_target
  puts "❌ App target not found!"
  exit 1
end

# Remove old test target if exists
old_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
if old_test_target
  puts "🗑️  Removing old test target..."
  project.targets.delete(old_test_target)
end

# Create new test target
puts "✨ Creating new test target..."
test_target = project.new_target(:unit_test_bundle, 'HomeInventoryModularTests', :ios, '17.0')

# Add dependency to app target
test_target.add_dependency(app_target)
puts "  ✓ Added app dependency"

# Configure build settings
puts "⚙️  Configuring build settings..."
test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@loader_path/Frameworks'
  ]
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  
  if config.name == 'Debug'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  end
  
  puts "  ✓ Configured #{config.name}"
end

# Create test group
puts "📁 Creating test file structure..."
main_group = project.main_group
test_group = main_group.new_group('HomeInventoryModularTests')

# Add test files
test_files_count = 0
Dir.glob('HomeInventoryModularTests/**/*.swift').sort.each do |file_path|
  next if file_path.include?('__Snapshots__')
  
  # Get path components
  components = file_path.split('/')
  current_group = test_group
  
  # Create group hierarchy
  components[1..-2].each do |component|
    existing = current_group.children.find { |g| g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == component }
    current_group = existing || current_group.new_group(component)
  end
  
  # Add file
  file_ref = current_group.new_reference(components.last)
  test_target.add_file_references([file_ref])
  test_files_count += 1
end

puts "  ✓ Added #{test_files_count} test files"

# Add Info.plist
if File.exist?('HomeInventoryModularTests/Info.plist')
  info_ref = test_group.new_reference('Info.plist')
  puts "  ✓ Added Info.plist"
else
  # Create Info.plist
  FileUtils.mkdir_p('HomeInventoryModularTests')
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
  puts "  ✓ Created and added Info.plist"
end

# Add SnapshotTesting package dependency
puts "📦 Adding package dependencies..."
snapshot_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
snapshot_dep.product_name = 'SnapshotTesting'

# Find swift-snapshot-testing package
package_ref = project.root_object.package_references.find do |ref|
  ref.is_a?(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference) &&
  ref.attributes && ref.attributes['repositoryURL'] &&
  ref.attributes['repositoryURL'].include?('swift-snapshot-testing')
end

if package_ref
  snapshot_dep.package = package_ref
  test_target.package_product_dependencies << snapshot_dep
  puts "  ✓ Added SnapshotTesting dependency"
else
  puts "  ⚠️  SnapshotTesting package not found - add manually in Xcode"
end

# Update scheme
puts "📋 Updating scheme..."
scheme_path = Xcodeproj::XCScheme.shared_data_dir(PROJECT_PATH) + 'HomeInventoryModular.xcscheme'
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  
  # Add test target to test action
  test_action = scheme.test_action
  testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
  testable.skipped = false
  test_action.testables << testable
  
  # Add environment variable
  test_action.environment_variables ||= Xcodeproj::XCScheme::EnvironmentVariables.new
  test_action.environment_variables['RECORD_SNAPSHOTS'] = { value: 'YES', enabled: true }
  
  scheme.save!
  puts "  ✓ Updated scheme"
else
  puts "  ⚠️  Scheme not found - will need to configure in Xcode"
end

# Save project
project.save

puts "\n✅ Test target rebuilt successfully!"
puts "\n📋 Summary:"
puts "   Test files: #{test_files_count}"
puts "   Dependencies: SnapshotTesting"
puts "   Build settings: Configured"
puts "\n🚀 Ready to run tests!"

# Create test script
test_script = <<-BASH
#!/bin/bash
set -e

echo "🧹 Cleaning..."
xcodebuild clean -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -quiet

echo "🔨 Building..."
xcodebuild build-for-testing \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build succeeded!"

echo "🧪 Running tests..."
xcodebuild test-without-building \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \\
  RECORD_SNAPSHOTS=YES \\
  -quiet

echo "✅ Done!"
BASH

File.write('run_simple_test.sh', test_script)
FileUtils.chmod(0755, 'run_simple_test.sh')
puts "\n📝 Created run_simple_test.sh"
puts "   Run: ./run_simple_test.sh"