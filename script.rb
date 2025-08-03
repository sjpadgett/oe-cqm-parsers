require 'cqm-parsers'
require 'json'
require 'fileutils'
require 'dotenv'

Dotenv.load('.env')

# Configure Mongoid
require 'mongoid'
Mongoid.load!('config/mongoid.yml', ENV['RAILS_ENV'] || 'development')

# To be compatible with the eCQM calculator, the measure models must have the _type fields
Mongoid.include_type_for_serialization = true

APP_CONFIG = {'vsac'=> {'auth_url'=> 'https://vsac.nlm.nih.gov/vsac/ws',
                        'content_url' => 'https://vsac.nlm.nih.gov/vsac/svs',
                        'utility_url' => 'https://vsac.nlm.nih.gov/vsac',
                        'default_profile' => 'eCQM Update 2019-05-10'}}

# To see available VSAC profiles https://vsac.nlm.nih.gov/vsac/profiles
# To get your VSAC API key https://uts.nlm.nih.gov/uts/profile
vsac_options = {
  options: {
    profile: 'eCQM Update 2021-05-06'
  },
  api_key: ENV['VSAC_API_KEY']
}

# Set the measure details. For defaults, you can just pass in {}.
measure_details = {}

# Initialize a value set loader, in this case we are using the VSACValueSetLoader.
value_set_loader = Measures::VSACValueSetLoader.new(vsac_options)

measure_files = Dir.entries('cms_measures')
measure_files.each do |measure_file_name|

  next if File.directory? measure_file_name

  # Load a MAT package from test fixtures.
  measure_file = File.new('cms_measures/' + measure_file_name)

  # Initialize the CqlLoader with the needed parameters.
  loader = Measures::CqlLoader.new(measure_file, measure_details, value_set_loader)

  # Build an array of measure models.
  measures = loader.extract_measures

  measure_name = File.basename(measure_file_name, '.zip')

  measures.each do |measure|
    dirname = 'json_measures/' + measure_name
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    value_sets_json = measure.value_sets.to_json
    measure_json = measure.to_json
    # puts measure.to_json
    File.write(dirname + '/' + 'value_sets.json', value_sets_json)
    File.write(dirname + '/' + measure_name + '.json', measure_json)
  end
end
