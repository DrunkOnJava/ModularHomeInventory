#!/usr/bin/env ruby

require 'xcodeproj'

# Open the Xcode project
project_path = './HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |target| target.name == 'HomeInventoryModularTests' }

if test_target.nil?
  puts "Error: Could not find test target 'HomeInventoryModularTests'"
  exit 1
end

# Define the new test files to add
test_files = [
  'AdvancedUIStatesTests.swift',
  'EdgeCaseScenarioTests.swift',
  'AccessibilityVariationsTests.swift',
  'ResponsiveLayoutTests.swift'
]

added_count = 0

test_files.each do |file_name|
  file_path = "HomeInventoryModularTests/ExpandedTests/#{file_name}"
  
  # Check if file reference already exists
  existing = project.files.find { |file| file.path == file_path }
  
  unless existing
    # Add the file reference to the project
    file_ref = project.main_group.new_reference(file_path)
    
    # Add the file to the test target
    test_target.add_file_references([file_ref])
    
    added_count += 1
    puts "Added #{file_name}"
  else
    puts "#{file_name} already exists in project"
  end
end

if added_count > 0
  # Save the project
  project.save
  puts "\nSuccessfully added #{added_count} test file#{added_count == 1 ? '' : 's'} to the Xcode project!"
else
  puts "\nNo new files were added - all files already exist in the project."
end