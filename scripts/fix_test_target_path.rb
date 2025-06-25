#!/usr/bin/env ruby

require 'xcodeproj'

# Fix the file path issue in the test target
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing test target file paths..."

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Could not find HomeInventoryModularTests target"
  exit 1
end

# Find and fix the file reference
test_group = project.main_group.find_subpath('HomeInventoryModularTests', false)
if test_group
  # Remove existing file references
  test_group.files.each do |file|
    if file.name == 'ViewScreenshotTests.swift'
      puts "  Removing old reference: #{file.path}"
      file.remove_from_project
    end
  end
  
  # Add correct file reference
  correct_path = 'HomeInventoryModularTests/ViewScreenshotTests.swift'
  if File.exist?(correct_path)
    file_ref = test_group.new_file(correct_path)
    file_ref.name = 'ViewScreenshotTests.swift'
    file_ref.path = 'ViewScreenshotTests.swift'
    file_ref.source_tree = '<group>'
    
    # Add to target
    test_target.add_file_references([file_ref])
    puts "  ✅ Added correct reference: #{correct_path}"
  else
    puts "  ❌ File not found at: #{correct_path}"
  end
end

# Save the project
project.save
puts "✅ Fixed test target file paths!"