module.exports = (app) ->

  @provider 'boot', ->
    configs = []

    @$get = (config, path) ->

      dirs = app.directories.map (directory) ->
        path.join directory, 'boot'

      config.get dirs, [ '**' ], (file, config) =>
        if typeof config is 'function'
          configs.push config

      configs
