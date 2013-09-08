express = require 'express'
require 'express-prettylogger'
dotPrefix = require './dot-prefix'
path = require 'path'
fs = require 'fs'
glob = require 'glob'
mime = require 'mime'

serve = (port, options) ->
  port ?= process.env.PORT || options.port

  console.info "Haw starting a server on port #{port}." unless options.quiet
  server = express()
  server.use express.logger 'pretty' unless options.quiet

  for local, mount of options.mount
    console.info "Will mount #{dotPrefix local} at \"#{mount}\" " unless options.quiet

  for requested, provided of options.generate
    console.info "Will generate #{requested} from \"#{dotPrefix provided}\"" unless options.quiet

  server.get '*', (req, res, next) =>
    console.log "Request made for #{req.url}" if options.verbose

    if req.url of options.generate
      console.log "#{req.url} to be generated from \"#{options.generate[req.url]}\"" if options.verbose
      source = (glob.sync path.resolve options.root, options.generate[req.url])[0]
      if source
        localFile = path.resolve options.root, source
      else
        console.log "No matches for #{options.generate[req.url]}" if options.verbose

    unless localFile?
      for local, mount of options.mount when req.url[...mount.length] is mount
        possibleLocalFile = path.resolve options.root, local, ".#{path.sep}#{req.url}"
        if fs.existsSync possibleLocalFile
          console.log "Found #{possibleLocalFile}" if options.verbose
          localFile = possibleLocalFile

    if localFile?
      if fs.statSync(localFile).isDirectory()
        localFile = path.resolve localFile, 'index.html'
      else
        requestExt = path.extname req.url
        localExt = path.extname localFile

      unless requestExt is localExt
        compile = options.compile[localExt][requestExt]

      if compile?
        console.log "Compiling #{localFile} (#{localExt}->#{requestExt})}" if options.verbose

        compile localFile, options, (error, content) ->
          if error?
            res.send 500, error
          else
            res.contentType mime.lookup req.url
            res.send content

      else
        fs.readFile localFile, (error, content) =>
          if error?
            res.send 500, error
          else
            res.contentType mime.lookup localFile
            res.send content

    else
      console.log "No suitable file found for #{req.url}" if options.verbose
      res.send 404

  server.listen port
  server

module.exports = serve
