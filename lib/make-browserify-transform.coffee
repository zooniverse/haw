path = require 'path'
through = require 'through'

module.exports = (extensions, transform) ->
  unless extensions instanceof Array
    extensions = [extensions]

  (file) ->
    if path.extname(file) in extensions
      content = ''

      write = (data) ->
        content += data

      end = ->
        transform file, content, (error, transformed) =>
          if error?
            @emit 'error', error
          else
            @queue transformed
          @queue null

      through write, end

    else
      through()
