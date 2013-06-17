webmake = require 'webmake'
path = require 'path'
fs = require 'fs'

try
  require.resolve 'webmake-eco'
catch (e)
  console.log '''
    You need to fake out a "webmake-eco" module. I am so sorry. Try this:
    mkdir node_modules/webmake-eco
    echo "module.exports = require('../../lib/webmake-eco');" > node_modules/webmake-eco/index.js
  '''

resolveJs = (filename, options = {}, callback) ->
  libs = for file in options.libs || []
    file = path.resolve file
    "#{fs.readFileSync file};"

  webmake filename,
    ext: ['coffee', 'eco']
    sourceMap: options.sourceMap
    (error, js) ->
      callback error, (libs.join '\n\n') + js

module.exports = resolveJs
