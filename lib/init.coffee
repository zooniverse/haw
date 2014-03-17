fs = require 'fs'
{EventEmitter} = require 'events'
eco = require 'eco'
path = require 'path'

# TODO: Find out how to reference this without creating a new one.
BufferCtor = fs.readFileSync(module.filename).constructor

class Initializer extends EventEmitter
  constructor: (config) ->
    super
    @[property] = value for property, value of config

  split: (string) ->
    parts = string.split(/\W+|([A-Z][a-z]+)/).filter Boolean
    @emit 'log', "Spit #{JSON.stringify string} into #{JSON.stringify parts}"
    parts

  camelCase: (string) ->
    parts = @split string

    parts = for part, i in parts
      if i is 0
        part.toLowerCase()
      else
        part.charAt(0).toUpperCase() + part[1...].toLowerCase()

    newString = parts.join ''
    @emit 'log', "Camel-cased #{JSON.stringify string} into #{JSON.stringify newString}"
    newString

  classCase: (string) ->
    parts = @split string
    parts = for part, i in parts
      part.charAt(0).toUpperCase() + part[1...].toLowerCase()

    newString = parts.join ''
    @emit 'log', "Class-cased #{JSON.stringify string} into #{JSON.stringify newString}"
    newString

  dashed: (string) ->
    parts = @split string
    newString = parts.join('-').toLowerCase()
    @emit 'log', "Dashed #{JSON.stringify string} into #{JSON.stringify newString}"
    newString

  makeStructure: (structure, directories = []) ->
    for name, value of structure
      name = eco.render name, this
      currentPath = path.resolve directories..., name

      if typeof value is 'function'
        value = value.call this

      if typeof value is 'string'
        value = "#{eco.render value, this}\n"

      if typeof value is 'string' or value instanceof BufferCtor
        if fs.existsSync currentPath
          @emit 'info', "Skipping #{currentPath} (already exists)"
        else
          @emit 'info', "Writing #{currentPath}"
          fs.writeFileSync currentPath, value

      else
        directories.push name
        unless fs.existsSync currentPath
          @emit 'info', "Creating directory #{currentPath}"
          fs.mkdirSync currentPath
        @makeStructure value, directories
        directories.pop()

  initialize: (type = 'default') ->
    type ?= 'default'

    if type of @init
      fs.mkdirSync path.resolve @root unless fs.existsSync @root
      @makeStructure @init[type], [@root]

    else
      @emit 'error', "No initializer found for '#{type}'"

module.exports = Initializer
