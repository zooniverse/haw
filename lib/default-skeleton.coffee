module.exports =
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
      'index.style': '''
        body
          margin: 0
      '''

    public:
      'index.html': '''
        <!DOCTYPE html>

        <html>
          <head>
            <meta charset="utf-8" />
            <title>{{$_}}</title>
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
        '{{$0 | basename | dashed}}.coffee': '''
          class {{$0 | camelCased}}

          module.exports = {{$0 | camelCase}}
        '''
