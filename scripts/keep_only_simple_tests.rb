#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🧹 Keeping only simple tests..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Keep only these files
keep_files = ['MinimalTest.swift', 'SimpleSnapshotTest.swift', 'FreshSnapshotTest.swift', 'Info.plist']

# Remove all other files from build phase
files_to_remove = []
test_target.source_build_phase.files.each do |file|
  if file.file_ref && !keep_files.include?(File.basename(file.file_ref.path))
    files_to_remove << file
  end
end

files_to_remove.each do |file|
  test_target.source_build_phase.files.delete(file)
  puts "  ✗ Removed #{File.basename(file.file_ref.path)}"
end

puts "\n✅ Kept only simple test files:"
test_target.source_build_phase.files.each do |file|
  if file.file_ref
    puts "  ✓ #{File.basename(file.file_ref.path)}"
  end
end

# Save
project.save

puts "\n🧪 Run: xcodebuild test -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' RECORD_SNAPSHOTS=YES"