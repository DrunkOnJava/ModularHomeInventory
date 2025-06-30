#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

# Test files to add
test_files = [
  'SuccessStatesTests.swift',
  'FormValidationTests.swift',
  'ModalsAndSheetsTests.swift',
  'OnboardingFlowTests.swift'
]

added_count = 0

test_files.each do |file_name|
  file_path = "HomeInventoryModularTests/ExpandedTests/#{file_name}"
  
  # Check if file already exists in project
  existing = project.files.find { |f| f.path&.include?(file_name) }
  
  unless existing
    file_ref = project.main_group.new_reference(file_path)
    test_target.add_file_references([file_ref])
    added_count += 1
    puts "Added #{file_name}"
  else
    puts "#{file_name} already exists in project"
  end
end

# Save project
project.save

puts "\n✅ Added #{added_count} test files to the project"