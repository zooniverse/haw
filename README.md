An alternative to `hem`

```
npm install haw
haw help
```

Configuration
=============

Haw will load configurations from `~/.config/haw.{json,js,coffee}`, `~/.haw.{json,js,coffee}`, `./slug.{json,js.coffee}` in that order. Don't put project-important stuff in your user config files, because then nobody else will get them.

If another configuration file is specified with `--config ./special-haw-config.json`, e.g., that will be loaded last. Might be useful to have a dev/production haw config; might not.

Configuration properties
------------------------

**root**: Default is the current working directory.

**port**: When serving, this is where the server will run. Default is `2217`.

**output**: This is where builds go. Default is "build" in the current working directory.

**force**: When building, overwrite any existing files at the build directory. Default is `false`.

**quiet**: Don't log anything. Default is `false`.

**verbose**: Log extra debugging info. Default is `false`.

**mount**: A map of globs matching source directories in the `root` to their destinations. When serving, the source directories are available at the destination path URL. When building, the source directories are copied to the destination path. By default, "public" and "static" are mounted at the root.

**generate**: A map of "virtual files" to globs matching the source files to generate them. When serving, these are recreated every time they're accessed. When building, they're created at the `output` directory. Default is:

```
{
  '/index.html': 'public/index.{html,eco}',
  '/main.js': 'app/main.{js,coffee}',
  '/main.css': 'css/main.{css,styl}'
}
```

**compile**: A map of source extensions to futher maps of destination extensions to async functions handling the conversion. Generated "virtual files" have their source files run through these. By default, the follow conversions are included: eco to html, js to js (with `require`s resolved with browserify), coffee to js, and styl to css.

It's worth noting that I'm not super happy with the `generate`/`compile` setup. It'll probably change in the future.

**optimize**: A map of file paths (rooted from the `output` directory) to optimization functions to run after a build. By default, the following will be optimized: `/main.js`, `/main.css`, `{*,**/*}.jpg`, and `{*,**/*}.png`.

**timestamp**: A map of static files to files referencing them. The static files will be renamed with the `timestampFilename` function and the files referencing them will be updated to point to the new files. By default files matching `/main.{css,js}` are renamed and the content of `index.html` is updated.

**stampFilename**: The function used to rename timestamped files. By default it appends a short hash.

**bundleOptions**: A map of options to pass to `browserify.bundle` the most common value will be {"debug": true} to generate source maps for your project. See the [browserify docs](https://github.com/substack/node-browserify#bbundleopts-cb) for more options. 

Commands
========

`haw serve` runs a development server.

`haw build` builds the site. Push the build directory to S3 or whatever and you've got yourself a web site.
