eco = require 'eco'
uglify = require 'uglify-js'
cleanCSS = require 'clean-css'

defaults =
  root: '.'

  port: 2217

  output: './build'

  static:
    './public': '.'

  js:
    './app/index.coffee': './application.js'

  libs: []

  css:
    './css/index.styl': './application.css'

  compilers:
    '.eco': ->
      "module.exports = #{eco.compile arguments...};\n"

  minifiers:
    js: (source) ->
      (uglify.minify source, fromString: true).code

    css: (source) ->
      cleanCSS.process source, keepBreaks: true, removeEmpty: true

module.exports = defaults
