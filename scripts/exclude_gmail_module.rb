#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }

if app_target
  # Find and remove Gmail dependency
  gmail_dep = app_target.dependencies.find { |d| d.name == 'Gmail' }
  if gmail_dep
    app_target.dependencies.delete(gmail_dep)
    puts "✅ Removed Gmail dependency from main target"
  end
  
  # Remove Gmail from frameworks build phase
  frameworks_phase = app_target.frameworks_build_phase
  gmail_file = frameworks_phase.files.find { |f| f.display_name == 'Gmail' }
  if gmail_file
    frameworks_phase.remove_file_reference(gmail_file)
    puts "✅ Removed Gmail from frameworks"
  end
  
  # Save project
  project.save
  puts "✅ Project updated successfully"
else
  puts "❌ Could not find main app target"
end