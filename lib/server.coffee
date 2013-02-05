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

    for entry, exit of @js then do (entry, exit) =>
      requestUrl = path.sep + path.relative '.', exit
      server.get requestUrl, (req, res, next) =>
        filename = path.resolve @root, entry
        js = resolveJs filename, {@compilers}
        res.contentType 'application/javascript'
        res.send js

    for entry, exit of @css then do (entry, exit) =>
      requestUrl = path.sep + path.relative '.', exit
      server.get requestUrl, (req, res, next) =>
        filename = path.resolve @root, entry
        css = renderStylus filename
        res.contentType 'text/css'
        res.send css

    for entry, exit of @static
      prefix = path.sep + path.relative '.', exit
      server.use prefix, express.static path.resolve @root, entry

    console.log "Server listening on port #{port}"
    server.listen port

    server

module.exports = Server
