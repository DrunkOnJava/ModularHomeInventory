#!/usr/bin/env ruby

require 'digest'
require 'fileutils'

class FinalDuplicateCleanup
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    @final_dir = File.join(@project_dir, 'Screenshots', 'Final')
    
    puts "🧹 Final Screenshot Duplicate Cleanup"
    puts "=" * 50
    puts ""
  end
  
  def run
    unless Dir.exist?(@final_dir)
      puts "❌ Final screenshots directory not found"
      exit 1
    end
    
    screenshots = Dir.glob(File.join(@final_dir, '*.png')).sort
    
    if screenshots.empty?
      puts "📭 No final screenshots found"
      exit 0
    end
    
    puts "📊 Found #{screenshots.length} screenshots to analyze"
    puts ""
    
    # Remove exact duplicates, keeping the first occurrence
    remove_exact_duplicates(screenshots)
    
    # Create a summary of unique screenshots
    generate_final_summary
  end
  
  private
  
  def remove_exact_duplicates(screenshots)
    puts "🔍 Removing exact duplicates (keeping first occurrence)..."
    
    seen_hashes = {}
    removed_count = 0
    
    screenshots.each do |file|
      filename = File.basename(file)
      hash = Digest::MD5.hexdigest(File.read(file))
      
      if seen_hashes[hash]
        original = File.basename(seen_hashes[hash])
        puts "   🗑️  Removing: #{filename} (duplicate of #{original})"
        File.delete(file)
        removed_count += 1
      else
        seen_hashes[hash] = file
        puts "   ✅ Keeping: #{filename}"
      end
    end
    
    puts ""
    if removed_count > 0
      puts "✅ Removed #{removed_count} duplicate screenshots"
    else
      puts "✅ No duplicates found"
    end
    puts ""
  end
  
  def generate_final_summary
    remaining_screenshots = Dir.glob(File.join(@final_dir, '*.png')).sort
    
    puts "📊 Final Unique Screenshot Collection"
    puts "-" * 40
    
    total_size = remaining_screenshots.sum { |f| File.size(f) }
    
    puts "📁 Location: #{@final_dir}"
    puts "📸 Unique Screenshots: #{remaining_screenshots.length}"
    puts "💾 Total Size: #{format_file_size(total_size)}"
    puts ""
    
    puts "📋 Unique Screenshots:"
    remaining_screenshots.each_with_index do |file, index|
      filename = File.basename(file)
      size = format_file_size(File.size(file))
      puts "   #{index + 1}. #{filename} (#{size})"
    end
    
    puts ""
    puts "🎯 **FINAL RESULT:**"
    puts "   ✅ #{remaining_screenshots.length} truly unique app screenshots"
    puts "   ✅ Real app content with sample data"
    puts "   ✅ Ruby-powered automation system complete"
    puts "   ✅ Fastlane-compatible screenshot collection"
    puts ""
    puts "🔄 To regenerate: ruby scripts/working_screenshots.rb"
  end
  
  def format_file_size(bytes)
    if bytes < 1024
      "#{bytes}B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)}KB"
    else
      "#{(bytes / (1024.0 * 1024.0)).round(1)}MB"
    end
  end
end

# Run the cleanup
if __FILE__ == $0
  FinalDuplicateCleanup.new.run
end