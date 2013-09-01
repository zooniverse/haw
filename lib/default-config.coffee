defaultConfig =
  config: 'slug'

  root: process.cwd()

  port: 2217

  output: 'build'
  force: false

  quiet: false
  verbose: false

  # (Local directory): (Mount point)
  mount:
    './public': '/'
    './test': '/test'
    './build': '/build'

  # (Generated file path): (Source file)
  generate:
    '/main.js': './app/index{.js,.coffee}'
    '/main.css': './css/index{.css,.styl}'

  # Compile based on extensions.
  compile:
    '.coffee': '.js': require './coffee-to-js'
    '.styl': '.css': require './styl-to-css'

  # Optimize files after a build
  # Paths are rooted at the build directory.
  optimize:
    '/main.js': require './optimize-js'
    '/main.css': require './optimize-css'
    '{*,**/*}.jpg': require './optimize-jpg'
    '{*,**/*}.png': require './optimize-png'

  # Modify file names, update references to them
  # (File with references): (Files to timestamp)
  # Paths are rooted at the build directory.
  timestamp:
    '/index.html': ['/main.js', '/main.css']

module.exports = defaultConfig
