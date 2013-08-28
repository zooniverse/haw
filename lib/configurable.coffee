{EventEmitter} = require 'events'
defaultConfig = require './default-config'
path = require 'path'

class Configurable extends EventEmitter
  constructor: (params = {}) ->
    super
    @[property] = value for property, value of defaultConfig
    @[property] = value for property, value of params

    unless @quiet
      @on 'log', -> console.log arguments...

      if @debug
        @on 'debug', -> console.log '> ', arguments...

    if @config
      try
        configPath = require.resolve path.resolve process.cwd(), @config
        configuration = require configPath

        @emit 'log', "Configuring with #{path.relative process.cwd(), configPath}"

        if typeof configuration is 'function'
          configuration.call @, @
        else
          @[property] = value for property, value of configuration

      catch e
        @emit 'log', "Couldn't find configuration \"#{@config}\""

module.exports = Configurable
