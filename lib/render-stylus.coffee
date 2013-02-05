fs = require 'fs'
path = require 'path'
stylus = require 'stylus'
nib = require 'nib'

renderStylus = (filename) ->
  styl = stylus "#{fs.readFileSync filename}"

  styl.set 'paths', [
    path.dirname filename
    nib.path
  ]

  styl.import 'nib'

  styl.render()

module.exports = renderStylus
