#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing individual test file paths..."

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

# Remove incorrect references
test_files = ['ItemsSnapshotTests.swift', 'BarcodeScannerSnapshotTests.swift', 
              'ReceiptsSnapshotTests.swift', 'AppSettingsSnapshotTests.swift',
              'PremiumSnapshotTests.swift', 'OnboardingSnapshotTests.swift']

# Remove files from build phase with wrong paths
files_to_remove = []
test_target.source_build_phase.files.each do |file|
  if file.file_ref && test_files.include?(File.basename(file.file_ref.path))
    files_to_remove << file
  end
end

files_to_remove.each do |file|
  test_target.source_build_phase.files.delete(file)
  puts "  ✗ Removed incorrect reference: #{File.basename(file.file_ref.path)}"
end

# Also remove the file references themselves
test_group.children.select do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXFileReference) && test_files.include?(child.path)
end.each do |ref|
  test_group.children.delete(ref)
  puts "  ✗ Removed file reference: #{ref.path}"
end

# Find or create IndividualTests group
individual_group = test_group['IndividualTests']
if individual_group
  # Also remove from IndividualTests group
  individual_group.children.select do |child|
    child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
  end.each do |ref|
    individual_group.children.delete(ref)
    puts "  ✗ Removed from IndividualTests: #{ref.path}"
  end
end

# Save project
project.save
puts "\n✅ Cleaned up incorrect references!"

# Now re-add with correct paths
puts "\n🔧 Re-adding with correct paths..."

# Find or create IndividualTests group
individual_group = test_group['IndividualTests'] || test_group.new_group('IndividualTests')

# Add files with correct paths
test_files.each do |filename|
  file_path = "IndividualTests/#{filename}"
  file_ref = individual_group.new_reference(filename)
  file_ref.path = filename
  file_ref.source_tree = '<group>'
  
  # Add to build phase
  test_target.add_file_references([file_ref])
  puts "  ✓ Added #{filename} with correct path"
end

# Save project
project.save

puts "\n✅ Fixed all test file paths!"
puts "\nNow you can run: ./scripts/test-runners/test-items.sh"