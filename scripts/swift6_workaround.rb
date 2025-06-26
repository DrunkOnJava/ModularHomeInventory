#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

class Swift6Workaround
  def initialize
    @package_files = Dir.glob("Modules/*/Package.swift")
    @backups = {}
  end
  
  def run
    puts "🔧 Swift 6 Workaround Script"
    puts "============================"
    puts ""
    
    begin
      # Backup and modify Package.swift files
      puts "📦 Backing up Package.swift files..."
      backup_packages
      
      puts "✏️  Temporarily updating to Swift 6.0..."
      update_packages_to_swift6
      
      puts "🏗️  Building with fastlane..."
      build_success = build_with_fastlane
      
      if build_success
        puts "✅ Build successful!"
        upload_to_testflight
      else
        puts "❌ Build failed!"
      end
      
    ensure
      # Always restore original files
      puts ""
      puts "🔄 Restoring original Package.swift files..."
      restore_packages
      puts "✅ Files restored"
    end
  end
  
  private
  
  def backup_packages
    @package_files.each do |file|
      backup_file = "#{file}.backup"
      FileUtils.cp(file, backup_file)
      @backups[file] = backup_file
      puts "  Backed up: #{file}"
    end
  end
  
  def update_packages_to_swift6
    @package_files.each do |file|
      content = File.read(file)
      # Update swift-tools-version to 6.0
      updated_content = content.gsub(/swift-tools-version:\s*5\.9/, 'swift-tools-version: 6.0')
      File.write(file, updated_content)
      puts "  Updated: #{file}"
    end
  end
  
  def restore_packages
    @backups.each do |original, backup|
      if File.exist?(backup)
        FileUtils.mv(backup, original, force: true)
        puts "  Restored: #{original}"
      end
    end
  end
  
  def build_with_fastlane
    puts ""
    cmd = "bundle exec fastlane ios build_only"
    puts "Running: #{cmd}"
    system(cmd)
  end
  
  def upload_to_testflight
    puts ""
    puts "📤 Uploading to TestFlight..."
    
    ipa_path = Dir.glob("build/*.ipa").first
    if ipa_path
      puts "Found IPA: #{ipa_path}"
      
      # Upload with altool
      upload_cmd = [
        "xcrun", "altool",
        "--upload-app",
        "-f", ipa_path,
        "-t", "ios",
        "-u", "griffinradcliffe@gmail.com",
        "-p", "lyto-qjbu-uffy-hsgb"
      ]
      
      if system(*upload_cmd)
        puts "✅ Successfully uploaded to TestFlight!"
        puts ""
        puts "📱 Next steps:"
        puts "1. Go to https://appstoreconnect.apple.com"
        puts "2. Add release notes for v1.0.6"
        puts "3. Enable TestFlight testing"
      else
        puts "❌ Upload failed"
        puts "Try using Transporter app with: #{ipa_path}"
      end
    else
      puts "❌ No IPA found in build directory"
    end
  end
end

# Run the workaround
Swift6Workaround.new.run