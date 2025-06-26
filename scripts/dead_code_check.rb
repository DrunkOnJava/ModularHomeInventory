#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'open3'

class DeadCodeChecker
  SEVERITY_LEVELS = {
    'class' => :high,
    'struct' => :high,
    'enum' => :high,
    'protocol' => :high,
    'function' => :medium,
    'property' => :medium,
    'enumcase' => :low,
    'typealias' => :low
  }.freeze

  SEVERITY_COLORS = {
    high: "\e[31m",      # Red
    medium: "\e[33m",    # Yellow
    low: "\e[36m",       # Cyan
    reset: "\e[0m"
  }.freeze

  def initialize
    @report_dir = 'reports/dead_code'
    FileUtils.mkdir_p(@report_dir)
  end

  def run
    puts "🔍 Running Periphery dead code analysis..."
    puts
    
    # Run Periphery scan
    json_output, status = Open3.capture2('periphery scan --format json')
    
    unless status.success?
      puts "❌ Periphery scan failed!"
      exit 1
    end
    
    # Parse results
    results = JSON.parse(json_output)
    
    if results.empty?
      puts "✅ No dead code found! Your codebase is clean."
      return
    end
    
    # Analyze results
    analyze_results(results)
    
    # Generate reports
    generate_html_report(results)
    generate_summary_report(results)
    
    # Show summary
    show_summary(results)
  end

  private

  def analyze_results(results)
    @stats = {
      total: results.length,
      by_kind: {},
      by_module: {},
      by_severity: { high: 0, medium: 0, low: 0 }
    }
    
    results.each do |item|
      # Count by kind
      kind = item['kind']
      @stats[:by_kind][kind] ||= 0
      @stats[:by_kind][kind] += 1
      
      # Count by module
      file_path = item['location']['file']
      module_name = extract_module_name(file_path)
      @stats[:by_module][module_name] ||= 0
      @stats[:by_module][module_name] += 1
      
      # Count by severity
      severity = SEVERITY_LEVELS[kind] || :low
      @stats[:by_severity][severity] += 1
    end
  end

  def extract_module_name(file_path)
    if file_path.include?('/Modules/')
      file_path.split('/Modules/')[1].split('/')[0]
    elsif file_path.include?('/Source/')
      'Main App'
    else
      'Other'
    end
  end

  def generate_html_report(results)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Dead Code Report</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }
          h1 { color: #333; }
          .stats { display: flex; gap: 20px; margin: 20px 0; }
          .stat-card { background: #f5f5f5; padding: 20px; border-radius: 8px; flex: 1; }
          .stat-value { font-size: 2em; font-weight: bold; color: #007AFF; }
          .high { color: #FF3B30; }
          .medium { color: #FF9500; }
          .low { color: #34C759; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
          th { background: #f5f5f5; font-weight: 600; }
          tr:hover { background: #f9f9f9; }
          .kind-badge { padding: 2px 8px; border-radius: 4px; font-size: 0.85em; }
          .kind-class, .kind-struct, .kind-enum, .kind-protocol { background: #FFE5E5; color: #CC0000; }
          .kind-function, .kind-property { background: #FFF3CD; color: #856404; }
          .kind-enumcase, .kind-typealias { background: #D4EDDA; color: #155724; }
        </style>
      </head>
      <body>
        <h1>Dead Code Analysis Report</h1>
        <p>Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</p>
        
        <div class="stats">
          <div class="stat-card">
            <div class="stat-value">#{@stats[:total]}</div>
            <div>Total Unused Items</div>
          </div>
          <div class="stat-card">
            <div class="stat-value high">#{@stats[:by_severity][:high]}</div>
            <div>High Priority</div>
          </div>
          <div class="stat-card">
            <div class="stat-value medium">#{@stats[:by_severity][:medium]}</div>
            <div>Medium Priority</div>
          </div>
          <div class="stat-card">
            <div class="stat-value low">#{@stats[:by_severity][:low]}</div>
            <div>Low Priority</div>
          </div>
        </div>
        
        <h2>By Module</h2>
        <table>
          <tr><th>Module</th><th>Count</th></tr>
          #{@stats[:by_module].sort_by { |_, count| -count }.map { |module_name, count|
            "<tr><td>#{module_name}</td><td>#{count}</td></tr>"
          }.join}
        </table>
        
        <h2>Detailed Results</h2>
        <table>
          <tr>
            <th>Type</th>
            <th>Name</th>
            <th>Location</th>
            <th>Module</th>
          </tr>
          #{results.map { |item|
            kind = item['kind']
            name = item['name']
            location = item['location']
            file = location['file']
            line = location['line']
            module_name = extract_module_name(file)
            
            "<tr>
              <td><span class='kind-badge kind-#{kind}'>#{kind}</span></td>
              <td><code>#{name}</code></td>
              <td>#{file}:#{line}</td>
              <td>#{module_name}</td>
            </tr>"
          }.join}
        </table>
      </body>
      </html>
    HTML
    
    File.write("#{@report_dir}/index.html", html)
    puts "📄 HTML report generated: #{@report_dir}/index.html"
  end

  def generate_summary_report(results)
    summary = []
    summary << "# Dead Code Summary Report"
    summary << ""
    summary << "Generated on: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    summary << ""
    summary << "## Statistics"
    summary << ""
    summary << "- **Total unused items**: #{@stats[:total]}"
    summary << "- **High priority**: #{@stats[:by_severity][:high]} (classes, structs, enums, protocols)"
    summary << "- **Medium priority**: #{@stats[:by_severity][:medium]} (functions, properties)"
    summary << "- **Low priority**: #{@stats[:by_severity][:low]} (enum cases, type aliases)"
    summary << ""
    summary << "## By Type"
    summary << ""
    @stats[:by_kind].sort_by { |_, count| -count }.each do |kind, count|
      summary << "- #{kind}: #{count}"
    end
    summary << ""
    summary << "## By Module"
    summary << ""
    @stats[:by_module].sort_by { |_, count| -count }.each do |module_name, count|
      summary << "- #{module_name}: #{count}"
    end
    summary << ""
    summary << "## Top 10 Files"
    summary << ""
    
    file_counts = {}
    results.each do |item|
      file = item['location']['file']
      file_counts[file] ||= 0
      file_counts[file] += 1
    end
    
    file_counts.sort_by { |_, count| -count }.first(10).each_with_index do |(file, count), index|
      summary << "#{index + 1}. #{file} (#{count} items)"
    end
    
    File.write("#{@report_dir}/summary.md", summary.join("\n"))
    puts "📄 Summary report generated: #{@report_dir}/summary.md"
  end

  def show_summary(results)
    puts
    puts "=" * 60
    puts "DEAD CODE ANALYSIS SUMMARY"
    puts "=" * 60
    puts
    puts "Total unused items found: #{color_for_count(@stats[:total])}#{@stats[:total]}#{SEVERITY_COLORS[:reset]}"
    puts
    puts "By severity:"
    puts "  #{SEVERITY_COLORS[:high]}High:   #{@stats[:by_severity][:high]}#{SEVERITY_COLORS[:reset]} (classes, structs, enums, protocols)"
    puts "  #{SEVERITY_COLORS[:medium]}Medium: #{@stats[:by_severity][:medium]}#{SEVERITY_COLORS[:reset]} (functions, properties)"
    puts "  #{SEVERITY_COLORS[:low]}Low:    #{@stats[:by_severity][:low]}#{SEVERITY_COLORS[:reset]} (enum cases, type aliases)"
    puts
    puts "By type:"
    @stats[:by_kind].sort_by { |_, count| -count }.each do |kind, count|
      severity = SEVERITY_LEVELS[kind] || :low
      puts "  #{SEVERITY_COLORS[severity]}#{kind.ljust(12)}: #{count}#{SEVERITY_COLORS[:reset]}"
    end
    puts
    puts "Top affected modules:"
    @stats[:by_module].sort_by { |_, count| -count }.first(5).each do |module_name, count|
      puts "  #{module_name.ljust(20)}: #{count}"
    end
    puts
    puts "Reports generated in: #{@report_dir}/"
    puts "  - index.html    (visual report)"
    puts "  - summary.md    (markdown summary)"
    puts
    
    if @stats[:total] > 50
      puts "⚠️  High amount of dead code detected! Consider cleaning up."
    elsif @stats[:total] > 20
      puts "⚠️  Moderate amount of dead code. Regular cleanup recommended."
    elsif @stats[:total] > 0
      puts "✅ Low amount of dead code. Good job maintaining the codebase!"
    end
  end

  def color_for_count(count)
    if count > 50
      SEVERITY_COLORS[:high]
    elsif count > 20
      SEVERITY_COLORS[:medium]
    else
      SEVERITY_COLORS[:low]
    end
  end
end

# Run the checker
DeadCodeChecker.new.run