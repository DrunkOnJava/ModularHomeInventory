#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project = Xcodeproj::Project.open('HomeInventoryModular.xcodeproj')

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
if test_target.nil?
  puts "Could not find HomeInventoryModularTests target"
  exit 1
end

# Find the test group
test_group = project.groups.find { |g| g.name == 'HomeInventoryModularTests' }
if test_group.nil?
  puts "Could not find HomeInventoryModularTests group"
  exit 1
end

# Add the new file
file_path = 'HomeInventoryModularTests/SimpleComponentSnapshotTests.swift'
file_ref = test_group.new_file(file_path)

# Add to build phase
test_target.source_build_phase.add_file_reference(file_ref)

# Save
project.save
puts "Successfully added SimpleComponentSnapshotTests.swift to the project"