module.exports = ->

  @provider 'mixins', ->
    configs = {}
    
    # modelBuilder.mixins.define mixin.name, mixin.fn 

    @$get = (config) ->

      info = config.one 'model-config'
      dirs = info._meta.mixins 

      configs = config.from info, dirs    
      configs
