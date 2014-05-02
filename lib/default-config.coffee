defaultConfig =
  root: process.cwd()

  port: 2217

  output: 'build'
  force: false

  quiet: false
  verbose: false

  # (Local directory): (Mount point)
  mount:
    '{public,static}': '/'

  # (Generated file path): (Source file)
  generate:
    '/index.html': 'public/index.{html,eco}'
    '/main.js': 'app/main.{js,coffee}'
    '/main.css': 'css/main.{css,styl}'

  # Compile generated files (by source -> request extension).
  compile:
    eco: html: (sourceFile, callback) ->
      fs = require 'fs'
      eco = require 'eco'

      fs.readFile sourceFile, (error, content) =>
        unless error?
          try
            rendered = eco.render content.toString(), @
          catch e
            error = e

        callback error, rendered

    js: js: (sourceFile, callback) ->
      browserify = require 'browserify'
      makeTransform = require './make-browserify-transform'

      b = browserify extensions: ['.coffee', '.eco', '.md', '.markdown']

      b.transform require 'coffeeify'

      b.transform require 'browserify-eco'

      b.transform makeTransform ['.md', '.markdown'], (file, content, callback) ->
        marked = require 'marked'

        try
          parsed = "module.exports = unescape('#{escape marked.parse content}');"
        catch e
          error = e

        callback error, parsed

      @modifyBrowserify? b

      if typeof @build is 'function'
        uglifyify = require 'uglifyify'
        b.transform uglifyify

      b.add sourceFile

      bundleOpts = @bundleOptions or {}
        
      b.bundle bundleOpts, callback

    coffee: js: ->
      @compile.js.js.apply @, arguments

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

          @modifyStylus? styl

          try
            rendered = styl.render()
            callback null, rendered
          catch e
            callback e

  # Optimize files after a build.
  # Paths are rooted at the build directory.
  optimize:
    '/main.js': (file, callback) ->
      UglifyJS = require 'uglify-js'
      fs = require 'fs'

      {code} = UglifyJS.minify file
      fs.writeFile file, code, callback

    '/main.css': (filename, callback) ->
      fs = require 'fs'
      CleanCSS = require 'clean-css'

      fs.readFile filename, (error, content) ->
        if error?
          callback error
        else
          min = new CleanCSS(keepBreaks: true).minify content
          fs.writeFile filename, min, callback

    '{*,**/*}.jpg': (filename, callback) ->
      which = require 'which'
      exec = require 'easy-exec'

      which 'jpegtran', (error) ->
        if error?
          callback 'Missing jpegtran! Try `brew install jpeg`.'
        else
          exec "jpegtran -copy none -progressive -outfile #{filename} #{filename}", callback

    '{*,**/*}.png': (filename, callback) ->
      which = require 'which'
      exec = require 'easy-exec'

      which 'optipng', (error) ->
        if error?
          callback 'Missing optipng! Try `brew install optipng`.'
        else
          exec "optipng -strip all -o7 -quiet #{filename}", callback

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
