#!/usr/bin/env ruby

# Read the project file
project_file = 'HomeInventoryModular.xcodeproj/project.pbxproj'
content = File.read(project_file)

# Files that were moved
moved_files = [
  'SnapshotTestCase.swift',
  'SimpleSnapshotTest.swift',
  'SettingsViewSnapshotTests.swift',
  'ScannerViewSnapshotTests.swift'
]

# Remove references to moved files
moved_files.each do |file|
  # Remove file references
  content.gsub!(/.*#{Regexp.escape(file)}.*\n/, '')
end

# Write back
File.write(project_file, content)
puts "Updated project file to remove references to moved test files"