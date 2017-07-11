module.exports = ->

  @provider 'mixins', ->
    configs = {} 

    @$get = (config) ->
      { definition } = config.one 'model-config'

      dirs = definition._meta.mixins 
      configs = config.from definition, dirs    
      
      configs

  @run (mixins, events, loopback) ->
    { modelBuilder } = loopback.registry 

    for key, value of mixins
      modelBuilder.mixins.define value.name, value.fn 
      
      events.emit 'mixins:' + key, value 

    return
