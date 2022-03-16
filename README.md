`git clone https://github.com/openemr/oe-cqm-parsers`

`cd oe-cqm-parsers`

`cp .env.sample .env`

put your VSAC API key in .env like this:
`VSAC_API_KEY=36806d55-084v-2mj9-d987-d651899e2144`

`bundle install`

In order to update the Measure and Value-Set JSON files, you first 
need to update the CMS measures in the cms_measures directory.
Delete all zip files in cms_measures, then replace with measures found on CMS website here:
https://ecqi.healthit.gov/ep-ec?qt-tabs_ep=0

Then run the script to generate JSON:

`bundle exec ruby script.rb`