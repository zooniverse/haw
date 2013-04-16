defaults = require './defaults'
clone = require 'clone'
deepExtend = require 'deep-extend'
express = require 'express'
require 'express-prettylogger'
path = require 'path'
resolveJs = require './resolve-js'
renderStylus = require './render-stylus'

class Server
  constructor: (params = {}) ->
    @[property] = value for property, value of clone defaults
    deepExtend @, params

  serve: (port, options = {}) ->
    port ?= options.port || process.env.PORT || @port

    server = express()
    server.use express.logger 'pretty'

    console.log "Haw starting a server on port #{port}."

    for entry, exit of @js then do (entry, exit) =>
      requestUrl = path.sep + path.relative '.', exit
      localFile = path.resolve @root, entry

      console.log "Will generate \"#{requestUrl}\" from #{localFile}"

      server.get requestUrl, (req, res) =>
        js = resolveJs localFile, {@libs, @compilers, debug: true}
        res.contentType 'application/javascript'
        res.send js

    for entry, exit of @css then do (entry, exit) =>
      requestUrl = path.sep + path.relative '.', exit
      localFile = path.resolve @root, entry

      console.log "Will generate \"#{requestUrl}\" from #{localFile}"

      server.get requestUrl, (req, res) =>
        css = renderStylus localFile, {@nib, @includeCss, compressCss: false}
        res.contentType 'text/css'
        res.send css

    for entry, exit of @static
      prefix = path.sep + path.relative '.', exit
      local = path.resolve @root, entry
      server.use prefix, express.static local
      console.log "Will serve static \"#{prefix}\" from #{local}"

    server.listen port

    server

module.exports = Server
