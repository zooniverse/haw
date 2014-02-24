optimist = require 'optimist'
defaultConfig = require './default-config'
path = require 'path'
showOutput = require './show-output'

optimist.usage '''
  Usage:
    haw init
    haw init controller SomeController
    haw serve --port 1234
    haw build --config ./package.json --output ./build
'''

options = optimist.options({
  c: alias: 'config', description: 'Configuration file'
  r: alias: 'root', description: 'Root from which to look for files'
  p: alias: 'port', description: 'Port on which to run the server'
  o: alias: 'output', description: 'Directory in which to build the site'
  f: alias: 'force', description: 'Overwrite any existing output directory'
  q: alias: 'quiet', description: 'Don\'t show any working info'
  v: alias: 'verbose', description: 'Show lots of working info'
  h: alias: 'help', description: 'Print some help'
  version: description: 'Print the version number'
}).argv

configuration = {}
configuration[property] = value for property, value of defaultConfig

require 'coffee-script/register'

configFile = options.config || configuration.config

configFile = try
  require.resolve configFile
catch e
  try
    require.resolve path.resolve configFile
  catch e
    null

if configFile?
  try
    config = require configFile
  catch e
    console.error e
    process.exit 1

  if typeof config is 'function'
    config.call configuration, configuration
  else
    configuration[property] = value for property, value of config

configuration[property] = value for property, value of options

[command, commandArgs...] = options._

command = 'help' if options.help
command = 'version' if options.version or (options.v and not command)

switch command
  when 's', 'serve', 'server'
    Server = require './server'
    exec = require 'easy-exec'
    port = commandArgs[0] ? configuration.port
    server = new Server configuration
    showOutput server

    console.log 'Hit "o" to open your browser.'
    process.stdin.setRawMode true
    process.stdin.resume()
    process.stdin.on 'data', (data) ->
      switch data.toString()
        when 'o'
          console.log 'Opening browser'
          exec "open http://localhost:#{configuration.port}"
        when 'q', '\u0003'
          console.log 'Goodbye'
          process.exit()

    server.serve port

  when 'i', 'init'
    init = require '../lib/init'
    type = commandArgs.shift()
    name = commandArgs.join ' '
    init type, name, configuration, (error, created) ->
      if error?
        console.log error
        process.exit 1

  when 'b', 'build', 'builder'
    Builder = require '../lib/builder'
    builder = new Builder configuration
    showOutput builder
    builder.build()

  when 'h', 'help'
    optimist.showHelp()

  when 'v', 'version'
    console.log (require path.join __dirname, '..', 'package').version

  else
    optimist.showHelp()
    process.exit 1
