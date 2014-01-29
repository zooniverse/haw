defaultConfig =
  config: 'slug'

  root: process.cwd()

  port: 2217

  output: 'build'
  force: false

  quiet: false
  verbose: false

  # (Local directory): (Mount point)
  mount:
    './{public,static}': '/'

  # (Generated file path): (Source file)
  generate:
    '/main.js': './app/main.{js,coffee}'
    '/main.css': './css/main.{css,styl}'

  # Compile generated files (by source -> request extension).
  compile:
    coffee: js: (sourceFile, callback) ->
      webmake = require 'webmake'
      webmakeEco = require './webmake-eco'

      webmake sourceFile,
        ext: ['coffee', webmakeEco]
        sourceMap: true unless @webmakeOptions?.sourceMap is false
        ignoreErrors: true unless @webmakeOptions?.ignoreErrors is false
        callback

    styl: css: (sourceFile, callback) ->
      fs = require 'fs'
      stylus = require 'stylus'
      path = require 'path'
      nib = require 'nib'

      fs.readFile sourceFile, (error, source) =>
        if error?
          callback error
        else
          styl = stylus source.toString()
          styl.include path.dirname sourceFile

          unless @stylusOptions?.nib is false
            styl.include nib.path
            styl.import 'nib'

          unless @stylusOptions?.includeCss is false
            styl.set 'include css', true

          try
            rendered = styl.render()
            callback null, rendered
          catch e
            callback e

  # Optimize files after a build.
  # Paths are rooted at the build directory.
  optimize:
    '/main.js': require './optimize-js'
    '/main.css': require './optimize-css'
    '{*,**/*}.jpg': require './optimize-jpg'
    '{*,**/*}.png': require './optimize-png'

  # Modify file names, update references to them
  # (File with references): (Files to timestamp)
  timestamp:
    '/main.{css,js}': '/index.html'

  stampFilename: (filename, callback) ->
    # TODO: Async
    fs = require 'fs'
    crypto = require 'crypto'
    content = fs.readFileSync filename
    hash = crypto.createHash('md5').update(content).digest 'hex'
    [nameSegments..., ext] = filename.split '.'
    "#{nameSegments.join '.'}.#{hash[...6]}.#{ext}"

  init: require './default-inits'

module.exports = defaultConfig
