exec = require 'easy-exec'

optimizePng = (file, options, callback) ->
  exec "optipng -strip all -o7 -quiet #{file}", callback

module.exports = optimizePng
