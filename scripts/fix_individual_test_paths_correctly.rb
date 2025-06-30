#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing individual test file paths correctly..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Find test group
test_group = project.main_group['HomeInventoryModularTests']

# Find IndividualTests group
individual_group = test_group['IndividualTests']
unless individual_group
  puts "❌ IndividualTests group not found!"
  exit 1
end

# Test files
test_files = ['ItemsSnapshotTests.swift', 'BarcodeScannerSnapshotTests.swift', 
              'ReceiptsSnapshotTests.swift', 'AppSettingsSnapshotTests.swift',
              'PremiumSnapshotTests.swift', 'OnboardingSnapshotTests.swift']

# First, remove all existing references from build phase
files_to_remove = []
test_target.source_build_phase.files.each do |file|
  if file.file_ref && test_files.include?(File.basename(file.file_ref.path))
    files_to_remove << file
  end
end

files_to_remove.each do |file|
  test_target.source_build_phase.files.delete(file)
  puts "  ✗ Removed from build phase: #{File.basename(file.file_ref.path)}"
end

# Fix the file references in the IndividualTests group
individual_group.children.select { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) }.each do |ref|
  if test_files.include?(ref.path)
    # Set the correct source tree and path
    ref.source_tree = '<group>'
    ref.path = ref.path  # Keep just the filename
    ref.set_path("IndividualTests/#{ref.path}")  # Set the full path
    puts "  ✓ Fixed path for #{ref.path}"
    
    # Add back to build phase
    test_target.source_build_phase.add_file_reference(ref)
    puts "  ✓ Re-added to build phase: #{ref.path}"
  end
end

# Save project
project.save

puts "\n✅ Fixed all test file paths correctly!"
puts "\nNow you can run: ./scripts/test-runners/test-items.sh"