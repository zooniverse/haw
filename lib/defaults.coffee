eco = require 'eco'
uglify = require 'uglify-js'

defaults =
  root: '.'

  port: 2217

  output: './build'
  version: true

  static:
    './public': '.'

  js:
    './app/index.coffee': './application.js'

  libs: []
  compilers:
    '.eco': ->
      "module.exports = #{eco.compile arguments...};\n"

  css:
    './css/index.styl': './application.css'

  nib: true
  includeImportedCss: true
  compressCss: false

  minifiers:
    js: (source) ->
      (uglify.minify source, fromString: true).code

module.exports = defaults
