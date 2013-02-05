eco = require 'eco'
uglify = require 'uglify-js'
cleanCSS = require 'clean-css'

defaults =
  root: '.'

  output: './build'

  port: 2217

  static:
    './public': '.'

  js:
    './js/main.coffee': './application.js'

  css:
    './css/main.styl': './application.css'

  compilers:
    '.eco': ->
      "module.exports = #{eco.compile arguments...};\n"

  minifiers:
    js: (source) ->
      (uglify.minify source, fromString: true).code

    css: (source) ->
      cleanCSS.process source, keepBreaks: true, removeEmpty: true

module.exports = defaults
