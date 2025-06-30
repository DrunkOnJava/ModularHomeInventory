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

# Get all test files from the file system
test_files = Dir.glob("HomeInventoryModularTests/**/*.swift")
puts "Found #{test_files.count} test files in file system"

# Remove all existing test file references from the project
removed_count = 0
project.main_group.recursive_children.each do |file_ref|
  next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)
  next unless file_ref.path&.end_with?('.swift')
  
  # Check if this is a test file with incorrect path
  if file_ref.real_path.to_s.include?('HomeInventoryModularTests/HomeInventoryModularTests') ||
     file_ref.path.include?('HomeInventoryModularTests/HomeInventoryModularTests')
    puts "Removing incorrect reference: #{file_ref.path}"
    file_ref.remove_from_project
    removed_count += 1
  end
end

puts "Removed #{removed_count} incorrect references"

# Find or create test group
test_group = project.main_group.find_subpath('HomeInventoryModularTests', true)

# Group test files by directory
test_files_by_dir = test_files.group_by { |f| File.dirname(f).split('HomeInventoryModularTests/').last }

# Add test files with correct structure
added_count = 0
test_files_by_dir.each do |dir, files|
  # Create subgroup for each directory
  if dir && dir != '.'
    subgroup = test_group.find_subpath(dir, true)
  else
    subgroup = test_group
  end
  
  files.each do |file_path|
    # Check if file already exists in project
    file_name = File.basename(file_path)
    existing_ref = project.files.find { |f| f.path == file_path }
    
    unless existing_ref
      # Add file reference
      file_ref = subgroup.new_reference(file_path)
      
      # Add to test target's source build phase
      test_target.source_build_phase.add_file_reference(file_ref)
      
      puts "Added: #{file_path}"
      added_count += 1
    end
  end
end

puts "Added #{added_count} test files"

# Clean up any duplicate build files
build_files = test_target.source_build_phase.files
unique_files = {}
duplicates_removed = 0

build_files.each do |bf|
  if bf.file_ref
    key = bf.file_ref.real_path.to_s
    if unique_files[key]
      bf.remove_from_project
      duplicates_removed += 1
    else
      unique_files[key] = bf
    end
  end
end

puts "Removed #{duplicates_removed} duplicate build files"

# Save the project
project.save
puts "Project saved successfully"