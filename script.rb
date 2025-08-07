#!/usr/bin/env ruby

require 'debug'
require 'cqm-parsers'
require 'json'
require 'fileutils'
require 'dotenv'
require 'optparse'

Dotenv.load('.env')

Mongoid.include_type_for_serialization = true

=begin
https://ecqi.healthit.gov/ep-ec?qt-tabs_ep=0
=end

APP_CONFIG = {
  'vsac' => {
    'auth_url' => 'https://vsac.nlm.nih.gov/vsac/ws',
    'content_url' => 'https://vsac.nlm.nih.gov/vsac/svs',
    'utility_url' => 'https://vsac.nlm.nih.gov/vsac',
    'default_profile' => 'eCQM Update 2022-05-05'
  }
}

# VSAC Profile mappings - only profiles with 'Update {year}' pattern
VSAC_PROFILES = {
  2025 => 'eCQM Update 2025-05-08',
  2024 => 'eCQM Update 2024-05-02',
  2023 => 'eCQM Update 2023-05-04',
  2022 => 'eCQM Update 2022-05-05',
  2021 => 'eCQM Update 2021-05-06',
  2020 => 'eCQM Update 2020-05-07',
  2019 => 'eCQM Update 2019-05-10'
}

# Parse command line options
options = {
  profile: nil,
  year: nil,
  measures_dir: 'cms_measures',
  output_dir: 'json_measures'
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby script.rb [options]"

  opts.on("--profile PROFILE", "VSAC Profile name (overrides --year)") { |v| options[:profile] = v }
  opts.on("--year YEAR", Integer, "Year for eCQM Update profile (#{VSAC_PROFILES.keys.join(', ')})") { |v| options[:year] = v }
  opts.on("--measures-dir DIR", "Directory containing CMS measure ZIP files (default: cms_measures)") { |v| options[:measures_dir] = v }
  opts.on("--output-dir DIR", "Output directory for JSON measures (default: json_measures)") { |v| options[:output_dir] = v }
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts "\nAvailable eCQM Update profiles by year:"
    VSAC_PROFILES.each { |year, profile| puts "  #{year}: #{profile}" }
    exit
  end
end.parse!

# Determine profile to use
selected_profile = nil
if options[:profile]
  selected_profile = options[:profile]
  puts "[INFO] Using custom profile: #{selected_profile}"
elsif options[:year]
  if VSAC_PROFILES.key?(options[:year])
    selected_profile = VSAC_PROFILES[options[:year]]
    puts "[INFO] Using eCQM Update profile for #{options[:year]}: #{selected_profile}"
  else
    puts "[ERROR] Year #{options[:year]} not supported. Available years: #{VSAC_PROFILES.keys.join(', ')}"
    exit 1
  end
else
  # Default to most recent profile
  latest_year = VSAC_PROFILES.keys.max
  selected_profile = VSAC_PROFILES[latest_year]
  puts "[INFO] No profile specified, using latest (#{latest_year}): #{selected_profile}"
end

# Build full output directory path
full_output_dir = if options[:year]
                    "#{options[:year]}_reporting_period/#{options[:output_dir]}"
                  else
                    options[:output_dir]
                  end

# Build full measures directory path
full_measures_dir = if options[:year]
                      "#{options[:year]}_reporting_period/#{options[:measures_dir]}"
                    else
                      options[:measures_dir]
                    end

# Validate directories
unless Dir.exist?(full_measures_dir)
  puts "[ERROR] Measures directory '#{full_measures_dir}' not found"
  exit 1
end

# VSAC configuration
vsac_options = {
  options: {
    profile: selected_profile
  },
  vsac_api_key: ENV['VSAC_API_KEY']
}

unless vsac_options[:vsac_api_key]
  puts "[ERROR] VSAC_API_KEY not found in environment variables"
  puts "Please set your VSAC API key in .env file:"
  puts "echo 'VSAC_API_KEY=your_api_key_here' > .env"
  exit 1
end

measure_details = {}
value_set_loader = Measures::VSACValueSetLoader.new(vsac_options)

measure_files = Dir.entries(full_measures_dir)
failed_measures = []
processed_count = 0
skipped_count = 0

puts "[INFO] Processing measures from '#{full_measures_dir}' to '#{full_output_dir}'"
puts "[INFO] Using VSAC profile: #{selected_profile}"
puts "=" * 60

measure_files.each do |measure_file_name|
  next if File.directory?(File.join(full_measures_dir, measure_file_name))

  measure_name = File.basename(measure_file_name, '.zip')
  output_dir = File.join(full_output_dir, measure_name)

  # Check if measure JSON already exists (skip if it does)
  measure_json_file = File.join(output_dir, "#{measure_name}.json")
  if File.exist?(measure_json_file)
    puts "[SKIP] #{measure_name} JSON already exists: #{measure_json_file}"
    skipped_count += 1
    next
  end

  puts "[INFO] Processing #{measure_file_name}"

  begin
    measure_file = File.new(File.join(full_measures_dir, measure_file_name))
    loader = Measures::CqlLoader.new(measure_file, measure_details, value_set_loader)
    measures = loader.extract_measures

    FileUtils.mkdir_p(output_dir)

    measures.each do |measure|
      File.write(File.join(output_dir, 'value_sets.json'), measure.value_sets.to_json)
      File.write(File.join(output_dir, "#{measure_name}.json"), measure.to_json)
    end

    puts "[SUCCESS] Processed #{measure_name}"
    processed_count += 1

  rescue Util::VSAC::VSACError => e
    puts "[ERROR] VSAC error for #{measure_name}: #{e.message}"
    failed_measures << measure_name
  rescue StandardError => e
    puts "[ERROR] Unexpected error for #{measure_name}: #{e.message}"
    failed_measures << measure_name
  end
end

# Summary
puts "=" * 60
puts "[SUMMARY] Processing complete:"
puts "  Processed: #{processed_count} measures"
puts "  Skipped: #{skipped_count} measures (already exist)"
puts "  Failed: #{failed_measures.length} measures"

# Log failed measures
unless failed_measures.empty?
  puts "\nFailed measures:"
  failed_measures.each { |name| puts "  - #{name}" }

  failed_log = "failed_measures_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
  File.write(failed_log, failed_measures.join("\n"))
  puts "\nFailed measures logged to: #{failed_log}"
end

puts "\nNext steps:"
puts "1. Run generate_ecqm_list.rb to create OpenEMR SQL lists"
puts "2. Import the generated SQL into your OpenEMR database"
