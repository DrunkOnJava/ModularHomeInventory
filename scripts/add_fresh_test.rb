#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target and group
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
test_group = project.main_group['HomeInventoryModularTests']

if test_target && test_group
  # Add FreshSnapshotTest.swift
  unless test_group.children.any? { |f| f.path == 'FreshSnapshotTest.swift' }
    file_ref = test_group.new_reference('FreshSnapshotTest.swift')
    test_target.add_file_references([file_ref])
    puts "✅ Added FreshSnapshotTest.swift"
  end
  
  # Save
  project.save
  
  puts "\n🧪 Run: xcodebuild test -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:HomeInventoryModularTests/FreshSnapshotTest RECORD_SNAPSHOTS=YES"
else
  puts "❌ Test target or group not found"
end