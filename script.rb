# puts "Please enter your name"
# name = gets.chomp
# puts "Hello, #{name}! I'm Ruby!"
# Set the VSACValueSetLoader options; in this example we are fetching a specific profile
#
require 'rails'
require 'measure-loader/vsac_value_set_loader'
require 'measure-loader/cql_loader'

vsac_options = {
  options: {},
  api_key: '165874b1-4cdc-4d2f-9c80-41dff514333a'
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
