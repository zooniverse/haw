path = require 'path'
exec = require 'easy-exec'
fs = require 'fs'


optimizeJpg = (file, options, callback) ->
  tempFile = path.resolve ".TEMP.#{Math.random().toString().split('.')[1]}.jpg"

  exec "jpegtran -copy none -progressive -outfile #{tempFile} #{file}", (error) ->
    if error?
      callback error
    else
      fs.unlink file, (error) ->
          if error?
            callback error
          else
            fs.rename tempFile, file, (error) ->
              if error?
                callback error
              else
                  callback(null)

module.exports = optimizeJpg
