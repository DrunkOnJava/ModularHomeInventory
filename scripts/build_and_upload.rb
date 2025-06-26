#!/usr/bin/env ruby

require 'gym'
require 'pilot'

# Set credentials
ENV['FASTLANE_USER'] = 'griffinradcliffe@gmail.com'
ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] = 'lyto-qjbu-uffy-hsgb'

puts "🚀 Building and Uploading to TestFlight"
puts "======================================"
puts ""

begin
  # Configure gym for building
  gym_config = {
    project: "HomeInventoryModular.xcodeproj",
    scheme: "HomeInventoryModular",
    configuration: "Release",
    export_method: "app-store",
    output_directory: "./build",
    output_name: "HomeInventoryModular",
    clean: true,
    silent: false,
    skip_package_dependencies_resolution: true,
    cloned_source_packages_path: "./build/SourcePackages",
    disable_package_automatic_updates: true,
    export_options: {
      signingStyle: "automatic",
      teamID: "2VXBQV4XC9",
      uploadSymbols: true,
      generateAppStoreInformation: true
    }
  }
  
  puts "🔨 Building IPA for App Store..."
  puts "Note: This may fail due to Swift 6 package resolution issues"
  puts ""
  
  # Try to build
  ipa_path = Gym.config = gym_config
  ipa_file = Gym::Manager.new.work
  
  if ipa_file && File.exist?(ipa_file)
    puts "✅ Build successful!"
    puts "📦 IPA: #{ipa_file}"
    puts ""
    
    # Upload with Pilot
    puts "📤 Uploading to TestFlight..."
    
    pilot_config = {
      username: 'griffinradcliffe@gmail.com',
      app_identifier: 'com.homeinventory.app',
      ipa: ipa_file,
      skip_waiting_for_build_processing: true,
      skip_submission: true,
      changelog: "🎉 Home Inventory v1.0.6\n\n🆕 NEW FEATURES:\n• Professional Insurance Reports\n• View-Only Sharing Mode\n\n✨ IMPROVEMENTS:\n• Enhanced iPad experience\n• Better sync reliability\n• Performance optimizations"
    }
    
    Pilot.config = pilot_config
    Pilot::BuildManager.new.upload
    
    puts "✅ Successfully uploaded to TestFlight!"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  
  if e.message.include?("backward-incompatible with Swift")
    puts ""
    puts "⚠️  Swift 6 package resolution issue detected!"
    puts ""
    puts "Alternative approaches:"
    puts ""
    puts "1. Use Xcode GUI:"
    puts "   open HomeInventoryModular.xcodeproj"
    puts "   - Select 'Any iOS Device'"
    puts "   - Product → Archive"
    puts "   - Upload from Organizer"
    puts ""
    puts "2. Downgrade to Swift 5.9:"
    puts "   - Install Swift 5.9 toolchain"
    puts "   - Select in Xcode preferences"
    puts ""
    puts "3. Use Transporter app:"
    puts "   - Build IPA manually in Xcode"
    puts "   - Upload with Transporter"
  end
end