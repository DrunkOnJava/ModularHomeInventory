#!/usr/bin/env ruby

require 'spaceship'
require 'fastlane_core'

# Configuration
APP_IDENTIFIER = 'com.homeinventory.app'
IPA_PATH = 'build/HomeInventoryModular-1.0.6.ipa'
USERNAME = 'griffinradcliffe@gmail.com'
APP_SPECIFIC_PASSWORD = 'lyto-qjbu-uffy-hsgb'
TEAM_ID = '2VXBQV4XC9'

puts "🚀 TestFlight Upload via Ruby Spaceship"
puts "========================================"
puts "App: #{APP_IDENTIFIER}"
puts "IPA: #{IPA_PATH}"
puts ""

# Check if IPA exists
unless File.exist?(IPA_PATH)
  puts "❌ IPA not found at #{IPA_PATH}"
  exit 1
end

# Configure Spaceship
ENV['FASTLANE_USER'] = USERNAME
ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] = APP_SPECIFIC_PASSWORD
ENV['SPACESHIP_SKIP_2FA_UPGRADE'] = '1'

begin
  puts "🔑 Logging into App Store Connect..."
  
  # Login to App Store Connect
  Spaceship::ConnectAPI.login(USERNAME, use_portal: false, use_tunes: true)
  
  # Get available teams
  teams = Spaceship::ConnectAPI.teams
  if teams.length > 1
    # Find our team
    team = teams.find { |t| t.id == TEAM_ID }
    if team
      Spaceship::ConnectAPI.select_team(team_id: team.id)
      puts "✅ Selected team: #{team.name} (#{team.id})"
    end
  end
  
  # Find the app
  puts "🔍 Finding app..."
  app = Spaceship::ConnectAPI::App.find(APP_IDENTIFIER)
  
  if app.nil?
    puts "❌ Could not find app with identifier: #{APP_IDENTIFIER}"
    exit 1
  end
  
  puts "✅ Found app: #{app.name} (#{app.bundle_id})"
  
  # Upload the IPA using altool directly
  puts "📤 Uploading IPA to TestFlight..."
  puts ""
  
  # Use altool command directly
  altool_path = "/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool"
  
  cmd = [
    altool_path,
    "--upload-app",
    "-f", IPA_PATH,
    "-t", "ios",
    "-u", USERNAME,
    "-p", "@env:FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD",
    "--output-format", "xml"
  ]
  
  puts "Executing: #{cmd.join(' ')}"
  puts ""
  
  require 'open3'
  stdout, stderr, status = Open3.capture3(*cmd)
  
  if status.success?
    puts "✅ Successfully uploaded to TestFlight!"
    puts ""
    puts "📱 Next steps:"
    puts "1. Go to https://appstoreconnect.apple.com"
    puts "2. Select #{app.name}"
    puts "3. Go to TestFlight tab"
    puts "4. Wait for build processing (usually 5-10 minutes)"
    puts "5. Add testers and start testing!"
  else
    puts "❌ Upload failed!"
    puts "STDOUT: #{stdout}"
    puts "STDERR: #{stderr}"
    
    if stderr.include?("Missing Provisioning Profile")
      puts ""
      puts "⚠️  The IPA is missing a provisioning profile."
      puts "   This happens when building from simulator."
      puts "   You need to create a proper device build."
    end
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
  exit 1
end