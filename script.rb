require_relative '../cqm-parsers/lib/cqm-parsers.rb'
require 'json'

APP_CONFIG = {'vsac'=> {'auth_url'=> 'https://vsac.nlm.nih.gov/vsac/ws',
                        'content_url' => 'https://vsac.nlm.nih.gov/vsac/svs',
                        'utility_url' => 'https://vsac.nlm.nih.gov/vsac',
                        'default_profile' => 'MU2 Update 2016-04-01'}}

vsac_options = {
  options: {},
  api_key: 'xxxx'
}

# Set the measure details. For defaults, you can just pass in {}.
measure_details = {}

# Load a MAT package from test fixtures.
measure_file = File.new('measures/CMS2v9.zip')

# Initialize a value set loader, in this case we are using the VSACValueSetLoader.
value_set_loader = Measures::VSACValueSetLoader.new(vsac_options)

# Initialize the CqlLoader with the needed parameters.
loader = Measures::CqlLoader.new(measure_file, measure_details, value_set_loader)
# Build an array of measure models.
measures = loader.extract_measures

measures.each do |measure|
  puts measure.to_json
end
