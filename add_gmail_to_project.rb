#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'HomeInventoryModular' }

unless target
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

# Find the Gmail module reference
gmail_ref = nil
project.main_group.children.each do |child|
  if child.name == 'Modules' && child.is_a?(Xcodeproj::Project::Object::PBXGroup)
    child.children.each do |module_child|
      if module_child.name == 'Gmail'
        gmail_ref = module_child
        break
      end
    end
  end
end

# If not found, create it
unless gmail_ref
  modules_group = project.main_group.children.find { |g| g.name == 'Modules' }
  unless modules_group
    modules_group = project.main_group.new_group('Modules')
  end
  
  # Add Gmail folder reference
  gmail_path = 'Modules/Gmail'
  gmail_ref = modules_group.new_reference(gmail_path)
  gmail_ref.name = 'Gmail'
end

# Check if Gmail is already in the dependencies
has_gmail = false
target.dependencies.each do |dep|
  if dep.display_name == 'Gmail'
    has_gmail = true
    break
  end
end

unless has_gmail
  # We need to add Gmail as a Swift Package dependency
  # This is done through build phases and target dependencies
  
  # Find Frameworks, Libraries, and Embedded Content build phase
  frameworks_phase = target.frameworks_build_phase
  
  # Check if Gmail is already linked
  gmail_linked = frameworks_phase.files.any? { |f| f.display_name == 'Gmail' }
  
  unless gmail_linked
    puts "ℹ️  Gmail module needs to be added through Xcode's Package Dependencies"
    puts "   1. Open HomeInventoryModular.xcworkspace in Xcode"
    puts "   2. Select the HomeInventoryModular project"
    puts "   3. Go to Package Dependencies tab"
    puts "   4. Gmail should already be listed there"
    puts "   5. Select the HomeInventoryModular target"
    puts "   6. Go to General tab"
    puts "   7. Under 'Frameworks, Libraries, and Embedded Content', click +"
    puts "   8. Select 'Gmail' from the list"
  end
end

# Save the project
project.save

puts "✅ Project checked for Gmail module"