{EventEmitter} = require 'events'
Server = require './server'
defaultConfig = require './default-config'
wrench = require 'wrench'
glob = require 'glob'
path = require 'path'
fs = require 'fs'
async = require 'async'

class Builder extends EventEmitter
  root: defaultConfig.root
  output: defaultConfig.output
  force: defaultConfig.force
  mount: defaultConfig.mount
  generate: defaultConfig.generate
  compile: defaultConfig.compile
  optimize: defaultConfig.optimize
  timestamp: defaultConfig.timestamp
  stampFilename: defaultConfig.stampFilename
  limit: defaultConfig.limit

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
          @emit 'error', "Cannot remove #{@output}; not a directory"
      else
        @emit 'error', "Build directory #{@output} already exists; try --force"

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
      destination = path.resolve @output, ".#{path.sep}#{destination}"
      sources = glob.sync path.resolve @root, sourcesGlob
      for source in sources
        @emit 'log', "Will copy #{source} into #{destination}"
        files = glob.sync path.resolve source, '{*,**/*}'
        for file in files
          continue if fs.statSync(file).isDirectory()
          newFile = path.resolve destination, path.relative source, file
          newFileDir = path.dirname newFile
          unless fs.existsSync newFileDir
            @emit 'log', "Creating directory #{newFileDir}"
            wrench.mkdirSyncRecursive newFileDir
          @emit 'info', "Copying #{file} into #{newFile}"
          fs.writeFileSync newFile, fs.readFileSync file

  generateFiles: (callback) ->
    todo = 0
    for generatedFile, srcFilesGlob of @generate then do (generatedFile) =>
      @emit 'log', "Generating #{generatedFile} from #{srcFilesGlob}"
      outputFile = path.resolve @output, ".#{path.sep}#{generatedFile}"

      if fs.existsSync outputFile
        @emit 'warn', "#{outputFile} already exists; skipping"
      else
        todo += 1
        process.nextTick =>
          @generateFile generatedFile, (error, content) =>
            if error?
              @emit 'error', 'File generation error:', error
              callback? error
            else
              fs.writeFile outputFile, content, (error) =>
                todo -= 1

                if error?
                  @emit 'error', "Error writing #{generatedFile}"
                else
                  @emit 'log', "Generated #{generatedFile} successfully"

                if todo is 0
                  @emit 'log', 'Finished generating files'
                  callback?()
                else
                  @emit 'log', "Waiting for #{todo} files to generate"

  generateFile: Server::generateFile

  optimizeFiles: (callback) ->
    if @optimize
      todo = 0
      for pattern, optimizer of @optimize
        todo += 1
        @emit 'log', "Will optimize #{pattern}"

        matches = glob.sync path.resolve @output, ".#{path.sep}#{pattern}"
        matchWithOptimizer = matches.map (match, i) ->
          { filename: match, optimizer }

        async.eachLimit matchWithOptimizer, @limit, @_optimizeFile, (error) =>
          unless error?
            todo -= 1
            if todo is 0
              callback?()
            else
              @emit 'log', "Finished optimizing all #{pattern}"
    else
      callback?()

  applyTimestamps: ->
    if @timestamp
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

  _optimizeFile: ({filename, optimizer}, callback) =>
    @emit 'info', "Optimizing #{filename}"
    optimizer.call @, filename, (error) =>
      if error?
        @emit 'error', "Error optimizing #{filename}:", error
        callback error, null
      else
        @emit 'log', "Optimized #{filename} successfully"
        callback null, true

module.exports = Builder
