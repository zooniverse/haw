browserify = require 'browserify'
path = require 'path'
fs = require 'fs'

resolveJs = (filename, options = {}) ->
  libs = for file in options.libs || []
    file = path.resolve file
    "#{fs.readFileSync file};"

  bundle = browserify()

  bundle.debug = options.debug

  for ext, compiler of options.compilers || {}
    bundle.register ext, compiler

  bundle.addEntry filename

  js = bundle.bundle()

  (libs.join '\n\n') + js

module.exports = resolveJs
