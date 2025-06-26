#!/usr/bin/env ruby

require 'deliver'
require 'fastlane_core'

# Configuration
IPA_PATH = File.expand_path('../build/HomeInventoryModular-1.0.6.ipa', __dir__)
USERNAME = 'griffinradcliffe@gmail.com'
APP_SPECIFIC_PASSWORD = 'lyto-qjbu-uffy-hsgb'

# Set environment
ENV['DELIVER_USER'] = USERNAME
ENV['FASTLANE_USER'] = USERNAME  
ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] = APP_SPECIFIC_PASSWORD
ENV['DELIVER_FORCE'] = '1'

puts "🚀 Delivering IPA to TestFlight using deliver"
puts "============================================"
puts "IPA: #{IPA_PATH}"
puts ""

# Check if IPA exists
unless File.exist?(IPA_PATH)
  puts "❌ IPA not found at #{IPA_PATH}"
  exit 1
end

puts "📦 IPA found: #{File.size(IPA_PATH) / 1024.0 / 1024.0} MB"

# Configure deliver options
options = {
  username: USERNAME,
  app_identifier: 'com.homeinventory.app',
  team_id: '2VXBQV4XC9',
  ipa: IPA_PATH,
  skip_metadata: true,
  skip_screenshots: true,
  skip_binary_upload: false,
  force: true,
  submit_for_review: false,
  automatic_release: false,
  submission_information: {
    export_compliance_uses_encryption: true,
    export_compliance_is_exempt: true,
    export_compliance_contains_third_party_cryptography: false,
    export_compliance_contains_proprietary_cryptography: false
  }
}

begin
  puts "🔑 Logging in to App Store Connect..."
  
  # Create Deliver runner
  config = FastlaneCore::Configuration.create(Deliver::Options.available_options, options)
  runner = Deliver::Runner.new(config)
  
  puts "📤 Uploading IPA..."
  runner.run
  
  puts ""
  puts "✅ Successfully uploaded to TestFlight!"
  puts ""
  puts "📱 Next steps:"
  puts "1. Go to https://appstoreconnect.apple.com"
  puts "2. Wait for build processing (5-10 minutes)"
  puts "3. Add release notes for v1.0.6"
  puts "4. Enable TestFlight testing"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
  
  if e.message.include?("Missing Provisioning Profile")
    puts ""
    puts "⚠️  The IPA needs a provisioning profile for device builds."
    puts "   The current IPA was built for simulator."
  end
  
  exit 1
end