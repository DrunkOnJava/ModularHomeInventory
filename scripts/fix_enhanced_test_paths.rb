#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing enhanced test file paths..."

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

# Enhanced test files
enhanced_files = [
  'ItemsDetailedSnapshotTests.swift',
  'SearchSnapshotTests.swift', 
  'DataManagementSnapshotTests.swift',
  'SecuritySnapshotTests.swift',
  'GmailIntegrationSnapshotTests.swift',
  'SyncSnapshotTests.swift'
]

# Remove files from build phase with wrong paths
files_to_remove = []
test_target.source_build_phase.files.each do |file|
  if file.file_ref && enhanced_files.include?(File.basename(file.file_ref.path))
    files_to_remove << file
  end
end

files_to_remove.each do |file|
  test_target.source_build_phase.files.delete(file)
  puts "  ✗ Removed incorrect reference: #{File.basename(file.file_ref.path)}"
end

# Find or create EnhancedTests group
enhanced_group = test_group['EnhancedTests']
unless enhanced_group
  puts "❌ EnhancedTests group not found!"
  exit 1
end

# Fix the file references in the EnhancedTests group
enhanced_group.children.select { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) }.each do |ref|
  if enhanced_files.include?(ref.path)
    # Set the correct source tree and path
    ref.source_tree = '<group>'
    ref.path = ref.path  # Keep just the filename
    ref.set_path("EnhancedTests/#{ref.path}")  # Set the full path
    puts "  ✓ Fixed path for #{ref.path}"
    
    # Add back to build phase
    test_target.source_build_phase.add_file_reference(ref)
    puts "  ✓ Re-added to build phase: #{ref.path}"
  end
end

# Save project
project.save

puts "\n✅ Fixed all enhanced test file paths!"
puts "\nNow you can run: ./scripts/test-runners/test-itemsdetailed.sh"