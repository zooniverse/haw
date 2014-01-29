UglifyJS = require 'uglify-js'
fs = require 'fs'

optimizeJs = (file, callback) ->
  {code} = UglifyJS.minify file
  fs.writeFile file, code, callback

module.exports = optimizeJs
