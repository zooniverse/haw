path = require 'path'
exec = require 'easy-exec'
fs = require 'fs'

TEMP_FILE = path.resolve 'TEMP.jpg'

optimizeJpg = (file, options, callback) ->
  exec "jpegtran -copy none -progressive -outfile #{TEMP_FILE} #{file}", (error) ->
    if error?
      callback error
    else
      fs.unlink file, (error) ->
          if error?
            callback error
          else
            fs.rename TEMP_FILE, file, (error) ->
              if error?
                callback error
              else
                  callback(null)

module.exports = optimizeJpg
