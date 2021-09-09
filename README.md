git clone https://github.com/openemr/oe-cqm-parsers

cd oe-cqm-parsers

cp .env.sample .env

put your VSAC API key in .env like this:
`VSAC_API_KEY=Your UMLS API key`

bundle install

bundle exec ruby script.rb
