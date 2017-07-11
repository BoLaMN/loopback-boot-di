module.exports = ->

  @provider 'datasources', ->
    
    # app.dataSource key, obj  

    @$get = (config) ->
      info = config.one 'datasources'
      
      dirs = Object.keys info 
      configs = config.from info, dirs
      
      configs

  @run (events, datasources, loopback) ->

    for key, value of datasources
      loopback.dataSource key, value  
      
      events.emit 'datasources:' + key, value 

    return
