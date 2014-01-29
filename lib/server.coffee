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

  serve: (port = @port) ->
    @app = express()

    @app.all '*', (req, res, next) =>
      @emit 'info', "Got request for #{req.url}"
      next()

    for localGlob, mount of @mount
      localMatches = glob.sync path.resolve @root, localGlob
      for local in localMatches
        @emit 'info', "Mounting #{path.relative @root, local} at #{mount}"
        @app.use mount, express.static local

    for virtualFile, generator of @generate then do (virtualFile, generator) =>
      @emit 'info', "Will generate #{virtualFile} from #{generator}"
      @app.get virtualFile, (req, res, next) =>
        reqExt = path.extname(req.path).slice 1

        respond = (error, content) =>
          if error?
            @emit 'error', "Responding with an error #{error}"
            res.send 500, error
          else
            mimeType = mime.lookup req.path
            @emit 'log', "Content type of #{req.path} is #{mimeType}"
            res.contentType mimeType

            transformer = @compile[reqExt]?[reqExt]
            if transformer?
              @emit 'info', "Transforming final #{reqExt} response"
              transformer.call @, content, (error, content) =>
                if error?
                  @emit 'error', "Transformation error #{error}"
                  respond error
                else
                  @emit 'log', 'Transformation successful'
                  res.send content
            else
              res.send content

        glob path.resolve(@root, generator), (error, matches) =>
          if error?
            @emit 'error', "Glob error: #{generator}"
            respond error
          else if matches.length is 0
            @emit 'error', "Couldn't find a match for #{virtualFile} at #{generator}"
            next()
          else
            match = matches[0]
            if matches.length is 1
              @emit 'info', "Matched #{match}"
            else
              @emit 'warn', "Multiple matches found to generate #{generator}; using #{match}"

            fs.readFile match, (error, content) =>
              if error?
                @emit 'error', "Error reading #{match}"
              else
                srcExt = path.extname(match).slice 1
                unless srcExt is reqExt
                  compiler = @compile[srcExt]?[reqExt]

                if compiler?
                  @emit 'info', "Compiling #{srcExt}->#{reqExt}"
                  compiler.call @, content, (error, content) =>
                    if error?
                      @emit 'error', "Compile error: #{error}"
                      respond error
                    else
                      respond null, content
                else
                  respond null, content

    @app.listen port
    @emit 'info', "Server listening on port #{port}"
    @app

  close: ->
    @app.close()

module.exports = Server
