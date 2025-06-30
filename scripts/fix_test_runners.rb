#!/usr/bin/env ruby

# Fix all test runner scripts to handle existing result bundles

Dir.glob('scripts/test-runners/test-*.sh').each do |file|
  content = File.read(file)
  
  # Skip if already fixed
  next if content.include?('rm -rf')
  
  # Extract result bundle path
  if match = content.match(/-resultBundlePath\s+([^\s]+\.xcresult)/)
    bundle_path = match[1]
    
    # Add cleanup code before "# Run tests"
    cleanup_code = <<-CODE
# Remove existing result bundle if it exists
RESULT_BUNDLE_PATH="#{bundle_path}"
if [ -d "$RESULT_BUNDLE_PATH" ]; then
  rm -rf "$RESULT_BUNDLE_PATH"
fi

CODE
    
    content.sub!(/# Run tests/, cleanup_code + "# Run tests")
    content.gsub!(/-resultBundlePath\s+#{Regexp.escape(bundle_path)}/, '-resultBundlePath "$RESULT_BUNDLE_PATH"')
    
    File.write(file, content)
    puts "✅ Fixed #{file}"
  end
end

puts "\n✅ Done fixing test runners!"