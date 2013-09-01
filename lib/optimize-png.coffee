# TODO

optimizePng = (file, options, callback) ->
  fs.readFile file, (error, contents) ->
    if error?
      callback error
    else
      fs.writeFile file, contents, callback

module.exports = optimizePng
