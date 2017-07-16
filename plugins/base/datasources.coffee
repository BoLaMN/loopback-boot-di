module.exports = ->

  @provider 'datasources', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'datasources'

      configs = definition
      configs

  @run (events, datasources, loopback) ->

    Object.keys(datasources).forEach (key) ->
      datasource = datasources[key]

      events.get 'connectors', datasource.connector, (connector) ->
        console.log key, datasource.connector
        loopback.dataSource key, datasource  

        events.emit 'datasources:' + key, datasource 

    return
