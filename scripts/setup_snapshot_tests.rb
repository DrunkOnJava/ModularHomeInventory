#!/usr/bin/env ruby

require 'xcodeproj'
require 'json'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find or create the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

if test_target.nil?
  puts "❌ Test target not found. Creating it..."
  
  # Find the main app target
  app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
  
  # Create unit test target
  test_target = project.new_target(:unit_test_bundle, 'HomeInventoryModularTests', :ios, '17.0')
  
  # Configure test target
  test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.modular.tests'
    config.build_settings['DEVELOPMENT_TEAM'] = '2VXBQV4XC9'
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['TEST_HOST'] = "$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular"
    config.build_settings['BUNDLE_LOADER'] = "$(TEST_HOST)"
    config.build_settings['SWIFT_VERSION'] = '5.9'
  end
  
  # Add dependency on main app
  test_target.add_dependency(app_target)
end

# Find the test files group
test_group = project.main_group['HomeInventoryModularTests']
if test_group.nil?
  test_group = project.main_group.new_group('HomeInventoryModularTests')
end

# Add all test files to the target
test_files = Dir.glob('HomeInventoryModularTests/**/*.swift')
test_files.each do |file_path|
  # Skip if already in target
  file_ref = test_group.find_file_by_path(file_path)
  
  if file_ref.nil?
    # Create subgroups as needed
    path_components = File.dirname(file_path).split('/')
    current_group = project.main_group
    
    path_components.each do |component|
      next_group = current_group[component]
      if next_group.nil?
        next_group = current_group.new_group(component)
      end
      current_group = next_group
    end
    
    # Add file reference
    file_ref = current_group.new_file(file_path)
  end
  
  # Add to build phase if not already there
  unless test_target.source_build_phase.files_references.include?(file_ref)
    test_target.source_build_phase.add_file_reference(file_ref)
  end
end

# Create or update the scheme
scheme_path = Xcodeproj::XCScheme.shared_data_dir(project_path) + "HomeInventoryModularTests.xcscheme"
scheme = Xcodeproj::XCScheme.new

# Configure build action
build_action = scheme.build_action
build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(test_target))

# Configure test action
test_action = scheme.test_action
test_action.build_configuration = 'Debug'

testables = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
testables.skipped = false
test_action.add_testable(testables)

# Save scheme
scheme.save_as(project_path, 'HomeInventoryModularTests')

# Save project
project.save

puts "✅ Test target configured successfully!"
puts ""
puts "📋 Next steps:"
puts "1. Run tests: make test-snapshots"
puts "2. Record snapshots: make record-snapshots"