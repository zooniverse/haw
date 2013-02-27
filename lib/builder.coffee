defaults = require './defaults'
clone = require 'clone'
deepExtend = require 'deep-extend'
path = require 'path'
wrench = require 'wrench'
fs = require 'fs'
resolveJs = require './resolve-js'
renderStylus = require './render-stylus'

class Builder
  constructor: (params = {}) ->
    @[property] = value for property, value of clone defaults
    deepExtend @, params

  build: (output, options = {}) ->
    output = path.resolve output || options.output || @output

    throw new Error "#{output} already exists" if fs.existsSync output

    wrench.mkdirSyncRecursive output

    for entry, exit of @static
      entry = path.resolve @root, entry
      exit = path.resolve output, exit
      console.log "Copying #{path.relative '.', entry} -> #{path.relative '.', exit}"
      wrench.copyDirSyncRecursive entry, exit

    # TODO: Losslessly compress images.

    for entry, exit of @js
      entry = path.resolve @root, entry
      exit = path.resolve output, exit
      js = resolveJs entry, {@libs, @compilers}
      min = @minifiers.js js
      fs.writeFileSync exit, min
      # TODO: Change file name, change reference in HTML files

    for entry, exit of @css
      entry = path.resolve @root, entry
      exit = path.resolve output, exit
      css = renderStylus entry
      min =  @minifiers.css css
      fs.writeFileSync exit, min
      # TODO: Change file name, change reference in HTML files


module.exports = Builder
