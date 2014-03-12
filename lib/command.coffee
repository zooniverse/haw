minimist = require 'minimist'
path = require 'path'

class Command
  configFiles: null
  usage: ''
  options: null
  mainTask: 'main'

  constructor: (settings = {}) ->
    @[key] = value for key, value of settings
    @configFiles ?= []
    @options ?= []

  run: (argv = []) ->
    minimistOptions = alias: {}
    for [long, short, description, defaultValue] in @options when short?
      minimistOptions.alias[long] = short

    options = minimist argv, minimistOptions
    options = @mergeConfigs @configFiles..., options

    @modifyOptions options

    args = options._

    task = if args[0] of this
      this[args.shift()]
    else if @mainTask of this
      @[@mainTask]
    else
      @showHelp

    task.call this, args..., options

  mergeConfigs: (configs...) ->
    output = {}

    for config in configs
      if typeof config is 'string'
        config = try require.resolve path.resolve config
        if config
          config = require config

      if config?
        if typeof config is 'function'
          config.call output, configs
        else
          output[key] = value for key, value of config

    for [long, short, description, defaultValue] in @options
      output[long] = defaultValue unless long of output

    output

  modifyOptions: (options) ->
    options._.unshift 'help' if options.help

  main: ->
    @help()

  help: ->
    console.log @usage if @usage
    for [long, short, description, defaultValue] in @options
      # TODO: Line up these columns.
      console.log "-#{short} --#{long} #{description}"

  'debug-options': ->
    console.log arguments...

module.exports = Command
