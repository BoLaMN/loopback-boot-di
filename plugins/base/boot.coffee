module.exports = (app) ->

  @provider 'boots', ->
    configs = {}

    @$get = (config, path) ->
      dirs = app.directories.map (directory) ->
        path.join directory, 'boot'

      configs = config.from [ '**' ], dirs 
      configs

  @run (boots, events, loopback) ->

    Object.keys(boots).forEach (key) ->
      boot = boots[key]
      boot.fn loopback

      events.emit 'boots:' + key, boot 

    return

