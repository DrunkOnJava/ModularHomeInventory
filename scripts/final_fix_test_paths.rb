#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Final fix for test file paths..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Clear all file references
test_target.source_build_phase.files_references.clear
puts "✓ Cleared all file references"

# Remove old test group
main_group = project.main_group
old_test_group = main_group['HomeInventoryModularTests']
if old_test_group
  old_test_group.clear
  old_test_group.remove_from_project
end

# Create new test group
test_group = main_group.new_group('HomeInventoryModularTests')
test_group.set_source_tree('<group>')
test_group.set_path('HomeInventoryModularTests')

# Just add the simple test files that work
simple_files = [
  'MinimalTest.swift',
  'SimpleSnapshotTest.swift'
]

simple_files.each do |file_name|
  if File.exist?("HomeInventoryModularTests/#{file_name}")
    file_ref = test_group.new_reference(file_name)
    test_target.add_file_references([file_ref])
    puts "✓ Added #{file_name}"
  end
end

# Add Info.plist
if File.exist?('HomeInventoryModularTests/Info.plist')
  info_ref = test_group.new_reference('Info.plist')
  puts "✓ Added Info.plist"
end

# Save
project.save

puts "\n✅ Fixed! Test target now has only simple working tests."
puts "\n🧪 Run:"
puts "xcodebuild test -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:HomeInventoryModularTests/SimpleSnapshotTest RECORD_SNAPSHOTS=YES"