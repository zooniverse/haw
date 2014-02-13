chalk = require 'chalk'

module.exports = (thing) ->
  unless thing.quiet
    thing.on 'info', console.log.bind console
    thing.on 'warn', console.log.bind console, chalk.red 'WARN'
    thing.on 'error', (messages...) -> console.log chalk.red "# #{messages.join ' '}"

  if thing.verbose
    thing.on 'log', (messages...) -> console.log chalk.gray "# #{messages.join ' '}"
