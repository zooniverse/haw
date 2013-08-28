coffeeToJs = require './coffee-to-js'
stylToCss = require './styl-to-css'
fs = require 'fs'

defaultConfig =
  root: '.'

  port: 2217 # For the server

  output: 'build'
  force: false # Delete existing build directory

  quiet: false
  debug: false

  mount:
    # (Local directory): (Mount point)
    './public': '/'
    './test': '/test'

  generate:
    # (Generated file path): (Source file/function returning a string)
    '/application.js': './app/index.js'
    '/application.css': './css/index.css'

  compile:
    # E.g. requesting foo.js will fall through to compiling foo.coffee.
    '.coffee':
      '.js': coffeeToJs

    '.styl':
      '.css': stylToCss

  optimize:
    # Only after a build
    '/application.js': (file, options, callback) ->
      fs.readFileSync file # TODO

    '/application.css': (file, options, callback) ->
      fs.readFileSync file # TODO

    '{*,**/*}.jpg': (file, options, callback) ->
      fs.readFileSync file # TODO

    '{*,**/*}.png': (file, options, callback) ->
      fs.readFileSync file # TODO

module.exports = defaultConfig
