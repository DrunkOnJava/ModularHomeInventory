#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

# Files to remove from project
files_to_remove = [
  'EmptyStatesSnapshotTests.swift',
  'SuccessStatesSnapshotTests.swift',
  'FormValidationSnapshotTests.swift',
  'ModalsAndSheetsSnapshotTests.swift',
  'OnboardingFlowSnapshotTests.swift',
  'SettingsVariationsSnapshotTests.swift',
  'InteractionStatesSnapshotTests.swift',
  'DataVisualizationSnapshotTests.swift'
]

removed_count = 0

# Remove from build phase
test_target.source_build_phase.files.each do |file|
  if files_to_remove.include?(file.display_name)
    file.remove_from_project
    removed_count += 1
  end
end

# Remove from project file references
project.files.each do |file|
  if file.path && files_to_remove.any? { |name| file.path.include?(name) }
    file.remove_from_project
    removed_count += 1
  end
end

# Save project
project.save

puts "✅ Removed #{removed_count} file references from project"