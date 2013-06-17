webmake = require 'webmake'
require 'webmake-coffee'
path = require 'path'
fs = require 'fs'

resolveJs = (filename, options = {}, callback) ->
  libs = for file in options.libs || []
    file = path.resolve file
    "#{fs.readFileSync file};"

  webmake filename,
    ext: ['coffee']
    sourceMap: options.sourceMap
    (error, js) ->
      callback error, (libs.join '\n\n') + js

module.exports = resolveJs
