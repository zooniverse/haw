{EventEmitter} = require 'events'
defaultConfig = require './default-config'
async = require 'async'
wrench = require 'wrench'
glob = require 'glob'
path = require 'path'
fs = require 'fs'
ASYNC_IDENTITY = require './async-identity'

class Builder extends EventEmitter
  root: defaultConfig.root
  output: defaultConfig.output
  force: defaultConfig.force
  mount: defaultConfig.mount
  generate: defaultConfig.generate
  compile: defaultConfig.compile
  postProcess: defaultConfig.compile
  optimize: defaultConfig.optimize
  timestamp: defaultConfig.timestamp
  stampFilename: defaultConfig.stampFilename

  constructor: (config) ->
    super
    @[property] = value for property, value of config

  build: ->
    started = Date.now()
    if fs.existsSync @output
      @emit 'log', "Build directory #{@output} already exists"
      if @force
        if fs.statSync(@output).isDirectory()
          @removeOldBuildDirectory @output
        else
          @emit 'err', "Cannot remove #{@output}; not a directory"
      else
        @emit 'err', "Build directory #{@output} already exists; try --force"

    unless fs.existsSync @output
      @makeBuildDirectory()
      @copyMountedDirectories()
      @generateFiles =>
        @optimizeFiles =>
          @applyTimestamps()
          @emit 'info', "Build took #{(Date.now() - started) / 1000} seconds"

  removeOldBuildDirectory: ->
    @emit 'info', "Removing existing build directory #{@output}"
    wrench.rmdirSyncRecursive @output
    unless fs.existsSync @output
      @emit 'log', "Removed #{@output} successfully"

  makeBuildDirectory: ->
    @emit 'info', "Creating directory #{@output}"
    wrench.mkdirSyncRecursive @output
    if fs.existsSync @output
      @emit 'log', "Created of #{@output} successfully"

  copyMountedDirectories: ->
    for sourcesGlob, destination of @mount
      @emit 'log', "Will copy directories at #{sourcesGlob} to #{destination}"
      destination = path.resolve @output, ".#{path.sep}#{destination}"
      sources = glob.sync path.resolve @root, sourcesGlob
      for source in sources
        destrinationDir = path.dirname destination
        @emit 'log', "Creating directory #{destrinationDir}"
        wrench.mkdirSyncRecursive path.dirname destination
        @emit 'info', "Copying #{source} into #{destination}"
        wrench.copyDirSyncRecursive source, destination

  generateFiles: (callback) ->
    todo = 0
    for generatedFile, srcFilesGlob of @generate
      @emit 'log', "Generating #{generatedFile} from #{srcFilesGlob}"
      generatedFile = path.resolve @output, ".#{path.sep}#{generatedFile}"

      if fs.existsSync generatedFile
        @emit 'warn', "#{generatedFile} already exists; skipping"
      else
        srcFiles = glob.sync path.resolve @root, srcFilesGlob
        if srcFiles.length is 0
          @emit 'log', "No matches for #{srcFilesGlob}"
        else
          srcFile = srcFiles[0]
          if srcFiles.length is 1
            @emit 'log', "Matched source file #{srcFile}"
          else
            @emit 'warn', "Found multiple sources for #{generatedFile}; using #{srcFile}"

          todo += 1
          @generateFile srcFile, generatedFile, (error) =>
            todo -= 1
            if error?
              @emit 'err', 'File generation error:', error
              callback? error
            else
              @emit 'log', "Generated #{generatedFile} successfully"
              if todo is 0
                @emit 'log', 'Finished generating files'
                callback?()
              else
                @emit 'log', "Waiting for #{todo} files to generate"

  generateFile: (srcFile, generatedFile, callback) ->
    @emit 'info', "Will generate #{generatedFile} from #{srcFile}"

    srcFileExt = path.extname(srcFile).slice 1
    genFileExt = path.extname(generatedFile).slice 1

    compiler = @compile[srcFileExt]?[genFileExt]
    processor = @postProcess?[genFileExt]

    source = "#{fs.readFileSync srcFile}"

    if compiler?
      @emit 'info', "Will compile #{generatedFile} (#{srcFileExt}->#{genFileExt})"
    else
      @emit 'log', "No compiler found for #{generatedFile} (#{srcFileExt}->#{genFileExt})"
      compiler = ASYNC_IDENTITY

    process.nextTick =>
      compiler.call @, source, (error, compiled) =>
        if error?
          @emit 'err', "Error compiling #{srcFile}:", error
          callback?.call @, error
        else
          @emit 'log', "Compiled #{srcFile} successfully"

          if processor?
            @emit 'info', "Will post-process #{generatedFile} (#{genFileExt})"
          else
            @emit 'log', "No post-processor found for #{generatedFile} (#{genFileExt})"
            processor = ASYNC_IDENTITY

          processor.call @, compiled, (error, processed) =>
            if error?
              @emit 'err', "Error post-processing #{generatedFile}:", error
              callback?.call @, error
            else
              @emit 'log', "Post-processed #{generatedFile} successfully"

              fs.writeFileSync generatedFile, processed
              @emit 'log', "Wrote #{generatedFile} successfully"
              callback?.call @

  optimizeFiles: (callback) ->
    todo = 0
    for pattern, optimizer of @optimize
      @emit 'log', "Will optimize #{pattern}"
      matches = glob.sync path.resolve @output, ".#{path.sep}#{pattern}"
      for filename in matches
        todo += 1
        @emit 'info', "Optimizing #{filename}"
        optimizer.call @, filename, (error) =>
          todo -= 1
          if error?
            @emit 'err', "Error optimizing #{filename}:", error
            callback? error
          else
            @emit 'log', "Optimized #{filename} successfully"
            if todo is 0
              @emit 'log', 'Finished optimizing files'
              callback?()
            else
              @emit 'log', "Waiting for #{todo} files to optimize"

  applyTimestamps: ->
    for referencesGlob, referencersGlob of @timestamp
      @emit 'log', "Will rename #{referencesGlob} and update #{referencersGlob}"
      references = glob.sync path.resolve @output, ".#{path.sep}#{referencesGlob}"
      referencers = glob.sync path.resolve @output, ".#{path.sep}#{referencersGlob}"

      changes = {}

      for reference in references
        changes[reference] = @renameFile reference

      for referencer in referencers
        @fixReferences referencer, changes

  renameFile: (filename) ->
    stampedFilename = @stampFilename filename
    @emit 'info', "Renaming #{filename} to #{stampedFilename}"
    fs.renameSync filename, stampedFilename
    @emit 'log', "Renamed #{filename} to #{stampedFilename} successfully"
    stampedFilename

  fixReferences: (filename, changes) ->
    @emit 'info', "Updating references in #{filename}"
    dir = path.dirname filename
    content = fs.readFileSync filename
    for original, timestamped of changes
      relativeOriginal = path.relative dir, original
      relativeTimestamped = path.relative dir, timestamped
      @emit 'log', "Will replace #{relativeOriginal} with #{relativeTimestamped}"
      content = "#{content}".replace relativeOriginal, relativeTimestamped
    fs.writeFileSync filename, content
    @emit 'log', "Updated references in #{filename} successfully"

module.exports = Builder

# builder = new Builder
#   root: 'demo'
#   force: true

#   compile:
#     coffee:
#       js: (content, callback) ->
#         callback? null, "// COMPILED\n#{content}"

#   postProcess:
#     js: (content, callback) ->
#       callback? null, "// RESOLVED\n#{content}"

#   optimize:
#     '/main.js': (filename, callback) ->
#       # Optimize in place
#       callback()

#   timestamp:
#     '/main.{css,js}': '/index.html'

#   stampFilename: (filename, callback) ->
#     # TODO: Async
#     crypto = require 'crypto'
#     content = fs.readFileSync filename
#     hash = crypto.createHash('md5').update(content).digest 'hex'
#     [nameSegments..., ext] = filename.split '.'
#     "#{nameSegments.join '.'}.#{hash[...6]}.#{ext}"

# chalk = require 'chalk'
# builder.on 'info', console.log.bind console
# builder.on 'warn', console.log.bind console, chalk.red 'WARN'
# builder.on 'error', (messages...) -> console.log chalk.red "# #{messages.join ' '}"
# builder.on 'log', (messages...) -> console.log chalk.gray "# #{messages.join ' '}"

# builder.build()
