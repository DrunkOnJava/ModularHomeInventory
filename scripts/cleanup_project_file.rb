#!/usr/bin/env ruby

require 'xcodeproj'

# Files to remove from the project
files_to_remove = [
  'AccessibilitySnapshotTests.swift',
  'AddItemViewSnapshotTests.swift',
  'ItemCardSnapshotTests.swift',
  'ItemDetailViewSnapshotTests.swift',
  'ItemsListViewSnapshotTests.swift',
  'ReceiptsViewSnapshotTests.swift',
  'SnapshotTestingConfiguration.swift'
]

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Track removed files
removed_files = []

# Find and remove file references
project.files.each do |file|
  if files_to_remove.include?(file.name)
    puts "Removing reference to: #{file.path}"
    file.remove_from_project
    removed_files << file.name
  end
end

# Save the project
if removed_files.any?
  project.save
  puts "\nSuccessfully removed #{removed_files.count} file references from the project"
  puts "Removed files:"
  removed_files.each { |f| puts "  - #{f}" }
else
  puts "No matching files found to remove"
end