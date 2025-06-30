#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing test file references..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Clear all source files from build phase
test_target.source_build_phase.files_references.clear
puts "🧹 Cleared existing file references"

# Find or create test group
main_group = project.main_group
test_group = main_group['HomeInventoryModularTests']

# Remove any duplicate test groups
project.main_group.children.select { |g| g.name == 'HomeInventoryModularTests' && g != test_group }.each do |dup|
  dup.remove_from_project
end

# Clean up the test group - remove all existing references
if test_group
  test_group.clear
else
  test_group = main_group.new_group('HomeInventoryModularTests')
end

# Re-add all test files with correct paths
test_files_added = 0
Dir.glob('HomeInventoryModularTests/**/*.swift').sort.each do |file_path|
  next if file_path.include?('__Snapshots__')
  
  path_components = file_path.split('/')
  current_group = test_group
  
  # Create group structure
  path_components[1..-2].each do |component|
    existing = current_group.children.find { |g| g.name == component && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
    current_group = existing || current_group.new_group(component)
  end
  
  # Add file reference
  filename = path_components.last
  # Remove any existing file with same name
  current_group.children.select { |f| f.name == filename && f.is_a?(Xcodeproj::Project::Object::PBXFileReference) }.each(&:remove_from_project)
  
  file_ref = current_group.new_reference(filename)
  test_target.add_file_references([file_ref])
  
  test_files_added += 1
  puts "  ✓ Added: #{file_path}"
end

# Add Info.plist if it exists
if File.exist?('HomeInventoryModularTests/Info.plist')
  info_ref = test_group.new_reference('Info.plist')
  puts "  ✓ Added: HomeInventoryModularTests/Info.plist"
end

# Update test target settings
test_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = ''
  config.build_settings['GCC_PREFIX_HEADER'] = ''
end

# Save project
project.save

puts ""
puts "✅ Fixed test file references!"
puts "   Total test files: #{test_files_added}"