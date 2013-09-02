defaultsInits =
  default:
    app:
      'index.coffee': ''

      models:
        '.gitkeep': ''

      views:
        '.gitkeep': ''

      controllers:
        '.gitkeep': ''

    css:
      'index.styl': '''
        body
          margin: 0
      '''

    public:
      'index.html': '''
        <!DOCTYPE html>

        <html>
          <head>
            <meta charset="utf-8" />
            <title>{{name}}</title>
            <link rel="stylesheet" href="./application.css" />
          </head>

          <body>
            <script src="./application.js"></script>
          </body>
        </html>
      '''

      images:
        '.gitkeep': ''

  controller:
    app:
      controllers:
        '{{dashed name}}.coffee': '''
          class {{classCase name}}
            className: '{{dashed name}}'

          module.exports = {{classCase name}}
        '''

    css:
      '{{dashed name}}.styl': '''
        .{{dashed name}}
          color: inherit
      '''

module.exports = defaultsInits
