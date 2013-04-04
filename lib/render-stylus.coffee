fs = require 'fs'
path = require 'path'
stylus = require 'stylus'
nib = require 'nib'

renderStylus = (filename, options = {}) ->
  styl = stylus "#{fs.readFileSync filename}"

  styl.include path.dirname filename

  styl.set 'include css', options.includeImportedCss

  styl.set 'compress', options.compressCss

  if options.nib
    styl.include nib.path
    styl.import 'nib'

  styl.render()

module.exports = renderStylus
