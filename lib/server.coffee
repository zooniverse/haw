{EventEmitter} = require 'events'
defaultConfig = require './default-config'
express = require 'express'
glob = require 'glob'
path = require 'path'
fs = require 'fs'
mime = require 'mime'

class Server extends EventEmitter
  port: defaultConfig.port
  root: defaultConfig.root
  generate: defaultConfig.generate
  mount: defaultConfig.mount
  compile: defaultConfig.compile

  constructor: (config) ->
    super
    @[property] = value for property, value of config

    @app = express()

    @app.all '*', (req, res, next) =>
      @emit 'info', "Got a request for #{req.url}"
      next()

    for localGlob, mount of @mount
      localMatches = glob.sync path.resolve @root, localGlob
      for local in localMatches
        @app.use mount, express.static local

    for generatedFile, generator of @generate
      @app.get generatedFile, @handleGeneratedFileRequest

  serve: (port = @port) ->
    @app.listen port

    @emit 'info', "Server listening on port #{port}"

    for localGlob, mount of @mount
      @emit 'info', "Mounting #{localGlob} at #{mount}"

    for generatedFile, generator of @generate
      @emit 'info', "Will generate #{generatedFile} from #{generator}"

    @app

  handleGeneratedFileRequest: (req, res, next) =>
    @generateFile req.path, (error, content) =>
      if error?
        @emit 'error', "Error generating #{req.path}", error
        res.send 500, error
      else if content?
        @emit 'info', "Generated #{req.path} successfully"
        mimeType = mime.lookup req.path
        res.contentType mimeType
        res.send content
      else
        @emit 'warn', "No content generated for #{req.path}"
        next()

  generateFile: (generatedFile, callback) ->
    generator = @generate[generatedFile]
    glob path.resolve(@root, generator), (error, matches) =>
      if error?
        @emit 'error', "Error with glob #{generator}", error
        callback? error

      else if matches.length is 0
        @emit 'error', "No match found for #{generator}"
        callback?()

      else
        if matches.length > 1
          @emit 'warn', "Found multiple matches for #{generator}"

        source = matches[0]
        @emit 'info', "Generating #{generatedFile} from #{source}"

        srcExt = path.extname(source).slice 1
        reqExt = path.extname(generatedFile).slice 1
        compiler = @compile[srcExt]?[reqExt]

        if compiler?
          @emit 'log', "Found compiler for #{generatedFile} (#{srcExt}->#{reqExt})"
        else
          @emit 'log', "No compiler found for #{generatedFile} (#{srcExt}->#{reqExt})"
          compiler ?= fs.readFile

        compiler.call @, source, (error, content) =>
          if error?
            @emit 'error', "Compile error in #{source}:", error
            callback error
          else
            @emit 'log', "Compiled #{source} successfully"
            callback null, content

  close: ->
    @app.close()

module.exports = Server
