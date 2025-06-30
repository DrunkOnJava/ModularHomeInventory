#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing test target configuration..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

if test_target.nil?
  puts "❌ Test target not found!"
  exit 1
end

puts "✅ Found test target: #{test_target.name}"

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }

if app_target.nil?
  puts "❌ App target not found!"
  exit 1
end

# Set up test target dependencies
unless test_target.dependencies.any? { |d| d.target == app_target }
  test_target.add_dependency(app_target)
  puts "✅ Added app target dependency"
end

# Ensure test target has proper build phases
unless test_target.source_build_phase
  test_target.new_shell_script_build_phase
  puts "✅ Added source build phase"
end

# Find or create the test group
main_group = project.main_group
test_group = main_group['HomeInventoryModularTests'] || main_group.new_group('HomeInventoryModularTests')

# Clear existing file references from build phase
test_target.source_build_phase.files_references.clear
puts "🧹 Cleared existing file references"

# Add all test files
test_files_added = 0
Dir.glob('HomeInventoryModularTests/**/*.swift').each do |file_path|
  # Skip if file already exists in project
  existing_ref = project.files.find { |f| f.real_path.to_s == File.expand_path(file_path) }
  
  if existing_ref
    # Just add to build phase
    test_target.source_build_phase.add_file_reference(existing_ref)
  else
    # Create proper group structure
    path_components = file_path.split('/')
    current_group = test_group
    
    # Navigate/create group structure
    path_components[1..-2].each do |component|
      current_group = current_group[component] || current_group.new_group(component)
    end
    
    # Add file
    file_ref = current_group.new_reference(path_components.last)
    test_target.source_build_phase.add_file_reference(file_ref)
  end
  
  test_files_added += 1
end

puts "✅ Added #{test_files_added} test files to build phase"

# Add framework dependencies
frameworks_group = project.frameworks_group
snapshot_framework = frameworks_group.files.find { |f| f.path&.include?('SnapshotTesting') }

if snapshot_framework
  unless test_target.frameworks_build_phase.files_references.include?(snapshot_framework)
    test_target.frameworks_build_phase.add_file_reference(snapshot_framework)
    puts "✅ Added SnapshotTesting framework"
  end
end

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
end

puts "✅ Updated build settings"

# Save the project
project.save

puts "✅ Project saved successfully!"
puts ""
puts "📋 Summary:"
puts "   - Test target: #{test_target.name}"
puts "   - Test files added: #{test_files_added}"
puts "   - Dependencies configured: ✓"
puts "   - Build settings updated: ✓"
puts ""
puts "🚀 Test target is now properly configured!"