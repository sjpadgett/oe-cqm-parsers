git clone https://github.com/openemr/oe-cqm-parsers

cd oe-cqm-parsers

cp .env.sample .env

put your VSAC API key in .env like this:
`VSAC_API_KEY=36806d55-084v-2mj9-d987-d651899e2144`

bundle install

bundle exec ruby script.rb