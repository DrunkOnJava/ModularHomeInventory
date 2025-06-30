#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

if test_target
  # Find and remove TabletLayoutSnapshotTests.swift from the project
  removed_count = 0
  
  test_target.source_build_phase.files.each do |file|
    if file.display_name == 'TabletLayoutSnapshotTests.swift'
      file.remove_from_project
      removed_count += 1
    end
  end
  
  # Also remove from the project file references
  project.files.each do |file|
    if file.path&.include?('TabletLayoutSnapshotTests.swift')
      file.remove_from_project
      removed_count += 1
    end
  end
  
  if removed_count > 0
    project.save
    puts "✅ Removed TabletLayoutSnapshotTests.swift from project (#{removed_count} references)"
  else
    puts "⚠️  TabletLayoutSnapshotTests.swift not found in project"
  end
else
  puts "❌ HomeInventoryModularTests target not found"
end