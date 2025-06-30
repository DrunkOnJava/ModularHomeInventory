#!/usr/bin/env ruby

# Read the project file
project_file = 'HomeInventoryModular.xcodeproj/project.pbxproj'
content = File.read(project_file)

# Files to remove
files_to_remove = [
  'AccessibilitySnapshotTests.swift',
  'AddItemViewSnapshotTests.swift',
  'ItemCardSnapshotTests.swift',
  'ItemDetailViewSnapshotTests.swift',
  'ItemsListViewSnapshotTests.swift',
  'ReceiptsViewSnapshotTests.swift',
  'SnapshotTestingConfiguration.swift'
]

# Create backup
File.write("#{project_file}.backup2", content)
puts "Created backup at #{project_file}.backup2"

# Remove each file's references
files_to_remove.each do |file|
  # Find all lines containing the file
  matches = content.scan(/.*#{Regexp.escape(file)}.*/)
  
  if matches.any?
    puts "\nRemoving references to #{file}:"
    matches.each { |m| puts "  #{m.strip}" }
    
    # Remove the lines
    content.gsub!(/.*#{Regexp.escape(file)}.*\n/, '')
  end
end

# Write the modified content back
File.write(project_file, content)
puts "\nProject file updated successfully"