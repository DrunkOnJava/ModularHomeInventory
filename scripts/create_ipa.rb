#!/usr/bin/env ruby

require 'fileutils'
require 'zip'
require 'plist'

# Configuration
APP_NAME = "HomeInventoryModular"
VERSION = "1.0.6"
BUILD = "7"
BUNDLE_ID = "com.homeinventory.app"

puts "📦 Creating IPA for TestFlight submission"
puts "========================================"

# Check if we have a built app
app_path = "build/Build/Products/Debug-iphonesimulator/#{APP_NAME}.app"
unless File.exist?(app_path)
  puts "❌ No app found at #{app_path}"
  puts "   Please build first with: make build"
  exit 1
end

puts "✅ Found app at: #{app_path}"

# Read Info.plist to verify version
info_plist_path = "#{app_path}/Info.plist"
if File.exist?(info_plist_path)
  # Convert binary plist to XML first
  xml_output = `plutil -convert xml1 -o - "#{info_plist_path}"`
  info = Plist.parse_xml(xml_output)
  puts "📱 App Info:"
  puts "   Bundle ID: #{info['CFBundleIdentifier'] || BUNDLE_ID}"
  puts "   Version: #{info['CFBundleShortVersionString'] || VERSION}"
  puts "   Build: #{info['CFBundleVersion'] || BUILD}"
end

# Create Payload directory
payload_dir = "build/Payload"
FileUtils.rm_rf(payload_dir) if File.exist?(payload_dir)
FileUtils.mkdir_p(payload_dir)

# Copy app to Payload
puts "\n🔨 Preparing IPA structure..."
FileUtils.cp_r(app_path, payload_dir)

# Create IPA
ipa_path = "build/#{APP_NAME}-#{VERSION}.ipa"
puts "📦 Creating IPA at: #{ipa_path}"

Dir.chdir("build") do
  system("zip -r \"#{APP_NAME}-#{VERSION}.ipa\" Payload/")
end

if File.exist?(ipa_path)
  puts "\n✅ IPA created successfully!"
  puts "   Path: #{ipa_path}"
  puts "   Size: #{(File.size(ipa_path) / 1024.0 / 1024.0).round(2)} MB"
  
  puts "\n📤 Next steps:"
  puts "   1. Open Transporter app"
  puts "   2. Sign in with Apple ID: griffinradcliffe@gmail.com"
  puts "   3. Drag #{ipa_path} to Transporter"
  puts "   4. Click 'Deliver'"
else
  puts "\n❌ Failed to create IPA"
  exit 1
end

# Cleanup
FileUtils.rm_rf(payload_dir)