const fs = require('fs')
// Get a CMS Measure JSON and it's corresponding value set JSON by string
module.exports = class OeCqmParsers {

    getMeasureJSON(measureName) {
        let response = {
            measure: '',
            value_sets: '',
            error: ''
        }
        try {
            response.measure = fs.readFileSync('json_measures/' + measureName + '/' + measureName + '.json', 'utf8')
            response.value_sets = fs.readFileSync('json_measures/' + measureName + '/value_sets.json', 'utf8')
        } catch (err) {
            response.error = err
        }

        return response
    }
}

