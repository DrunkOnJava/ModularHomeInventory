#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

# Add SimpleEmptyStatesTests.swift to the project
file_path = 'HomeInventoryModularTests/ExpandedTests/SimpleEmptyStatesTests.swift'
file_ref = project.main_group.new_reference(file_path)
test_target.add_file_references([file_ref])

# Save project
project.save

puts "✅ Added SimpleEmptyStatesTests.swift to the project"