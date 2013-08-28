Configurable = require './configurable'
express = require 'express'
require 'express-prettylogger'
dotPrefix = require './dot-prefix'
path = require 'path'
fs = require 'fs'
mime = require 'mime'

class Server extends Configurable
  serve: (port, options = {}) ->
    port ?= options.port || process.env.PORT || @port

    @emit 'log', "Haw starting a server on port #{port}."
    server = express()
    server.use express.logger 'pretty'

    for local, mount of @mount then do (mount, local) =>
      @emit 'log', "Will mount #{dotPrefix local} at \"#{mount}\" "

    for requested, provided of @generate then do (requested, provided) =>
      @emit 'log', "Will generate \"#{requested}\" from #{dotPrefix provided}"

    server.get '*', (req, res, next) =>
      @emit 'debug', "Request made for #{req.url}"
      localFile = null

      possibleLocalFiles = []
      if req.url of @generate
        possibleLocalFiles.push path.resolve @root, @generate[req.url]
      else
        possibleLocalFiles.push path.resolve @root, ".#{path.sep}#{req.url}"

        for local, mount of @mount
          continue unless req.url[...mount.length] is mount
          possibleLocalFiles.push path.resolve @root, local, ".#{path.sep}#{req.url}"

      @emit 'debug', "Possible local files: #{possibleLocalFiles}"
      for possibility in possibleLocalFiles # then do (possibility) =>
        continue if localFile?

        @emit 'debug', "Checking #{possibility}..."
        if fs.existsSync possibility
          @emit 'debug', "#{possibility} exists!"
          if (fs.statSync possibility).isDirectory()
            @emit 'debug', "#{possibility} is a directory."
            possibility = path.resolve possibility, 'index.html'

            if fs.existsSync possibility
              @emit 'debug', "#{possibility} exists!"
              localFile = possibility

              fs.readFile localFile, (error, content) =>
                if error?
                  res.send 500, error
                else
                  res.contentType mime.lookup localFile
                  res.send content

          else
            localFile = possibility

            fs.readFile localFile, (error, content) =>
              if error?
                res.send 500, error
              else
                res.contentType mime.lookup localFile
                res.send content

        else
          @emit 'debug', "#{possibility} doesn't exist."

          requestExt = path.extname req.url

          for srcExt of @compile when @compile[srcExt][requestExt]? then do (requestExt, srcExt) =>
            srcFile = possibility[...-requestExt.length] + srcExt
            @emit 'debug', "Checking for compilable (#{srcExt}->#{requestExt}) source: #{srcFile}"

            if fs.existsSync srcFile
              @emit 'debug', "#{srcFile} exists!"
              localFile = srcFile

              @compile[srcExt][requestExt] localFile, @, (error, content) ->
                if error?
                  res.send 500, error
                else
                  res.contentType mime.lookup req.url
                  res.send content

            else
              @emit 'debug', "#{srcFile} doesn't exist"

      if not localFile?
        @emit 'debug', "No suitable file found for #{req.url}"
        res.send 404

    server.listen port
    server

module.exports = Server
