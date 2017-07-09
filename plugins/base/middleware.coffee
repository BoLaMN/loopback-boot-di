module.exports = ->

  @provider 'middleware', ->
    
    # app.defineMiddlewarePhases phases 
    # app.middlewareFromConfig config.fn, config 

    @$get = (config) ->
      config.one 'middleware'
