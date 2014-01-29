defaultConfig =
  config: 'slug'

  root: process.cwd()

  port: 2217

  directoryIndex: 'index.{html,htm}'

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
    coffee: js: (source, callback) ->
      CoffeeScript = require 'coffee-script'
      try
        callback null, CoffeeScript.compile source
      catch e
        callback e

    styl: css: require './styl-to-css'

  # Post-process generated files (by request extension).
  postProcess:
    js: (content, callback) ->
      callback? null, "// Requires resolved\n#{content}"

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
    '/main.{css,js}': 'index.html'

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
