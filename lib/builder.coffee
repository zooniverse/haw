defaults = require './defaults'
clone = require 'clone'
deepExtend = require 'deep-extend'
path = require 'path'
wrench = require 'wrench'
fs = require 'fs'
resolveJs = require './resolve-js'
renderStylus = require './render-stylus'
Version = require 'node-version-assets'

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

    htmlFiles = []
    imageFiles = []

    for file in wrench.readdirSyncRecursive output
      file = path.resolve output, file
      htmlFiles.push file if file.match /\.html?$/i
      imageFiles.push file if file.match /\.jpe?g|\.png$/i

    versionedAssets = []

    for entry, exit of @js
      entry = path.resolve @root, entry
      exit = path.resolve output, exit
      console.log "Bundling JavaScript #{path.relative '.', entry} -> #{path.relative '.', exit}"

      js = resolveJs entry, {@libs, @compilers}
      min = @minifiers.js js
      fs.writeFileSync exit, min
      versionedAssets.push exit

    for entry, exit of @css
      entry = path.resolve @root, entry
      exit = path.resolve output, exit
      console.log "Bundling CSS #{path.relative '.', entry} -> #{path.relative '.', exit}"

      css = renderStylus entry, {@nib, @includeCss, @compressCss}
      fs.writeFileSync exit, css
      versionedAssets.push exit

    if @version
      version = new Version
        assets: versionedAssets
        grepFiles: htmlFiles

      version.run()

module.exports = Builder
