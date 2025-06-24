#!/usr/bin/env ruby

require 'xcodeproj'

# Create a new workspace
workspace = Xcodeproj::Workspace.new(nil)

# Add the main project
workspace << 'HomeInventoryModular.xcodeproj'

# Add all local package paths
[
  'Modules/Core',
  'Modules/SharedUI',
  'Modules/Items',
  'Modules/BarcodeScanner',
  'Modules/Receipts',
  'Modules/AppSettings',
  'Modules/Sync',
  'Modules/Premium',
  'Modules/Onboarding'
].each do |package_path|
  workspace << package_path
end

# Save the workspace
workspace.save_as('HomeInventoryModular.xcworkspace')

puts "✅ Created HomeInventoryModular.xcworkspace with all local packages"