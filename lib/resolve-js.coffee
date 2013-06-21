webmake = require 'webmake'
webmakeEco = require './webmake-eco'
path = require 'path'
fs = require 'fs'

resolveJs = (filename, options = {}, callback) ->
  libs = for file in options.libs || []
    file = path.resolve file
    "#{fs.readFileSync file};"

  webmake filename,
    ext: ['coffee', webmakeEco]
    sourceMap: options.sourceMap
    ignoreErrors: true
    (error, js) ->
      callback error, (libs.join '\n\n') + js

module.exports = resolveJs
