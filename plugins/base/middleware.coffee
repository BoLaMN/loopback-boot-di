module.exports = ->

  @provider 'middlewares', ->
    configs = {}
    
    # app.defineMiddlewarePhases phases 
    # app.middlewareFromConfig config.fn, config 

    @$get = (config) ->
      { definition } = config.one 'middleware'

      configs = definition
      configs

  @run (middlewares, events, loopback) ->
    phases = Object.keys middlewares 

    loopback.defineMiddlewarePhases phases 

    phases.forEach (key) ->
      middleware = middlewares[key]

      Object.keys(middleware).forEach (name) ->
        value = middleware[name]
        console.log name, value 

        loopback.middlewareFromConfig value.fn, value.config

        events.emit 'middlewares:' + name, value 

    return 

