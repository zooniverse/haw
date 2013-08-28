Configurable = require './configurable'
path = require 'path'
fs = require 'fs'
wrench = require 'wrench'
dotPrefix = require './dot-prefix'
glob = require 'glob'

class Builder extends Configurable
  build: (output, options = {}) ->
    output = path.resolve process.cwd(), output || options.output || @output

    if fs.existsSync output
      @emit 'debug', "#{output} already exists!"
      if @force
        @emit 'log', 'Deleting existing build output directory'
        wrench.rmdirSyncRecursive output
      else
        throw new Error "#{output} already exists"

    @emit 'log', "Creating output directory #{dotPrefix output}"
    wrench.mkdirSyncRecursive output

    for source, destination of @mount
      source = path.resolve @root, source
      destination = path.resolve process.cwd(), output, "./#{destination}"
      @emit 'debug', "Will copy aliased source #{source} to #{destination}"
      continue unless fs.existsSync source

      @emit 'log', "Copying #{dotPrefix source} to #{dotPrefix destination}"
      wrench.copyDirSyncRecursive source, destination

    for generatedFile, sourceFile of @generate
      generatedFile = path.resolve process.cwd(), output, "./#{generatedFile}"
      sourceFile = path.resolve @root, sourceFile
      @emit 'debug', "Will generate #{generatedFile} from #{sourceFile}"
      continue unless fs.existsSync sourceFile

      @emit 'log', "Generating #{dotPrefix generatedFile} from #{dotPrefix sourceFile}"

    for pattern, optimizer of @optimize
      files = glob.sync path.resolve output, "./#{pattern}"
      @emit 'debug', "Will optimize globbed pattern \"#{pattern}\" (#{files.length} files)"

      for file in files
        @emit 'log', "Optimizing #{dotPrefix file}"

module.exports = Builder
