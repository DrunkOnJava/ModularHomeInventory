#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
if app_target.nil?
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

puts "✅ Found app target: #{app_target.name}"

# Add encryption compliance settings to all configurations
app_target.build_configurations.each do |config|
  puts "\n📝 Updating #{config.name} configuration:"
  
  # Add encryption compliance settings
  config.build_settings['INFOPLIST_KEY_ITSAppUsesNonExemptEncryption'] = 'YES'
  
  # Note: The compliance code will be provided by App Store Connect after first submission
  # config.build_settings['INFOPLIST_KEY_ITSEncryptionExportComplianceCode'] = 'YOUR_CODE_HERE'
  
  puts "   ✅ Added ITSAppUsesNonExemptEncryption = YES"
end

# Save the project
project.save
puts "\n✅ Project saved successfully!"
puts "\n📌 Important Next Steps:"
puts "1. Submit your first build to TestFlight"
puts "2. Complete the Export Compliance questionnaire in App Store Connect"
puts "3. App Store Connect will provide an ITSEncryptionExportComplianceCode"
puts "4. Add that code to your project using this script again"
puts "\n💡 For now, you can proceed with TestFlight submission."