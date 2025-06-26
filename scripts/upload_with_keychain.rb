#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

# Configuration
IPA_PATH = File.expand_path('../build/HomeInventoryModular-1.0.6.ipa', __dir__)
APP_ID = 'com.homeinventory.app'
USERNAME = 'griffinradcliffe@gmail.com'

puts "🚀 TestFlight Upload using Keychain Credentials"
puts "=============================================="
puts "App: #{APP_ID}"
puts "IPA: #{IPA_PATH}"
puts ""

# Check if IPA exists
unless File.exist?(IPA_PATH)
  puts "❌ IPA not found at #{IPA_PATH}"
  exit 1
end

puts "📦 IPA found: #{(File.size(IPA_PATH) / 1024.0 / 1024.0).round(2)} MB"

# Since the IPA is from simulator build, we need to create a proper one
# Let's use xcrun altool with keychain access
puts "📤 Uploading to TestFlight using keychain credentials..."
puts ""

# Use xcrun altool which can access keychain
cmd = [
  'xcrun', 'altool',
  '--upload-app',
  '-f', IPA_PATH,
  '-t', 'ios',
  '-u', USERNAME,
  '--bundle-id', APP_ID,
  '--bundle-short-version-string', '1.0.6',
  '--bundle-version', '7'
]

puts "Executing upload command..."
puts "This will use credentials from your keychain"
puts ""

# Execute with real-time output
success = system(*cmd)

if success
  puts ""
  puts "✅ Upload completed!"
  puts ""
  puts "📱 Next steps:"
  puts "1. Go to https://appstoreconnect.apple.com"
  puts "2. Check TestFlight for the new build"
  puts "3. Add release notes for v1.0.6:"
  puts ""
  puts "🎉 Home Inventory v1.0.6"
  puts ""
  puts "🆕 NEW FEATURES:"
  puts "• Professional Insurance Reports"
  puts "• View-Only Sharing Mode"
  puts ""
  puts "✨ IMPROVEMENTS:"
  puts "• Enhanced iPad experience"
  puts "• Better sync reliability"
  puts "• Performance optimizations"
else
  puts ""
  puts "❌ Upload failed!"
  puts ""
  
  if $?.exitstatus == 1
    puts "Common issues:"
    puts "• Missing provisioning profile (simulator builds can't be uploaded)"
    puts "• Invalid credentials in keychain"
    puts "• Network connectivity issues"
    puts ""
    puts "To fix provisioning profile issue:"
    puts "1. Open Xcode"
    puts "2. Select 'Any iOS Device' as destination"
    puts "3. Product → Archive"
    puts "4. Upload from Organizer"
  end
end