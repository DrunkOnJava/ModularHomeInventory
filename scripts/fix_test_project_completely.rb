#!/usr/bin/env ruby

require 'xcodeproj'

project_path = './HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless test_target
  puts "Error: Test target not found"
  exit 1
end

puts "Found test target: #{test_target.name}"

# Clear all source files from the test target's build phase
puts "Clearing all existing source files from test target..."
test_target.source_build_phase.files_references.clear

# Remove all test file references from the project
puts "Removing all test file references from project..."
test_files_to_remove = []
project.files.each do |file_ref|
  if file_ref.real_path.to_s.include?('HomeInventoryModularTests')
    test_files_to_remove << file_ref
  end
end

test_files_to_remove.each do |file_ref|
  file_ref.remove_from_project
end

puts "Removed #{test_files_to_remove.count} test file references"

# Find or create the test group
test_group = project.main_group['HomeInventoryModularTests']
if test_group
  test_group.clear
else
  test_group = project.main_group.new_group('HomeInventoryModularTests')
end

# Get all test files from the file system
test_files = Dir.glob("HomeInventoryModularTests/**/*.swift").sort

puts "Found #{test_files.count} test files in file system"

# Group test files by directory
test_files_by_dir = {}
test_files.each do |file_path|
  dir_components = File.dirname(file_path).split('/')
  dir_components.shift # Remove 'HomeInventoryModularTests'
  
  if dir_components.empty?
    test_files_by_dir[''] ||= []
    test_files_by_dir[''] << file_path
  else
    dir_path = dir_components.join('/')
    test_files_by_dir[dir_path] ||= []
    test_files_by_dir[dir_path] << file_path
  end
end

# Add test files with correct structure
added_count = 0
test_files_by_dir.each do |dir, files|
  # Create subgroup for each directory
  if dir && !dir.empty?
    current_group = test_group
    dir.split('/').each do |component|
      current_group = current_group[component] || current_group.new_group(component)
    end
  else
    current_group = test_group
  end
  
  files.each do |file_path|
    # Add file reference with correct path
    file_ref = current_group.new_reference(file_path)
    
    # Add to test target's source build phase
    test_target.source_build_phase.add_file_reference(file_ref)
    
    puts "Added: #{file_path}"
    added_count += 1
  end
end

puts "\nAdded #{added_count} test files to project"

# Add Info.plist if missing
info_plist_path = 'HomeInventoryModularTests/Info.plist'
if File.exist?(info_plist_path)
  unless test_group.find_file_by_path(info_plist_path)
    test_group.new_reference(info_plist_path)
    puts "Added Info.plist"
  end
end

# Save the project
project.save
puts "\nProject saved successfully!"