module.exports = ->

  @provider 'middleware', ->
    
    # app.defineMiddlewarePhases phases 
    # app.middlewareFromConfig config.fn, config 

    @$get = (config) ->
      config.one 'middleware'

  @run (middleware, events, loopback) ->

    for key, value of middleware
      #value.fn loopback, value.definition
      
      events.emit 'middleware:' + key, value 

