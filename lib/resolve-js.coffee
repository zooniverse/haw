browserify = require 'browserify'

resolveJs = (filename, options = {}) ->
  bundle = browserify()

  for ext, compiler of options.compilers || {}
    bundle.register ext, compiler

  bundle.addEntry filename

  bundle.bundle()

module.exports = resolveJs
