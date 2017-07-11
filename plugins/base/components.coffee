module.exports = ->

  @provider 'components', ->
    configs = {}

    # 

    @$get = (config) ->
      info = config.one 'component-config'
      
      dirs = Object.keys info 
      configs = config.from info, dirs

      configs

  @run (components, events, loopback) ->

    for key, value of components
      value.fn loopback, value.definition

      events.emit 'components:' + key, value 

    return

