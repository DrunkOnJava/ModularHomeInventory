#!/usr/bin/env ruby

require 'xcodeproj'
require 'set'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🧹 Cleaning test target file references..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

puts "📋 Current file count: #{test_target.source_build_phase.files.count}"

# Clear all file references from build phase
test_target.source_build_phase.files_references.clear
puts "✓ Cleared all file references from build phase"

# Remove test group and recreate
main_group = project.main_group
old_test_group = main_group['HomeInventoryModularTests']
if old_test_group
  old_test_group.clear
  old_test_group.remove_from_project
  puts "✓ Removed old test group"
end

# Create new test group
test_group = main_group.new_group('HomeInventoryModularTests')
puts "✓ Created new test group"

# Find and add only valid test files
test_files_added = 0
test_files_by_name = {}

# Collect all test files and deduplicate by name
Dir.glob('HomeInventoryModularTests/**/*.swift').each do |file_path|
  next if file_path.include?('__Snapshots__')
  
  file_name = File.basename(file_path)
  
  # Keep only one instance of each file (prefer the one in subdirectories)
  if !test_files_by_name[file_name] || file_path.include?('/')
    test_files_by_name[file_name] = file_path
  end
end

# Add unique files
test_files_by_name.each do |file_name, file_path|
  # Get path components relative to HomeInventoryModularTests
  relative_path = file_path.sub('HomeInventoryModularTests/', '')
  components = relative_path.split('/')
  
  # Create group hierarchy
  current_group = test_group
  if components.length > 1
    components[0..-2].each do |component|
      existing = current_group.children.find { |g| 
        g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == component 
      }
      current_group = existing || current_group.new_group(component)
    end
  end
  
  # Add file reference
  file_ref = current_group.new_reference(components.last)
  file_ref.set_path(file_path)
  test_target.add_file_references([file_ref])
  test_files_added += 1
  
  puts "  ✓ Added: #{relative_path}"
end

# Add Info.plist if it exists
info_path = 'HomeInventoryModularTests/Info.plist'
if File.exist?(info_path)
  info_ref = test_group.new_reference('Info.plist')
  info_ref.set_path(info_path)
  puts "  ✓ Added Info.plist"
end

# Save project
project.save

puts "\n✅ Cleanup complete!"
puts "   Files added: #{test_files_added}"
puts "\n📝 Test files structure:"

# Show structure
test_files_by_name.keys.group_by { |name|
  if name.include?('Snapshot')
    if name.include?('Simple') || name.include?('Minimal') || name.include?('Working')
      'Simple Tests'
    else
      'Module Snapshot Tests'
    end
  else
    'Other Tests'
  end
}.each do |category, files|
  puts "\n#{category}:"
  files.sort.each { |f| puts "  - #{f}" }
end