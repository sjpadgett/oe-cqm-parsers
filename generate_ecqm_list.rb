#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'
require 'cgi'

# --- Argument Parsing ---
options = {
  list_id: nil,
  list_title: nil,
  json_dir: "json_measures",
  output_dir: 'output',
  defaults: [],
  year: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby generate_ecqm_list.rb [options]"

  opts.on("--list-id ID", "List ID (e.g. ecqm_2025_reporting)") { |v| options[:list_id] = v }
  opts.on("--list-title TITLE", "List Title (e.g. eCQM 2025 Performance Period)") { |v| options[:list_title] = v }
  opts.on("--json-dir DIR", "Directory containing parsed eCQM JSON measures") { |v| options[:json_dir] = v }
  opts.on("--output-dir DIR", "Where to write the SQL output") { |v| options[:output_dir] = v }
  opts.on("--defaults x,y,z", Array, "Comma-separated list of CMS IDs to mark as default active") { |v| options[:defaults] = v }
  opts.on("--year YEAR", Integer, "Override year used for list_id and title (e.g. 2024)") { |v| options[:year] = v }
end.parse!

# --- Scan All JSONs and Collect Measure Metadata ---
measures = []
Dir.glob("#{options[:year]}_reporting_period/#{options[:json_dir]}/**/*.json").each do |file_path|
  next if file_path.include?('value_sets.json')

  begin
    measure = JSON.parse(File.read(file_path), max_nesting: false)
    cms_id = measure['cms_id']
    title = measure['title']
    description = measure['description']
    next unless cms_id && title

    measures << { id: cms_id, title: title, description: description }
  rescue => e
    warn "[WARN] Failed to process #{file_path}: #{e.message}"
  end
end

abort("[ERROR] No valid measures found in #{options[:json_dir]}") if measures.empty?

# --- Auto-fill list_id and title if needed ---
unless options[:list_id] && options[:list_title]
  year = options[:year]
  unless year
    abort("[ERROR] Please enter a reporting period year (--year=YYYY) to auto-generate list_id and list_title")
  end
  options[:list_id] ||= "ecqm_#{year}_reporting"
  options[:list_title] ||= "eCQM #{year} Performance Period"
end

# --- SQL Generation ---
sql_lines = []
sql_lines << "INSERT INTO `list_options` (`list_id`, `option_id`, `title`, `seq`, `is_default`, `option_value`, `notes`) VALUES " \
  "('lists','#{options[:list_id]}','#{options[:list_title]}',0,1,0, '');"

seq = 0
measures.each do |m|
  seq += 10
  activity = options[:defaults].include?(m[:id]) ? 1 : 0
  safe_title = m[:title].gsub("'", "\\\\'")
  html_safe_description = CGI.escapeHTML(m[:description].to_s).gsub("\n", "<br>")
  safe_description = html_safe_description.gsub("'", "\\\\'")
  sql_lines << "INSERT INTO `list_options` (`list_id`, `option_id`, `title`, `seq`, `activity`, `notes`) VALUES " \
    "('#{options[:list_id]}','#{m[:id]}','#{safe_title}',#{seq},#{activity},'#{safe_description}');"

  puts "[INFO] Cms Id: #{m[:id]} - #{safe_title}"
end

# --- Output ---
FileUtils.mkdir_p(options[:output_dir])
output_path = File.join(options[:output_dir], "#{options[:list_id]}.sql")
File.write(output_path, sql_lines.join("\n") + "\n")

puts "[INFO] SQL list written to #{output_path}"
