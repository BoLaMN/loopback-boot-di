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

  @run (boot, events, loopback) ->

    for value in boot
      value.fn loopback

      events.emit 'boot', value 

    return

