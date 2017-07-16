module.exports = ->

  @provider 'mixins', ->
    configs = {} 

    @$get = (config) ->
      { definition } = config.one 'model-config'

      dirs = definition._meta.mixins 
      
      configs = config.from [ '**' ], dirs    
      configs

  @run (mixins, events, loopback) ->
    { modelBuilder } = loopback.registry 

    Object.keys(mixins).forEach (key) ->
      mixin = mixins[key]
      
      modelBuilder.mixins.define mixin.name, mixin.fn 

      events.emit 'mixins:' + key, mixin 

    return
