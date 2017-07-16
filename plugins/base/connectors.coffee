module.exports = ->

  @provider 'connectors', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'connector-config'

      configs = config.from definition

      configs

  @run (connectors, events, loopback) ->

    Object.keys(connectors).forEah (key) ->
      config = connectors[key]

      if config.fn?.initialize
        connector = config.fn 
      else 
        connector = config.fn loopback

      loopback.connector key, connector

      events.emit 'connectors:' + key, config 

    return

