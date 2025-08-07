require 'debug'
require 'cqm-parsers'
require 'json'
require 'fileutils'
require 'dotenv'

Dotenv.load('.env')

Mongoid.include_type_for_serialization = true

=begin
https://ecqi.healthit.gov/ep-ec?qt-tabs_ep=0
=end

APP_CONFIG = {
  'vsac' => {
    'auth_url'     => 'https://vsac.nlm.nih.gov/vsac/ws',
    'content_url'  => 'https://vsac.nlm.nih.gov/vsac/svs',
    'utility_url'  => 'https://vsac.nlm.nih.gov/vsac',
    'default_profile' => 'eCQM Update 2022-05-05'
  }
}

vsac_options = {
  options: {
    profile: 'eCQM Update 2023-05-04'
  },
  vsac_api_key: ENV['VSAC_API_KEY']
}

measure_details = {}
value_set_loader = Measures::VSACValueSetLoader.new(vsac_options)

measure_files = Dir.entries('cms_measures')
failed_measures = []

measure_files.each do |measure_file_name|
  next if File.directory?(measure_file_name)

  measure_name = File.basename(measure_file_name, '.zip')
  output_dir = File.join('json_measures', measure_name)

  if File.directory?(output_dir)
    puts "[SKIP] #{measure_name} already exists in #{output_dir}"
    next
  end

  puts "[INFO] Processing #{measure_file_name}"

  begin
    measure_file = File.new(File.join('cms_measures', measure_file_name))
    loader = Measures::CqlLoader.new(measure_file, measure_details, value_set_loader)
    measures = loader.extract_measures

    FileUtils.mkdir_p(output_dir)

    measures.each do |measure|
      File.write(File.join(output_dir, 'value_sets.json'), measure.value_sets.to_json)
      File.write(File.join(output_dir, "#{measure_name}.json"), measure.to_json)
    end

    puts "[SUCCESS] Processed #{measure_name}"

  rescue Util::VSAC::VSACError => e
    puts "[ERROR] VSAC error for #{measure_name}: #{e.message}"
    failed_measures << measure_name
  rescue StandardError => e
    puts "[ERROR] Unexpected error for #{measure_name}: #{e.message}"
    failed_measures << measure_name
  end
end

# Optional: log failed measure names
unless failed_measures.empty?
  puts "\n[SUMMARY] Failed measures:"
  failed_measures.each { |name| puts "  - #{name}" }

  File.write("failed_measures.log", failed_measures.join("\n"))
end
