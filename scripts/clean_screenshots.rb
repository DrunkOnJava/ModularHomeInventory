#!/usr/bin/env ruby

require 'fileutils'
require 'digest'

class ScreenshotCleaner
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    @output_dir = File.join(@project_dir, 'Screenshots', 'AutomatedApp')
    
    puts "🧹 Screenshot Cleanup and Organization Tool"
    puts "=" * 50
    puts ""
  end
  
  def run
    unless Dir.exist?(@output_dir)
      puts "❌ Screenshot directory not found: #{@output_dir}"
      exit 1
    end
    
    screenshots = Dir.glob(File.join(@output_dir, '*.png'))
    
    if screenshots.empty?
      puts "📭 No screenshots found to clean"
      exit 0
    end
    
    puts "📊 Analyzing #{screenshots.length} screenshots..."
    puts ""
    
    # Remove exact duplicates
    remove_exact_duplicates(screenshots)
    
    # Remove zero-byte files
    remove_zero_byte_files(screenshots)
    
    # Organize by content similarity
    organize_by_similarity(screenshots)
    
    # Generate cleaned summary
    generate_cleaned_summary
  end
  
  private
  
  def remove_exact_duplicates(screenshots)
    puts "🔍 Removing exact duplicates..."
    
    file_hashes = {}
    duplicates_removed = 0
    
    screenshots.each do |file|
      next unless File.exist?(file)
      
      hash = Digest::MD5.hexdigest(File.read(file))
      
      if file_hashes[hash]
        puts "   🗑️  Removing duplicate: #{File.basename(file)}"
        puts "       (same as #{File.basename(file_hashes[hash])})"
        File.delete(file)
        duplicates_removed += 1
      else
        file_hashes[hash] = file
      end
    end
    
    if duplicates_removed > 0
      puts "   ✅ Removed #{duplicates_removed} exact duplicates"
    else
      puts "   ✅ No exact duplicates found"
    end
    puts ""
  end
  
  def remove_zero_byte_files(screenshots)
    puts "🔍 Removing zero-byte files..."
    
    zero_byte_count = 0
    
    screenshots.each do |file|
      next unless File.exist?(file)
      
      if File.size(file) == 0
        puts "   🗑️  Removing zero-byte file: #{File.basename(file)}"
        File.delete(file)
        zero_byte_count += 1
      end
    end
    
    if zero_byte_count > 0
      puts "   ✅ Removed #{zero_byte_count} zero-byte files"
    else
      puts "   ✅ No zero-byte files found"
    end
    puts ""
  end
  
  def organize_by_similarity(screenshots)
    puts "📁 Organizing by content type..."
    
    # Create organized subdirectories
    subdirs = {
      'navigation' => File.join(@output_dir, 'organized', 'navigation'),
      'interactions' => File.join(@output_dir, 'organized', 'interactions'),
      'modals' => File.join(@output_dir, 'organized', 'modals'),
      'edge_cases' => File.join(@output_dir, 'organized', 'edge_cases'),
      'duplicates' => File.join(@output_dir, 'organized', 'duplicates')
    }
    
    subdirs.each_value { |dir| FileUtils.mkdir_p(dir) }
    
    remaining_screenshots = Dir.glob(File.join(@output_dir, '*.png'))
    
    remaining_screenshots.each do |file|
      filename = File.basename(file)
      
      target_dir = case filename
                   when /^0[1-5]_/
                     subdirs['navigation']
                   when /^0[6-9]_|^1[0-4]_/
                     subdirs['interactions']
                   when /^1[5-9]_/
                     subdirs['modals']
                   when /^2[0-9]_/
                     subdirs['edge_cases']
                   else
                     subdirs['duplicates']
                   end
      
      target_path = File.join(target_dir, filename)
      FileUtils.cp(file, target_path)
      puts "   📁 #{filename} → #{File.basename(target_dir)}/"
    end
    
    puts "   ✅ Organized screenshots into categories"
    puts ""
  end
  
  def generate_cleaned_summary
    puts "📊 Cleanup Summary"
    puts "-" * 20
    
    remaining_screenshots = Dir.glob(File.join(@output_dir, '*.png'))
    organized_screenshots = Dir.glob(File.join(@output_dir, 'organized', '**', '*.png'))
    
    total_size = (remaining_screenshots + organized_screenshots).sum { |f| File.size(f) }
    
    puts "📁 Original location: #{remaining_screenshots.length} files"
    puts "📂 Organized location: #{organized_screenshots.length} files"
    puts "💾 Total size after cleanup: #{format_file_size(total_size)}"
    puts ""
    
    if organized_screenshots.any?
      puts "📂 Organized Categories:"
      ['navigation', 'interactions', 'modals', 'edge_cases', 'duplicates'].each do |category|
        category_files = Dir.glob(File.join(@output_dir, 'organized', category, '*.png'))
        if category_files.any?
          category_size = category_files.sum { |f| File.size(f) }
          puts "   #{category.capitalize}: #{category_files.length} files (#{format_file_size(category_size)})"
        end
      end
    end
    
    puts ""
    puts "💡 Next Steps:"
    puts "   1. Review organized categories for best screenshots"
    puts "   2. Delete remaining duplicates in main directory"
    puts "   3. Use organized screenshots for fastlane and documentation"
    puts "   4. Run automation again with sample data for more variety"
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
  ScreenshotCleaner.new.run
end